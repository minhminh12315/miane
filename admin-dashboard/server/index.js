const express = require('express')
const cors = require('cors')
const cookieParser = require('cookie-parser')
const { randomUUID } = require('crypto')
const { Pool } = require('pg')

const PGHOST = process.env.PGHOST || 'localhost'
const PGPORT = process.env.PGPORT || 5432
const PGUSER = process.env.PGUSER
const PGPASSWORD = process.env.PGPASSWORD

if (!PGUSER || !PGPASSWORD) {
  console.error(
    'Fatal: PGUSER and PGPASSWORD environment variables are required. ' +
      'Do not rely on hardcoded database credentials.',
  )
  process.exit(1)
}

const FRONTEND_ORIGINS = (process.env.FRONTEND_ORIGIN || 'http://localhost:5173,http://127.0.0.1:5173')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean)

function clientError(res, status, message) {
  return res.status(status).json({ error: message })
}

function serverError(res, err, fallback = 'Internal server error') {
  console.error(err)
  return res.status(500).json({ error: fallback })
}

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
    if (!/^[a-zA-Z0-9_]+$/.test(table_name)) {
      continue
    }
    const { rows: cols } = await pool.query(`
      SELECT column_name FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = $1
      ORDER BY ordinal_position
    `, [table_name])
    const { rows: countRows } = await pool.query(
      `SELECT COUNT(*)::bigint AS count FROM ${quoteIdent(table_name)}`,
    )
    result.push({
      name: table_name,
      rows: Number(countRows[0].count),
      columns: cols.map((c) => c.column_name),
    })
  }
  return result
}

function quoteIdent(ident) {
  return `"${String(ident).replace(/"/g, '""')}"`
}

const app = express()
app.use(cors({
  origin(origin, callback) {
    if (!origin || FRONTEND_ORIGINS.includes(origin)) {
      callback(null, true)
      return
    }
    callback(new Error(`Origin ${origin} not allowed by CORS`))
  },
  credentials: true,
}))
app.use(express.json())
app.use(cookieParser())

// --- Auth: real login against Identity.API, admin-role gated, session cookie. ---

app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body
    if (!email || !password) return clientError(res, 400, 'Email and password are required')

    const loginRes = await fetch(`${IDENTITY_API_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })
    if (loginRes.status === 401) return clientError(res, 401, 'Email or password is incorrect')
    if (!loginRes.ok) return clientError(res, 502, 'Identity.API login failed')

    const data = await loginRes.json()
    if (!data.roles?.includes('Admin')) {
      return clientError(res, 403, 'This account does not have Admin access')
    }

    const expiresAt = new Date(data.expiresIn).getTime()
    if (!Number.isFinite(expiresAt) || expiresAt <= Date.now()) {
      return clientError(res, 502, 'Identity.API returned an invalid token expiry')
    }

    // Revoke any prior sessions for this admin on re-login.
    for (const [id, session] of sessions.entries()) {
      if (session.email === data.user.email || (data.user?.id && session.userId === data.user.id)) {
        sessions.delete(id)
      }
    }

    const sessionId = randomUUID()
    sessions.set(sessionId, {
      accessToken: data.accessToken,
      userId: data.user?.id,
      email: data.user.email,
      fullName: data.user.fullName,
      roles: data.roles,
      expiresAt,
    })

    res.cookie(SESSION_COOKIE, sessionId, {
      httpOnly: true,
      sameSite: 'lax',
      secure: process.env.NODE_ENV === 'production',
      maxAge: expiresAt - Date.now(),
    })
    res.json({ email: data.user.email, fullName: data.user.fullName, roles: data.roles })
  } catch (err) {
    serverError(res, err)
  }
})

app.post('/api/auth/logout', (req, res) => {
  const sessionId = req.cookies[SESSION_COOKIE]
  if (sessionId) sessions.delete(sessionId)
  res.clearCookie(SESSION_COOKIE, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
  })
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
    serverError(res, err)
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
      users: users.length,
      trips: trips.length,
      expenses: expenses.length,
    })
  } catch (err) {
    serverError(res, err, 'Failed to load stats')
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
      ...users.map((u) => ({ text: `New user registered: ${u.fullName || 'Unknown'}`, at: u.createAt })),
      ...trips.map((t) => ({ text: `Trip created: ${t.name || 'Untitled'}`, at: t.createdAt })),
      ...expenses.map((e) => ({ text: `Expense added: ${e.description || 'Untitled'}`, at: e.createdAt })),
    ]
    const combined = events
      .filter((r) => r.at && !Number.isNaN(new Date(r.at).getTime()))
      .sort((a, b) => new Date(b.at) - new Date(a.at))
      .map((r, i) => ({ id: i, text: r.text, time: r.at }))
    res.json(combined)
  } catch (err) {
    serverError(res, err, 'Failed to load activity')
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
    serverError(res, err, 'Failed to load users')
  }
})

app.post('/api/users', async (req, res) => {
  try {
    const { fullName, email, tier, active, isAdmin } = req.body
    if (!fullName || !email) return clientError(res, 400, 'fullName and email are required')

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
    clientError(res, 400, err.message || 'Failed to create user')
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
    clientError(res, 400, err.message || 'Failed to update user')
  }
})

app.put('/api/users/:id/status', async (req, res) => {
  try {
    const { active } = req.body
    if (typeof active !== 'boolean') {
      return clientError(res, 400, 'active must be a boolean')
    }
    if (
      active === false &&
      req.session.userId &&
      String(req.session.userId) === String(req.params.id)
    ) {
      return clientError(res, 400, 'You cannot deactivate your own account')
    }

    await adminFetch(IDENTITY_API_URL, `/users/${req.params.id}/status`, req.session.accessToken, {
      method: 'PUT',
      body: JSON.stringify({ isActive: active }),
    })
    res.json({ ok: true, active })
  } catch (err) {
    clientError(res, 400, err.message || 'Failed to update user status')
  }
})

const PORT = process.env.PORT || 4000
app.listen(PORT, () => {
  console.log(`Admin dashboard API listening on http://localhost:${PORT}`)
})
