# Security & Bug Audit Fix Report

**Branch:** `main`  
**Date:** 2026-07-26  
**Scope:** Full-project audit — Critical / High / Medium fixes  
**Remote:** Confirmed `git pull --ff-only origin main` → Already up to date before commit

---

## Summary statistics

| Metric | Count |
|--------|------:|
| Files modified | ~75 |
| Files added (new) | 9 |
| Files deleted | 2 |
| Approx. lines changed | +1714 / −1118 (pre-report; +this file) |
| Severity tiers addressed | Critical, High, Medium |
| Services touched | Identity, Expense, Trip, Notification, Gateway, Admin, Mobile, AI-image |

---

## New files

| Path | Purpose |
|------|---------|
| `src/BuildingBlocks/EventBus/HttpNotificationEventBus.cs` | HTTP forward of integration events to Notification.API + `CompositeEventBus` |
| `src/BuildingBlocks/Middleware/TrustedUserHeadersMiddleware.cs` | Strip client `X-User-*`, re-derive from JWT only |
| `src/BuildingBlocks/Security/JwtSigningKeyGuard.cs` | Reject known Dev JWT signing key outside Development |
| `src/BuildingBlocks/Validation/ImageMagicBytes.cs` | Magic-byte validation for image uploads |
| `src/Clients/mobile/lib/core/network/token_store.dart` | Secure token storage via `flutter_secure_storage` |
| `src/Clients/mobile/lib/features/auth/presentation/controllers/registration_draft_provider.dart` | In-memory registration draft (password not in route args) |
| `src/Services/Expense/Expense.API/Services/TripMembershipClient.cs` | Expense → Trip membership check (IDOR defense) |
| `src/Services/Expense/Expense.API/Services/WalletAuthorizationService.cs` | Wallet custodian / fund authorization helpers |
| `src/Services/Identity/Identity.API/Models/Auth/UpgradeProRequest.cs` | Pro upgrade requires receipt body outside Dev |

## Deleted files

| Path | Reason |
|------|--------|
| `src/Clients/mobile/lib/features/analytics/presentation/screens/analytics_screen.dart` | Dead / hardcoded, unused |
| `src/Clients/mobile/lib/features/user_profile/presentation/screens/initial_setup_screen.dart` | Unreachable (`needsSetup` never assigned) |

---

## Critical fixes

| # | Area | Change |
|---|------|--------|
| C1 | Identity headers | Gateway + services strip client `X-User-*`; `TrustedUserHeadersMiddleware` re-derives from JWT |
| C2 | JWT signing key | `JwtSigningKeyGuard` blocks known Dev key outside Development |
| C3 | Admin bootstrap | Hardcoded admin only in Dev; prod requires `ADMIN_BOOTSTRAP_PASSWORD` |
| C4 | Google mock auth | Dev-only; removed loose `"mock"` substring match |
| C5 | Direct register | `/auth/register` disabled outside Dev (410) |
| C6 | Pro upgrade | Non-Dev requires receipt body; mobile sends receipt; `completePurchase` only after backend OK |
| C7 | Mobile session | Refresh failure → `markSessionExpired()` |
| C8 | Admin Postgres | Fail startup if `PGUSER` / `PGPASSWORD` missing |

---

## High fixes

| # | Area | Change |
|---|------|--------|
| H1 | Trip membership IDOR | `GET /trips/{id}/membership`; Expense uses `TripMembershipClient` on expense/wallet/pool/debts |
| H2 | Custodian / fund | Only current custodian; confirm-once; JSON metadata (no string injection) |
| H3 | Account lockout | Login uses Identity `IsLockedOut` / `AccessFailed` / `ResetAccessFailedCount` |
| H4 | OTP | Constant-time compare, attempt limit; Redis stores hash not plaintext password |
| H5 | Splits + wallet TX | Shared split calculation; expense + wallet in one DB transaction |
| H6 | Gateway | Rate limit on public auth routes; separate `notifications-events` route |
| H7 | Notification events | Internal webhook requires `X-Internal-Api-Key` |
| H8 | Admin dashboard | Secure cookie, AuthError→logout, self-deactivate block, Databases route, Vite `/api` proxy |
| H9 | Mobile tokens | `flutter_secure_storage` (`TokenStore`); reject empty tokens; 401 refresh+retry |
| H10 | AI-image | `AI_IMAGE_API_KEY` / `X-Api-Key`; restricted CORS |
| H11 | Event bus wiring | Expense/Trip → `POST /notifications/events` with internal API key (`HttpNotificationEventBus`) |
| H12 | Dual debt ledger | Balances prefer Debts V2 when present; settle supports legacy + V2 |
| H13 | Creditor-only settle | Only `ToUserId` can finalize; debtor “Đã chuyển” does not settle |
| H14 | Manual expense | Mobile “Nhập tay” → `ScanResultReviewScreen` empty draft (Android-friendly) |
| H15 | E-wallets hidden | Payment destinations bank-only until wallet payout API exists |

