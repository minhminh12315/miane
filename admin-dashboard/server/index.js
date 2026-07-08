const express = require('express')
const cors = require('cors')
const cookieParser = require('cookie-parser')
const { randomUUID } = require('crypto')
const { Pool } = require('pg')

const PGHOST = process.env.PGHOST || 'localhost'
const PGPORT = process.env.PGPORT || 5432
const PGUSER = process.env.PGUSER || 'Miane'
const PGPASSWORD = process.env.PGPASSWORD || 'Miane_password'

const FRONTEND_ORIGIN = process.env.FRONTEND_ORIGIN || 'http://localhost:5173'

// Business data (users, trips, expenses) goes through each service's real
// admin endpoints (all protected by the "Admin" role — see UsersController,
// AdminTripsController, AdminExpensesController) instead of touching their
// tables directly, so the same validation and role checks the rest of the
// system relies on still apply. The JWT used for these calls comes from the
// dashboard user's own login session (see the auth/session section below),
// not a hardcoded service account — one real admin JWT works against all of
// them since they share the same signing key/issuer/audience.
const IDENTITY_API_URL = process.env.IDENTITY_API_URL || 'http://localhost:5127'
const TRIP_API_URL = process.env.TRIP_API_URL || 'http://localhost:5128'
const EXPENSE_API_URL = process.env.EXPENSE_API_URL || 'http://localhost:5129'

async function adminFetch(baseUrl, path, token, options = {}) {
  const res = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}`, ...options.headers },
  })
  const body = await res.json().catch(() => ({}))
  if (!res.ok) throw new Error(body.message || `Admin API request failed: ${res.status}`)
  return body
}

// --- Session: cookie holds an opaque session id, the real JWT stays server-side. ---
const SESSION_COOKIE = 'admin_session'
const sessions = new Map() // sessionId -> { accessToken, email, fullName, roles, expiresAt }

function requireAuth(req, res, next) {
  const sessionId = req.cookies[SESSION_COOKIE]
  const session = sessionId && sessions.get(sessionId)
  if (!session || session.expiresAt < Date.now()) {
    if (session) sessions.delete(sessionId)
    return res.status(401).json({ error: 'Not authenticated' })
  }
  req.session = session
  next()
}

// One pool per real MIANE database (same Postgres server, 4 separate databases).
const databases = {
  Miane_identity: { pool: makePool('Miane_identity'), description: 'Users, roles, permissions' },
  Miane_trip: { pool: makePool('Miane_trip'), description: 'Trips and trip members' },
  Miane_expense: { pool: makePool('Miane_expense'), description: 'Expenses, splits, trip pools' },
  Miane_notification: { pool: makePool('Miane_notification'), description: 'Push / email notifications' },
}

function makePool(database) {
  return new Pool({ host: PGHOST, port: PGPORT, user: PGUSER, password: PGPASSWORD, database })
}

async function listTables(pool) {
  const { rows: tables } = await pool.query(`
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name != '__EFMigrationsHistory'
    ORDER BY table_name
  `)

  const result = []
  for (const { table_name } of tables) {
    const { rows: cols } = await pool.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = $1
      ORDER BY ordinal_position
    `, [table_name])
    const { rows: countRows } = await pool.query(`SELECT COUNT(*) FROM "${table_name}"`)
    result.push({
      name: table_name,
      rows: Number(countRows[0].count),
      columns: cols.map((c) => c.column_name),
    })
  }
  return result
}

const app = express()
app.use(cors({ origin: FRONTEND_ORIGIN, credentials: true }))
app.use(express.json())
app.use(cookieParser())

