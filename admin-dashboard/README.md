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

## Luồng hoạt động & danh sách file (ghi chú để học)

### 1. Luồng đăng nhập (Login)

1. `src/pages/Login.jsx` — user nhập email/password, gọi `api.login()`.
2. `src/api.js` → `POST http://localhost:4000/api/auth/login` (server của dashboard, không phải Identity.API trực tiếp).
3. `server/index.js` (`POST /api/auth/login`) nhận request, gọi thật tới `Identity.API`: `POST http://localhost:5127/auth/login` — endpoint có sẵn từ trước (`AuthController.cs`), không phải mới viết.
4. Sai email/password → Identity.API trả 401 → dashboard server trả 401 → `Login.jsx` hiện lỗi.
5. Đúng password nhưng response không có role `"Admin"` → dashboard server tự chặn, trả 403 (dù login đúng vẫn không cho vào, vì không phải tài khoản admin).
6. Đúng và có role Admin → server tạo 1 session: lưu JWT thật vào biến `sessions` (một `Map` trong RAM), set cookie `admin_session` (httpOnly — JavaScript ở browser không đọc được cookie này), trả về `{email, fullName, roles}` cho frontend (không trả JWT thật về browser).
7. Frontend lưu vào `AuthContext` (`src/AuthContext.jsx`), điều hướng vào Dashboard.

### 2. Luồng gọi API sau khi đã đăng nhập (ví dụ trang Users)

1. `src/pages/Users.jsx` gọi `api.getUsers()` → `GET http://localhost:4000/api/users` (cookie `admin_session` tự động gửi kèm vì `fetch(..., { credentials: 'include' })`).
2. `server/index.js` có middleware `requireAuth` chặn trước mọi route `/api/*` (trừ 3 route auth) — đọc cookie, tìm session trong `Map`, lấy JWT thật ra; không có/hết hạn → trả 401.
3. Server dùng JWT đó gọi thật tới `Identity.API`: `GET http://localhost:5127/users` — route mới (`UsersController.cs`), có `[Authorize(Roles = "Admin")]` nên phải đúng JWT + đúng role mới gọi được.
4. Identity.API trả data thật từ Postgres → dashboard server đổi tên field cho gọn (`toDashboardUser`) → trả về frontend.

Trang Dashboard (stats/activity) làm y hệt bước 2–4 nhưng gọi thêm `Trip.API` (`GET /trips/admin`) và `Expense.API` (`GET /expenses/admin`).

### 3. Danh sách file đã tạo/sửa

**Backend .NET (ngoài thư mục `admin-dashboard/`):**

| File | Trạng thái | Việc nó làm |
|---|---|---|
| `src/Services/Identity/Identity.API/Controllers/UsersController.cs` | Mới | API quản lý user cho admin: list/create/update/deactivate, chỉ role Admin gọi được |
| `src/Services/Trip/Trip.API/Controllers/AdminTripsController.cs` | Mới | `GET /trips/admin` — xem tất cả trip, không chỉ trip của mình |
| `src/Services/Expense/Expense.API/Controllers/AdminExpensesController.cs` | Mới | `GET /expenses/admin` — xem tất cả expense |
| `src/Services/Notification/Notification.API/Controllers/AdminNotificationsController.cs` | Mới | `GET /notifications/admin` |
| `src/Services/Trip/Trip.API/Program.cs`, `appsettings.json` | Sửa | Thêm JWT bearer auth (trước đây Trip.API không kiểm tra token, chỉ tin header `X-User-Id`) |
| `src/Services/Expense/Expense.API/Program.cs`, `appsettings.json` | Sửa | Tương tự Trip.API |
| `src/Services/Notification/Notification.API/Program.cs`, `appsettings.json`, `.csproj` | Sửa | Tương tự Trip.API |
| `docker-compose.yml`, `docker-compose.dev.yml` | Sửa | Thêm biến `Jwt__Key`/`Jwt__Issuer`/`Jwt__Audience` cho 3 service trên (cùng key với Identity.API nên 1 JWT dùng chung được) |

**Frontend + server (trong `admin-dashboard/`):**

| File | Trạng thái | Việc nó làm |
|---|---|---|
| `src/pages/Login.jsx` | Mới | Form đăng nhập |
| `src/AuthContext.jsx` | Mới | Context lưu trạng thái đăng nhập (`user`, `login()`, `logout()`), tự kiểm tra session lúc mở web qua `api.me()` |
| `src/App.jsx` | Sửa | Chưa login → hiện `Login`; đã login → hiện `Sidebar` + `Routes` |
| `src/components/Sidebar.jsx` | Sửa | Thêm tên user đang đăng nhập + nút Logout |
| `src/pages/Dashboard.jsx`, `Users.jsx`, `Databases.jsx` | Sửa | Đổi từ mock data sang gọi API thật |
| `src/api.js` | Sửa | Thêm `login`/`logout`/`me`; mọi request thêm `credentials: 'include'` để cookie session được gửi đi |
| `server/index.js` | Sửa (nhiều nhất) | Thêm session (`Map` + cookie), middleware `requireAuth`, 3 route `/api/auth/*`, và các hàm gọi thật tới Identity/Trip/Expense API thay vì query thẳng Postgres cho phần user/stats/activity |
| `server/package.json` | Sửa | Thêm dependency `cookie-parser` |

## Known limits

- No hard delete for users — only activate/deactivate, since related Trip/Expense data references user IDs without a cross-service cleanup story.
- Sessions live in an in-memory `Map` on the dashboard server — restarting the server logs everyone out. Fine for a local intern tool, not meant to run as a public multi-instance service.
- Adding the JWT bearer middleware to Trip/Expense/Notification only gates the new `admin/*` routes — every pre-existing endpoint on those services is untouched and still trusts the Gateway-forwarded `X-User-Id` header.

## Heads up: `docker compose down -v` deletes all data

The Postgres data lives in the named volume `miane_postgres_data`. Plain `docker compose down` (or `stop`) leaves it alone. Adding `-v` deletes it — every user/trip/expense in the local dev DB, back to just the two seeded accounts. There's no backup/dump in this repo, so treat `-v` as irreversible.
