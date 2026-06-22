<div align="center">

# ✈️ MIANE

**Smart Travel Itinerary Planner & Group Expense Splitter**

*Plan together. Spend smarter. Travel further.*

[![.NET](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Flutter](https://img.shields.io/badge/Flutter-SDK%203.5%2B-02569B?logo=flutter)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?logo=redis)](https://redis.io/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>

---

## 📖 Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture & Tech Stack](#2-architecture--tech-stack)
3. [Prerequisites](#3-prerequisites)
4. [Environment Variables & Secrets](#4-environment-variables--secrets)
5. [Getting Started](#5-getting-started)
   - [Option A — Docker Compose (Recommended)](#option-a--docker-compose-recommended)
   - [Option B — Local Development (Run Services Individually)](#option-b--local-development-run-services-individually)
6. [Project Structure](#6-project-structure)
7. [API Gateway & Service Endpoints](#7-api-gateway--service-endpoints)
8. [Database Schema Overview](#8-database-schema-overview)
9. [Running Tests](#9-running-tests)
10. [Contribution Guidelines](#10-contribution-guidelines)

---

## 1. Project Overview

**MIANE** is a premium mobile-first application for groups of travelers to:

- 🗺️ **Plan trips collaboratively** — create shared itineraries, invite members via a unique 8-character code, and manage trip lifecycle from planning to completion.
- 💸 **Split expenses fairly** — log group expenses with equal or custom splits, handle multi-currency payments with automatic conversion, and track who owes whom.
- 🏦 **Manage a shared Trip Pool** — contribute to a group fund and pay shared expenses directly from it.
- 📊 **Simplify debts** — a debt simplification algorithm minimizes the number of transactions needed to settle all balances within a trip.
- 🤖 **AI-assisted features** — AI-powered trip planning suggestions and OCR-based receipt scanning to auto-fill expense details.
- 🔔 **Real-time push notifications** — Firebase Cloud Messaging (FCM) delivers instant updates for expense creation, debt settlements, and member changes.

The system follows a **microservices architecture**, with a Flutter mobile client (targeting iOS and Android) communicating with four independent backend services through a centralized YARP API Gateway.

---

## 2. Architecture & Tech Stack

### System Architecture Diagram

```
┌───────────────────────────────────────────────────────────┐
│                   Flutter Mobile Client                    │
│       (Riverpod · http · JWT · Google Fonts)              │
└───────────────────────┬───────────────────────────────────┘
                        │ HTTP (port 5000)
                        ▼
┌───────────────────────────────────────────────────────────┐
│               Web.Gateway (YARP Reverse Proxy)            │
│   JWT Validation · Rate Limiting · Header Propagation     │
│                 ASP.NET Core / .NET 10                    │
└────┬──────────────┬────────────────┬───────────────┬──────┘
     │ :5127        │ :5128          │ :5129         │ :5130
     ▼              ▼                ▼               ▼
┌─────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────┐
│Identity │  │  Trip    │  │   Expense   │  │Notification  │
│  .API   │  │  .API    │  │    .API     │  │    .API      │
│ASP.NET  │  │ASP.NET   │  │  ASP.NET   │  │  ASP.NET     │
│.NET 10  │  │.NET 10   │  │  .NET 10   │  │  .NET 10     │
└────┬────┘  └────┬─────┘  └──────┬──────┘  └──────┬───────┘
     │            │               │                 │
     ▼            ▼               ▼                 ▼
┌─────────────────────────────────────────────────────────┐
│           PostgreSQL 16   (4 separate databases)        │
│   Miane_identity · Miane_trip · Miane_expense           │
│   Miane_notification                                    │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│       Redis 7   (Caching · OTP · Token Blacklist)       │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│   Firebase (FCM Push · Auth Google OAuth)               │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│   External AI Service  (Trip Planner · OCR Receipt)     │
│   HTTP client in BuildingBlocks.AI → configurable URL   │
└─────────────────────────────────────────────────────────┘
```

### Tech Stack Table

| Layer | Technology | Version |
|-------|-----------|---------|
| **Mobile Client** | Flutter + Dart | SDK `^3.5.0` |
| **State Management** | Riverpod (`flutter_riverpod` + `riverpod_generator`) | `^2.5.1` / `^2.4.0` |
| **Backend Framework** | ASP.NET Core | .NET 10 |
| **API Gateway** | YARP Reverse Proxy | `2.3.0` |
| **ORM** | Entity Framework Core + Npgsql | `10.0.8` / `10.0.1` |
| **Database** | PostgreSQL | `16-alpine` |
| **Cache / Session** | Redis (StackExchange.Redis) | `7-alpine` |
| **Auth** | ASP.NET Core Identity + JWT Bearer | .NET 10 |
| **Email (OTP)** | MailKit | `4.12.1` |
| **CQRS / Messaging** | MediatR | `12.4.1` |
| **Validation** | FluentValidation | `11.11.0` |
| **Async Reliability** | Transactional Outbox Pattern (EF Core) | Custom (`BuildingBlocks`) |
| **Push Notifications** | Firebase Admin SDK | `3.2.0` |
| **HTTP Client (Fonts)** | `google_fonts` Flutter package | `^8.1.0` |
| **Containerisation** | Docker + Docker Compose | Latest |

---

## 3. Prerequisites

Install the following tools before cloning the repository:

| Tool | Required Version | Download |
|------|-----------------|---------|
| **Docker Desktop** | Latest stable | [docker.com](https://www.docker.com/products/docker-desktop/) |
| **.NET SDK** | **10.0** | [dotnet.microsoft.com](https://dotnet.microsoft.com/download) |
| **Flutter SDK** | **3.5.0 or later** (Dart SDK `^3.5.0`) | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Git** | Any modern version | [git-scm.com](https://git-scm.com/) |
| **PowerShell** | 7+ (for integration tests) | [learn.microsoft.com](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell) |

**Verify your environment:**

```bash
dotnet --version       # Must be 10.x
flutter --version      # Must be 3.5+
docker --version
docker compose version
```

> **Firebase** (optional for local dev): You need a Firebase project only if you want to test push notifications. See [Section 4](#4-environment-variables--secrets) for details.

---

## 4. Environment Variables & Secrets

### 4.1 Create a `.env` file in the project root

When running with Docker Compose, the `docker-compose.yml` reads from a `.env` file (or from shell environment variables). Create `.env` in the project root:

```dotenv
# ─── JWT ────────────────────────────────────────────────────────────────────
# CHANGE THIS in production! Must be at least 32 characters.
JWT_SIGNING_KEY=Miane_Development_Jwt_Signing_Key_Change_In_Production_2026!@#

# ─── Database Connection Strings (defaults match docker-compose postgres) ───
# Leave blank to use the built-in defaults. Override only for remote databases.
IDENTITY_DB_CONNECTION_STRING=
TRIP_DB_CONNECTION_STRING=
EXPENSE_DB_CONNECTION_STRING=
NOTIFICATION_DB_CONNECTION_STRING=

# ─── Firebase (Push Notifications) ──────────────────────────────────────────
# Path to your Firebase service account JSON file, mounted into the container.
# Leave blank to skip push notification functionality.
FIREBASE_SERVICE_ACCOUNT_PATH=
FIREBASE_PROJECT_ID=

# ─── SMTP Email (OTP Registration) ───────────────────────────────────────────
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_FROM_NAME=MIANE

# ─── External AI Service ─────────────────────────────────────────────────────
# URL of the AI service (trip planner + OCR). Leave blank if not running.
AI_SERVICE_URL=http://localhost:8000
AI_SERVICE_API_KEY=
```

### 4.2 Local Development — `appsettings.Development.json`

When running services individually with `dotnet run`, each service reads its own `appsettings.Development.json`. The defaults connect to `localhost` PostgreSQL and Redis. The files already exist in each service directory with safe development defaults.

| Service | Config File Path |
|---------|-----------------|
| Identity | `src/Services/Identity/Identity.API/appsettings.Development.json` |
| Trip | `src/Services/Trip/Trip.API/appsettings.Development.json` |
| Expense | `src/Services/Expense/Expense.API/appsettings.Development.json` |
| Notification | `src/Services/Notification/Notification.API/appsettings.Development.json` |
| Web.Gateway | `src/ApiGateways/Web.Gateway/appsettings.Development.json` |

**Keys you MUST configure for full functionality:**

| Key | Service | Description |
|-----|---------|-------------|
| `Jwt:Key` | Identity, Gateway | JWT signing secret (min 32 chars) |
| `Firebase:ServiceAccountPath` | Identity, Notification | Path to Firebase service account JSON |
| `Firebase:ProjectId` | Identity, Notification | Firebase project ID |
| `Smtp:Username` / `Smtp:Password` | Identity | Gmail credentials (or SMTP relay) for OTP emails |
| `AiServices:BaseUrl` | Expense | URL to the Python AI service |
| `AiServices:ApiKey` | Expense | API key for the AI service |

---

## 5. Getting Started

### Option A — Docker Compose (Recommended)

This is the fastest way to spin up the entire stack with a single command.

**Step 1 — Clone the repository**

```bash
git clone https://github.com/minhminh12315/miane.git
cd miane
```

**Step 2 — Create the `.env` file**

Copy the template from [Section 4.1](#41-create-a-env-file-in-the-project-root) and fill in your values. At minimum, SMTP credentials are needed for registration OTPs to work.

**Step 3 — Start all services**

```bash
docker compose up --build
```

This command will:
- Pull and start **PostgreSQL 16** and **Redis 7** containers.
- Run the `docker/postgres-init.sql` init script to create the four service databases (`Miane_trip`, `Miane_expense`, `Miane_notification`) alongside the default `Miane_identity`.
- Build and start the four microservice APIs.
- Build and start the **Web.Gateway** (YARP).
- Build and start the **Flutter mobile client** (served via Nginx on port `3000`).

Each ASP.NET Core service **automatically runs EF Core migrations on startup** — no manual migration step is required.

**Step 4 — Verify the stack is healthy**

```
Service           Port     URL
─────────────────────────────────────────────
Web Gateway       5000     http://localhost:5000
Identity API      5127     http://localhost:5127
Trip API          5128     http://localhost:5128
Expense API       5129     http://localhost:5129
Notification API  5130     http://localhost:5130
Mobile Client     3000     http://localhost:3000
PostgreSQL        5432     localhost:5432
Redis             6370     localhost:6370
```

Hit the gateway health endpoint:
```bash
curl http://localhost:5000/
# Expected: "Miane Web Gateway"
```

**Step 5 — Tear down**

```bash
docker compose down            # Stop containers (keeps volumes)
docker compose down -v         # Stop and delete all data volumes
```

---

### Option B — Local Development (Run Services Individually)

Use this approach when you want hot-reload and IDE debugging for a specific service.

#### Step 1 — Start infrastructure

```bash
docker compose up postgres redis -d
```

This starts only the PostgreSQL and Redis containers, leaving the application services for you to run locally.

#### Step 2 — Run database migrations

Each service manages its own database. The services auto-migrate on startup in `Development` mode, so simply running the service is sufficient. If you want to run migrations manually:

```bash
# Identity
cd src/Services/Identity/Identity.API
dotnet ef database update

# Trip
cd src/Services/Trip/Trip.API
dotnet ef database update

# Expense
cd src/Services/Expense/Expense.API
dotnet ef database update

# Notification
cd src/Services/Notification/Notification.API
dotnet ef database update
```

#### Step 3 — Run the backend services

Open four separate terminals:

```bash
# Terminal 1 — Identity API (port 5127)
cd src/Services/Identity/Identity.API
dotnet run

# Terminal 2 — Trip API (port 5128)
cd src/Services/Trip/Trip.API
dotnet run

# Terminal 3 — Expense API (port 5129)
cd src/Services/Expense/Expense.API
dotnet run

# Terminal 4 — Notification API (port 5130)
cd src/Services/Notification/Notification.API
dotnet run
```

#### Step 4 — Run the API Gateway

```bash
# Terminal 5 — Web Gateway (port 8080 → mapped to 5000 externally in Docker, or 8080 locally)
cd src/ApiGateways/Web.Gateway
dotnet run
```

> **Note:** When running locally, the gateway connects to services by internal hostname. You may need to update `appsettings.Development.json` in `Web.Gateway` to use `http://localhost` cluster addresses instead of Docker service names.

#### Step 5 — Run the Flutter mobile app

```bash
cd src/Clients/mobile

# Install dependencies
flutter pub get

# Generate Riverpod code (required after any @riverpod changes)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on a connected device or emulator
flutter run
```

> The app connects to the API Gateway. Update the base URL in `src/Clients/mobile/lib/core/network/` to point to your local gateway address if needed.

---

## 6. Project Structure

```
miane/
│
├── docker-compose.yml              # Full-stack orchestration (all 6 containers)
├── docker/
│   └── postgres-init.sql           # Creates Miane_trip, Miane_expense, Miane_notification DBs
│
├── Miane.sln                       # Visual Studio solution file
│
├── src/
│   │
│   ├── BuildingBlocks/             # Shared class library (referenced by all services)
│   │   ├── AI/                     # HTTP clients for AI Trip Planner & OCR service
│   │   ├── Behaviors/              # MediatR pipeline behaviors (validation, logging)
│   │   ├── Caching/                # ICacheService + RedisCacheService abstraction
│   │   ├── CQRS/                   # ICommand, IQuery, ICommandHandler, IQueryHandler interfaces
│   │   ├── Data/                   # BaseDbContext with Outbox table + OutboxProcessor background service
│   │   ├── Domain/                 # Base domain entity types
│   │   ├── EventBus/               # In-process event bus (IEventBus, IIntegrationEvent)
│   │   ├── Exceptions/             # Domain exception types
│   │   ├── Extensions/             # AddBuildingBlocks() & AddOutboxProcessor() DI extensions
│   │   ├── Middleware/             # ExceptionHandlingMiddleware (global error handler)
│   │   ├── Notifications/          # Firebase Admin SDK integration (AddFirebaseNotifications())
│   │   └── BuildingBlocks.csproj   # Target: net10.0
│   │
│   ├── ApiGateways/
│   │   └── Web.Gateway/            # YARP Reverse Proxy — single entry point for all clients
│   │       ├── Program.cs          # JWT validation, rate limiting, X-User-Id header propagation
│   │       └── appsettings.json    # Route table: /auth, /users, /trips, /expenses, /notifications
│   │
│   ├── Services/
│   │   │
│   │   ├── Identity/
│   │   │   └── Identity.API/       # User registration, login, JWT issuance, OTP (port 5127)
│   │   │       ├── Controllers/    # AuthController (register, login, logout, validate, me)
│   │   │       ├── Data/           # AppDbContext (ASP.NET Core Identity + EF Core + Npgsql)
│   │   │       ├── Models/         # User entity, auth request/response models
│   │   │       └── Services/       # IAuthService (JWT + OTP), IEmailService (MailKit SMTP)
│   │   │
│   │   ├── Trip/
│   │   │   └── Trip.API/           # Trip & member management (port 5128)
│   │   │       ├── Controllers/    # Trip CRUD + member operations
│   │   │       ├── Data/           # TripDbContext, TripRepository
│   │   │       ├── Domain/         # Trip, TripMember entities
│   │   │       ├── Features/       # CQRS handlers: CreateTrip, GetTrip, GetUserTrips,
│   │   │       │                   #   JoinTrip, LeaveTrip, RemoveMember, UpdateTrip
│   │   │       ├── IntegrationEvents/  # Events published to Outbox
│   │   │       └── Migrations/     # EF Core migration files
│   │   │
│   │   ├── Expense/
│   │   │   └── Expense.API/        # Expense tracking, debt management (port 5129)
│   │   │       ├── Controllers/    # Expense endpoints
│   │   │       ├── Data/           # ExpenseDbContext
│   │   │       ├── Domain/         # Expense, ExpenseSplit, TripPool, PoolContribution,
│   │   │       │                   #   DebtRecord entities
│   │   │       ├── Features/       # CQRS handlers: CreateExpense, GetTripExpenses,
│   │   │       │                   #   GetTripBalances, GetTripPool, ContributeToPool,
│   │   │       │                   #   ScanBill (AI OCR), SettleDebt
│   │   │       ├── Services/       # CurrencyConversionService, DebtSimplificationService,
│   │   │       │                   #   StaticExchangeRateProvider
│   │   │       ├── IntegrationEvents/  # Events published to Outbox
│   │   │       └── Migrations/     # EF Core migration files
│   │   │
│   │   └── Notification/
│   │       └── Notification.API/   # FCM push notifications & notification history (port 5130)
│   │           ├── Controllers/    # DevicesController, NotificationsController, EventsController
│   │           ├── Data/           # NotificationDbContext
│   │           ├── Domain/         # DeviceRegistration, NotificationLog entities
│   │           ├── EventHandlers/  # NotificationEventProcessor (processes Outbox events)
│   │           └── Migrations/     # EF Core migration files
│   │
│   └── Clients/
│       └── mobile/                 # Flutter cross-platform mobile application
│           ├── lib/
│           │   ├── main.dart       # App entry; ProviderScope + AppAuthStatus routing
│           │   ├── core/
│           │   │   ├── network/    # HTTP client configuration, API base URL
│           │   │   └── theme/      # AppTheme (Heritage Navy, Luminous Azure, Sand Gold tokens)
│           │   └── features/       # Feature-first folder structure
│           │       ├── auth/       # Registration, OTP verify, login, welcome flow
│           │       ├── expense/    # Expense list, add expense, debt balances
│           │       ├── home/       # Main layout screen, navigation shell
│           │       ├── notification/ # Notification list & push handling
│           │       ├── search/     # Trip/user search
│           │       ├── settings/   # App settings
│           │       ├── user_profile/ # Profile setup & edit
│           │       └── analytics/  # Trip analytics & spending insights
│           ├── DESIGN.md           # Design system tokens (colors, typography, spacing, radius)
│           └── pubspec.yaml        # Flutter dependencies
│
├── tests/
│   └── integration-test.ps1        # Full end-to-end PowerShell integration test suite
│
├── database_schema.md              # Detailed DB schema for all 4 microservice databases
└── Miane.sln                       # .NET solution file
```

---

## 7. API Gateway & Service Endpoints

All client requests should go through the **Web Gateway at `http://localhost:5000`**. The gateway validates JWTs and forwards requests to the appropriate microservice.

### Public Routes (no authentication required)

| Method | Path | Service | Description |
|--------|------|---------|-------------|
| `POST` | `/auth/register` | Identity | Register a new user |
| `POST` | `/auth/register/send-otp` | Identity | Send OTP email for registration |
| `POST` | `/auth/register/verify-otp` | Identity | Verify OTP and issue tokens |
| `POST` | `/auth/login` | Identity | Login; returns JWT access + refresh tokens (HttpOnly cookies) |

### Protected Routes (Bearer token required)

| Method | Path | Service | Description |
|--------|------|---------|-------------|
| `GET` | `/auth/me` | Identity | Get current user profile |
| `GET` | `/auth/validate` | Identity | Validate current JWT |
| `POST` | `/auth/logout` | Identity | Invalidate session |
| `GET` | `/users/{**catch-all}` | Identity | User management endpoints |
| `GET/POST` | `/trips` | Trip | List user trips / Create a trip |
| `GET/PUT` | `/trips/{id}` | Trip | Get trip details / Update trip |
| `POST` | `/trips/join` | Trip | Join a trip via invite code |
| `POST` | `/trips/{id}/leave` | Trip | Leave a trip |
| `GET/POST` | `/expenses` | Expense | List/create expenses |
| `GET` | `/expenses/trip/{id}` | Expense | Get all expenses for a trip |
| `GET` | `/expenses/trip/{id}/balances` | Expense | Get simplified debt balances |
| `POST` | `/expenses/settle` | Expense | Settle a specific debt record |
| `GET/POST` | `/expenses/pool/{tripId}` | Expense | Get pool / contribute funds |
| `GET` | `/notifications` | Notification | Get notification history |

> The gateway propagates **`X-User-Id`** and **`X-User-Tier`** HTTP headers (extracted from JWT claims) to all downstream services, so individual services do not validate JWTs directly.

---

## 8. Database Schema Overview

The system uses **4 isolated PostgreSQL databases**, one per microservice. Each service manages its own schema via EF Core migrations.

| Database | Managed By | Key Tables |
|----------|-----------|-----------|
| `Miane_identity` | Identity.API | `Users`, `Roles`, `UserRoles`, `UserTokens`, `OutboxMessages` |
| `Miane_trip` | Trip.API | `Trips`, `TripMembers`, `OutboxMessages` |
| `Miane_expense` | Expense.API | `Expenses`, `ExpenseSplits`, `TripPools`, `PoolContributions`, `DebtRecords`, `OutboxMessages` |
| `Miane_notification` | Notification.API | `DeviceRegistrations`, `NotificationLogs` |

All databases except `Miane_identity` include an `OutboxMessages` table for the **Transactional Outbox Pattern**, ensuring reliable event delivery between services without a message broker. See [`database_schema.md`](./database_schema.md) for the full column-level schema documentation.

---

## 9. Running Tests

### Integration Tests (Full End-to-End)

The `tests/integration-test.ps1` script performs a complete user journey test across all microservices through the API Gateway. It covers:

- ✅ User registration, OTP flow, login, JWT claim validation
- ✅ Trip creation, joining via invite code, member management
- ✅ Expense creation (equal split, custom split, multi-currency)
- ✅ Debt simplification algorithm validation
- ✅ Debt settlement flow
- ✅ Trip Pool contribution and balance checks
- ✅ FCM device registration and notification retrieval
- ✅ Authorization enforcement (403 Forbidden for non-members)
- ✅ Input validation (400 for negative amounts, 404 for bad invite codes, 409 for duplicate joins)

**Run the tests** (requires the full stack to be running):

```powershell
# From the project root
.\tests\integration-test.ps1

# With custom gateway URL or extended startup wait
.\tests\integration-test.ps1 -GatewayUrl "http://localhost:5000" -StartupWaitSeconds 15
```

### Flutter Unit & Widget Tests

```bash
cd src/Clients/mobile

# Run all Flutter tests
flutter test
```

### Static Analysis

```bash
# .NET — all services
dotnet analyze

# Flutter
cd src/Clients/mobile
flutter analyze
```

---

## 10. Contribution Guidelines

### Branching Strategy

```
main              ← production-ready code only
  └── develop     ← integration branch for all features
        └── feature/<short-description>   ← new features
        └── fix/<short-description>       ← bug fixes
        └── chore/<short-description>     ← tooling, deps, CI
```

### Commit Message Convention

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <short summary>

Examples:
feat(expense): add multi-currency conversion on expense creation
fix(identity): correct OTP expiry comparison to use UTC
chore(deps): bump EF Core to 10.0.8
docs(readme): update getting started guide
```

**Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `perf`

### Pull Request Process

1. Branch from `develop` (never from `main` directly).
2. Keep PRs focused — one feature or fix per PR.
3. Ensure all services compile: `dotnet build Miane.sln`.
4. Run static analysis and fix all warnings: `dotnet analyze`.
5. Run the integration test suite against your local stack.
6. For Flutter changes, run `flutter analyze` and `flutter test`.
7. If you changed any `@riverpod` or `@freezed` annotated code, regenerate: `flutter pub run build_runner build --delete-conflicting-outputs`.
8. Request review from at least one team member before merging.

### Code Style

- **Backend (.NET):** Follow standard C# conventions; use `async/await` throughout; prefer `record` types for DTOs.
- **Flutter/Dart:** Follow the project's `analysis_options.yaml` linting rules; use Riverpod `AsyncNotifier` / `Notifier` (no `setState`-heavy widgets); structure all features under `lib/features/{feature_name}/data/`, `domain/`, and `presentation/`.
- **No placeholder code:** All committed code must be complete and production-ready. Do not commit `// TODO` blocks without an accompanying GitHub Issue.

---

<div align="center">

**MIT License** · Copyright © 2026 Quang Minh

</div>
