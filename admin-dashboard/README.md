# MIANE Admin Dashboard

Simple React admin dashboard for the MIANE system. No mock data.

- **Login** is real: the dashboard's Node server calls `Identity.API`'s actual `POST /auth/login`, checks the response includes the `Admin` role, and only then starts a session — non-admin accounts and wrong passwords are rejected by the real backend, not a frontend check. See `server/index.js`.
- **Session** is a server-side session keyed by an httpOnly cookie (`admin_session`) — the real JWT never reaches the browser. The dashboard's server holds it in memory (`Map`) and attaches it to every admin API call it makes on your behalf. Sessions expire when the underlying JWT does; logout clears both.
- **User management** (list / create / activate / deactivate) goes through real admin endpoints added to `Identity.API` (`/users`, `[Authorize(Roles = "Admin")]`) — the same validation, password hashing, and role checks the rest of the system uses. Creating a user can optionally grant it the `Admin` role too ("Grant Admin access" checkbox on the Users page) — so new admin accounts are created through the dashboard itself, not by hand in the DB. See `UsersController.cs`.
- **Trips/Expenses monitoring** (dashboard stats, recent activity) goes through matching admin "list all" endpoints added to `Trip.API` (`/trips/admin`) and `Expense.API` (`/expenses/admin`), also `[Authorize(Roles = "Admin")]`. Their regular endpoints stay self-scoped by design (X-User-Id header trust model); these are the one exception, gated behind the Admin role. `Notification.API` got the same JWT wiring and an `/notifications/admin` endpoint, though the dashboard doesn't call it yet.
- **Database/schema browser** still reads straight from Postgres (`information_schema`) — that's structural introspection, not a business action, so there's no admin API for it and direct read access is the simplest honest option.

## Pages

- **Login** - real Identity.API auth, Admin-role gated
- **Dashboard** - live stats (databases/users/trips/expenses) and recent activity
- **Users** - create users (optionally as Admin), edit, activate/deactivate — no hard delete, deactivation is the safe reversible option
- **Databases** - live schema browser: real tables, row counts, and columns for all 4 MIANE databases

## Run it

1. Start the backend stack (from the repo root):
   ```bash
   docker compose up -d postgres redis identity-api trip-api expense-api notification-api
   ```
2. Start the dashboard's API server:
   ```bash
   cd server
   npm install
   npm start   # http://localhost:4000
   ```
3. Start the frontend:
   ```bash
   npm install
   npm run dev   # http://localhost:5173
   ```
4. Log in with the seeded admin: `admin@Miane.local` / `Admin@123` (from `IdentitySeeder.cs`). Create more admins from the Users page afterward.

## Seeded accounts

From `IdentitySeeder.cs`, created on first Identity.API startup:

| Email | Password | Role | Dashboard access |
|---|---|---|---|
| `admin@Miane.local` | `Admin@123` | Admin | Yes |
| `staff@Miane.local` | `Staff@123` | Employee | No — not in the `Admin` role, login is rejected |

Change these passwords (or deactivate the accounts) before this ever runs anywhere but your own machine.

## Config (env vars, all optional)

- `IDENTITY_API_URL` / `TRIP_API_URL` / `EXPENSE_API_URL` (default `http://localhost:5127` / `5128` / `5129`) — where admin API calls go
- `FRONTEND_ORIGIN` (default `http://localhost:5173`) — allowed CORS origin for the session cookie
- `PGHOST` / `PGPORT` / `PGUSER` / `PGPASSWORD` (default `localhost` / `5432` / `Miane` / `Miane_password`) — direct Postgres access for the schema browser only

## Known limits

- No hard delete for users — only activate/deactivate, since related Trip/Expense data references user IDs without a cross-service cleanup story.
- Sessions live in an in-memory `Map` on the dashboard server — restarting the server logs everyone out. Fine for a local intern tool, not meant to run as a public multi-instance service.
- Adding the JWT bearer middleware to Trip/Expense/Notification only gates the new `admin/*` routes — every pre-existing endpoint on those services is untouched and still trusts the Gateway-forwarded `X-User-Id` header.

## Heads up: `docker compose down -v` deletes all data

The Postgres data lives in the named volume `miane_postgres_data`. Plain `docker compose down` (or `stop`) leaves it alone. Adding `-v` deletes it — every user/trip/expense in the local dev DB, back to just the two seeded accounts. There's no backup/dump in this repo, so treat `-v` as irreversible.