// --- Auth: real login against Identity.API, admin-role gated, session cookie. ---

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body
    if (!email || !password) return res.status(400).json({ error: 'Email and password are required' })

    const loginRes = await fetch(`${IDENTITY_API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })
    if (loginRes.status === 401) return res.status(401).json({ error: 'Email or password is incorrect' })
    if (!loginRes.ok) return res.status(502).json({ error: 'Identity.API login failed' })

    const data = await loginRes.json()
    if (!data.roles?.includes('Admin')) {
      return res.status(403).json({ error: 'This account does not have Admin access' })
    }

    const sessionId = randomUUID()
    const expiresAt = new Date(data.expiresIn).getTime()
    sessions.set(sessionId, {
      accessToken: data.accessToken,
      email: data.user.email,
      fullName: data.user.fullName,
      roles: data.roles,
      expiresAt,
    })

    res.cookie(SESSION_COOKIE, sessionId, {
      httpOnly: true,
      sameSite: 'lax',
      maxAge: expiresAt - Date.now(),
    })
    res.json({ email: data.user.email, fullName: data.user.fullName, roles: data.roles })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/auth/logout', (req, res) => {
  const sessionId = req.cookies[SESSION_COOKIE]
  if (sessionId) sessions.delete(sessionId)
  res.clearCookie(SESSION_COOKIE)
  res.json({ ok: true })
})

app.get('/api/auth/me', requireAuth, (req, res) => {
  res.json({ email: req.session.email, fullName: req.session.fullName, roles: req.session.roles })
})

// --- Everything below requires a logged-in Admin session. ---
app.use('/api', requireAuth)

app.get('/api/databases', async (req, res) => {
  try {
    const result = []
    for (const [name, { pool, description }] of Object.entries(databases)) {
      result.push({ name, description, tables: await listTables(pool) })
    }
    res.json(result)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/stats', async (req, res) => {
  try {
    const token = req.session.accessToken
    const [users, trips, expenses] = await Promise.all([
      adminFetch(IDENTITY_API_URL, '/users', token),
      adminFetch(TRIP_API_URL, '/trips/admin', token),
      adminFetch(EXPENSE_API_URL, '/expenses/admin', token),
    ])
    res.json({
      databases: Object.keys(databases).length,
      users: users.length,
      trips: trips.length,
      expenses: expenses.length,
    })
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/activity', async (req, res) => {
  try {
    const token = req.session.accessToken
    const [users, trips, expenses] = await Promise.all([
      adminFetch(IDENTITY_API_URL, '/users', token),
      adminFetch(TRIP_API_URL, '/trips/admin', token),
      adminFetch(EXPENSE_API_URL, '/expenses/admin', token),
    ])
    const events = [
      ...users.map((u) => ({ text: `New user registered: ${u.fullName}`, at: u.createAt })),
      ...trips.map((t) => ({ text: `Trip created: ${t.name}`, at: t.createdAt })),
      ...expenses.map((e) => ({ text: `Expense added: ${e.description}`, at: e.createdAt })),
    ]
    const combined = events
      .sort((a, b) => new Date(b.at) - new Date(a.at))
      .slice(0, 8)
      .map((r, i) => ({ id: i, text: r.text, time: r.at }))
    res.json(combined)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

function toDashboardUser(u) {
  return {
    id: u.id,
    fullName: u.fullName,
    email: u.email,
    tier: u.userTier === 1 ? 'Pro' : 'Basic',
    active: u.isActive,
    isAdmin: u.roles?.includes('Admin') ?? false,
  }
}

app.get('/api/users', async (req, res) => {
  try {
    const users = await adminFetch(IDENTITY_API_URL, '/users', req.session.accessToken)
    res.json(users.map(toDashboardUser))
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.post('/api/users', async (req, res) => {
  try {
    const { fullName, email, tier, active, isAdmin } = req.body
    if (!fullName || !email) return res.status(400).json({ error: 'fullName and email are required' })

    const created = await adminFetch(IDENTITY_API_URL, '/users', req.session.accessToken, {
      method: 'POST',
      body: JSON.stringify({
        fullName, email, userTier: tier === 'Pro' ? 1 : 0, isActive: active !== false, isAdmin: !!isAdmin,
      }),
    })
    res.status(201).json({
      id: created.id,
      fullName: created.fullName,
      email: created.email,
      tier: created.userTier === 1 ? 'Pro' : 'Basic',
      active: created.isActive,
      isAdmin: created.isAdmin,
      tempPassword: created.tempPassword,
    })
  } catch (err) {
    res.status(400).json({ error: err.message })
  }
})

app.put('/api/users/:id', async (req, res) => {
  try {
    const { fullName, tier } = req.body
    const updated = await adminFetch(IDENTITY_API_URL, `/users/${req.params.id}`, req.session.accessToken, {
      method: 'PUT',
      body: JSON.stringify({ fullName, userTier: tier === 'Pro' ? 1 : 0 }),
    })
    res.json(toDashboardUser(updated))
  } catch (err) {
    res.status(400).json({ error: err.message })
  }
})

app.put('/api/users/:id/status', async (req, res) => {
  try {
    const { active } = req.body
    await adminFetch(IDENTITY_API_URL, `/users/${req.params.id}/status`, req.session.accessToken, {
      method: 'PUT',
      body: JSON.stringify({ isActive: active }),
    })
    res.json({ ok: true, active })
  } catch (err) {
    res.status(400).json({ error: err.message })
  }
})

const PORT = process.env.PORT || 4000
app.listen(PORT, () => {
  console.log(`Admin dashboard API listening on http://localhost:${PORT}`)
})