---

## Medium fixes

| # | Area | Change |
|---|------|--------|
| M1 | Wallet concurrency | `TripWallet.Version` concurrency token + retry |
| M2 | Debt V1 voided | Filter `ExpenseStatus.Voided` in debt simplification |
| M3 | Payment methods | Masked account numbers in list responses |
| M4 | Protector | Unprotect throws (no silent empty string) |
| M5 | Join race | Unique violation → `ConflictException` |
| M6 | Logout | `[Authorize]` on logout |
| M7 | Refresh tokens | Optional `UserId`; `refresh_{token}` → userId index |
| M8 | Uploads | Magic-byte image validation |
| M9 | FX rates | Fail-closed outside Dev unless `ExchangeRates:AllowStatic=true` |
| M10 | Admin polish | expiresAt validation, session revoke on re-login, SQL allowlist, multi CORS, generic 500s, stale fetch guards |
| M11 | Mobile polish | Dispose join controllers, invite regex, no password trim, scan race guard, safer JSON casts |
| M12 | OTP route args | Password held in Riverpod draft, not navigation args |
| M13 | Password policy | Min 8 chars + upper/lower/digit (Identity + mobile register/reset) |
| M14 | Dead auth path | Removed `needsSetup` / InitialSetup / unused analytics screen |

---

## Changes by area

### BuildingBlocks
- Event bus: in-process + optional HTTP notification forward
- Trusted user headers middleware
- JWT signing key guard
- Image magic-bytes helper

### Identity.API
- Stronger password policy (length 8, complexity)
- Lockout-aware login, safer OTP, refresh token indexing
- Dev-gated register / Google mock / admin seed
- Pro upgrade receipt gate
- Secure logout authorization

### Expense.API
- Trip membership checks on sensitive controllers
- Wallet authorization + concurrency version
- Dual-read balances (V2 preferred) + creditor-only settle
- Split calculation + transactional wallet ledger
- Payment account masking / protector fail-loud
- FX fail-closed; Notification event forwarding config

### Trip.API
- Membership endpoint for Expense
- Join race handling
- Cover upload magic-byte check
- Notification event forwarding config

### Notification.API
- Internal API key on `/notifications/events`
- Config for `Internal:ApiKey`

### Web.Gateway
- Always strip then inject `X-User-*` when authenticated
- Rate limits on public auth
- Isolated notifications-events route

### Admin dashboard
- Secure cookie / auth error handling
- Self-deactivate block
- Databases route + Vite proxy
- PG credential hard-fail

### Mobile
- Secure token store, session expiry on refresh fail
- Pro upgrade receipt flow
- Creditor confirm settle UX; manual expense entry
- Bank-only payment destinations
- Registration draft provider; stronger password UX
- Removed dead InitialSetup / analytics screens

### AI-image
- API key auth + restricted CORS

### Docker Compose (`docker-compose.yml`, `docker-compose.dev.yml`)
- `Services__Notification__*` + `INTERNAL_API_KEY` wiring for Trip/Expense
- `Services__Trip__BaseUrl` for Expense (dev)
- `ExchangeRates__AllowStatic=true` for container Dev
- Notification `Internal__ApiKey` in dev compose

---

## Explicitly deferred (not in this commit)

| Item | Notes |
|------|-------|
| Full App Store / Play receipt verification | Only receipt presence gate |
| Live FX HTTP provider | Static allowed via flag outside Dev |
| Full settlement state machine (SDS) | Creditor confirm path only |
| Android ML Kit OCR | Manual entry path provided |
| Permanent DebtRecords → Debts V2 migration | Dual-read bridge instead |
| Full notification outbox saga | Best-effort HTTP forward |

---

## Config / env keys to be aware of

| Key | Used by |
|-----|---------|
| `JWT_SIGNING_KEY` | All JWT services (must not be Dev default in prod) |
| `ADMIN_BOOTSTRAP_PASSWORD` | Identity admin seed (prod) |
| `INTERNAL_API_KEY` | Notification events + Expense/Trip forwarders |
| `Services:Notification:BaseUrl` / `ApiKey` | Event forwarding |
| `Services:Trip:BaseUrl` | Expense membership client |
| `ExchangeRates:AllowStatic` | Expense FX outside Development |
| `AI_IMAGE_API_KEY` | ai-image service |
| `PGUSER` / `PGPASSWORD` | Admin dashboard Postgres |

---

## Verification notes

- `git pull --ff-only origin main` → **Already up to date**
- .NET build succeeded for BuildingBlocks, Expense.API, Trip.API, Identity.API (OpenApi/MailKit advisory warnings only)
- Mobile analyze: pre-existing missing package resolution for some optional deps in local analyze env; auth/OTP/register changes compile-clean relative to those packages

---

## Commit intent

Harden identity trust boundaries, close IDOR/auth gaps, align debt settle/balances with wallet V2, wire cross-service notifications, and clean medium-severity reliability/security debt across backend, gateway, admin, mobile, and AI-image.
