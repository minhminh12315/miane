<div align="center">

# MIANE

Ứng dụng lập kế hoạch chuyến đi và quản lý chi tiêu nhóm.

[![.NET](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet)](https://dotnet.microsoft.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Dart%20%5E3.5-02569B?logo=flutter)](https://flutter.dev/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)](https://docs.docker.com/compose/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

</div>

> MIANE hiện là một codebase phục vụ phát triển và demo local. README này mô
> tả những gì đang có trong code tại thời điểm hiện tại, bao gồm cả các giới
> hạn chưa hoàn thiện.

## Mục lục

- [Chức năng hiện có](#chức-năng-hiện-có)
- [Kiến trúc và công nghệ](#kiến-trúc-và-công-nghệ)
- [Chạy nhanh bằng Docker](#chạy-nhanh-bằng-docker)
- [Cấu hình `.env`](#cấu-hình-env)
- [Chạy Flutter trên iOS Simulator hoặc thiết bị thật](#chạy-flutter-trên-ios-simulator-hoặc-thiết-bị-thật)
- [Chạy chế độ phát triển](#chạy-chế-độ-phát-triển)
- [Admin Dashboard](#admin-dashboard)
- [Dữ liệu mẫu và reset dữ liệu](#dữ-liệu-mẫu-và-reset-dữ-liệu)
- [Kiểm thử](#kiểm-thử)
- [Giới hạn hiện tại](#giới-hạn-hiện-tại)
- [Xử lý lỗi thường gặp](#xử-lý-lỗi-thường-gặp)

## Chức năng hiện có

### Tài khoản

- Đăng ký và đăng nhập bằng email.
- OTP qua SMTP cho đăng ký và quên mật khẩu.
- Access token, refresh token và phiên đăng nhập lưu trong Redis.
- Đăng nhập Google trên iOS khi OAuth client được cấu hình đúng.
- Hồ sơ người dùng, avatar và phân quyền Admin/Employee.
- Nút đăng nhập Apple đang có trên giao diện nhưng **chưa được tích hợp**.

### Chuyến đi

- Tạo, sửa, xóa, tham gia bằng invite code và quản lý thành viên.
- Kiểm tra tên, địa điểm, thứ tự ngày; cảnh báo khi tạo chuyến trong quá khứ
  hoặc chuyến quá dài.
- Quản lý các chặng đi, tài liệu, ghi chú và file của chuyến.
- Upload ảnh bìa lên `Trip.API`.
- Tạo ảnh bìa bằng OpenAI thông qua service FastAPI và cache kết quả.

### Chi tiêu

- Tạo và chia khoản chi, xem số dư và công nợ.
- Trip Pool/Wallet, yêu cầu góp quỹ và thay đổi người giữ quỹ.
- Lưu tài khoản nhận tiền, lấy danh sách ngân hàng và tạo VietQR.
- Quét hóa đơn hoặc biên lai chuyển khoản trên iOS bằng Apple Vision; text
  được xử lý on-device và đi qua parser rule-based tiếng Việt trước khi người
  dùng xác nhận.
- OCR không gửi ảnh lên OpenAI.

### Thông báo và quản trị

- Notification service lưu lịch sử thông báo trong PostgreSQL và mobile có
  màn hình đọc/đánh dấu đã đọc.
- Admin Dashboard riêng bằng React + Node/Express, dùng API thật và dữ liệu
  thật từ PostgreSQL.
- Thông báo hiện là in-app notification; project không dùng dịch vụ push bên
  ngoài.

## Kiến trúc và công nghệ

```text
Flutter iOS/Web
    ├── HTTP/JWT ──> Web.Gateway :8080
    │                   ├── Identity.API     :5127
    │                   ├── Trip.API         :5128
    │                   ├── Expense.API      :5129
    │                   └── Notification.API :5130
    │                         │
    │                  PostgreSQL + Redis
    │
    └── tạo ảnh bìa ──> FastAPI AI Image :8000 ──> OpenAI Images API

Admin React :5173 ──> Admin Node :4000 ──> các API backend
```

| Thành phần | Công nghệ |
|---|---|
| Mobile/Web client | Flutter, Dart `^3.5.0`, Riverpod |
| OCR iOS | Apple Vision `VNRecognizeTextRequest` + parser Dart |
| Backend | ASP.NET Core / .NET 10, EF Core, MediatR |
| Gateway | YARP, JWT validation, rate limiting |
| Database | PostgreSQL 16, 4 database tách biệt |
| Cache/session | Redis 7 |
| AI cover | FastAPI + OpenAI Images API |
| Admin | React 19, Vite, Node/Express |

Các database:

- `Miane_identity`
- `Miane_trip`
- `Miane_expense`
- `Miane_notification`

Migrations trong từng service là nguồn thông tin schema chính xác nhất.
[`database_schema.md`](./database_schema.md) là tài liệu tham khảo bổ sung và
có thể chậm hơn migration mới nhất.

## Cấu trúc chính

```text
miane/
├── .env.example
├── docker-compose.yml
├── docker-compose.dev.yml
├── docker/postgres-init.sql
├── services/ai-image/
├── admin-dashboard/
├── src/
│   ├── ApiGateways/Web.Gateway/
│   ├── BuildingBlocks/
│   ├── Clients/mobile/
│   └── Services/
│       ├── Identity/Identity.API/
│       ├── Trip/Trip.API/
│       ├── Expense/Expense.API/
│       └── Notification/Notification.API/
└── tests/integration-test.ps1
```

## Yêu cầu môi trường

### Chạy toàn bộ bằng Docker

- Docker Desktop có Docker Compose v2.
- Git.

### Phát triển native/local

- .NET SDK 10.
- Flutter có Dart tương thích `^3.5.0`.
- Xcode và CocoaPods khi chạy iOS.
- Node.js/npm khi chạy Admin Dashboard.
- PowerShell 7 nếu chạy `tests/integration-test.ps1`.

Kiểm tra nhanh:

```bash
docker compose version
dotnet --version
flutter --version
node --version
```

## Chạy nhanh bằng Docker

### 1. Tạo file cấu hình

Tại thư mục gốc:

```bash
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Sau đó mở `.env` và ít nhất hãy:

- đổi `JWT_SIGNING_KEY`;
- cấu hình SMTP nếu muốn đăng ký/đặt lại mật khẩu từ mobile;
- thêm `OPENAI_API_KEY` nếu muốn tạo ảnh bìa AI;
- thêm VietQR credentials nếu muốn sinh QR chuyển khoản.

Không commit `.env`. File này đã được `.gitignore`.

### 2. Kiểm tra Compose

```bash
docker compose --env-file .env config --quiet
```

Lệnh trên chỉ kiểm tra cú pháp. Không nên gửi output đầy đủ của
`docker compose config` cho người khác vì output có thể chứa secret đã được
nội suy.

### 3. Khởi động

```bash
docker compose --env-file .env up -d --build
```

Theo dõi trạng thái:

```bash
docker compose ps
docker compose logs -f web-gateway identity-api trip-api expense-api notification-api ai-image
```

### 4. Kiểm tra

```bash
curl http://localhost:8080/
# Miane Web Gateway

curl http://localhost:8000/health
```

| Thành phần | URL/cổng host | Ghi chú |
|---|---|---|
| Flutter Web | <http://localhost:3000> | Build release do Nginx phục vụ |
| Web Gateway | <http://localhost:8080> | Điểm vào API của client |
| Identity API | <http://localhost:5127> | Direct dev access |
| Trip API | <http://localhost:5128> | Direct dev access |
| Expense API | <http://localhost:5129> | Direct dev access |
| Notification API | <http://localhost:5130> | Direct dev access |
| AI Image | <http://localhost:8000> | Health + tạo/cache ảnh |
| PostgreSQL | `localhost:5432` | User mặc định `Miane` |
| Redis | `localhost:6370` | Container dùng cổng nội bộ `6379` |

OpenAPI chỉ được map trong môi trường Development và có thể xem trực tiếp tại
`http://localhost:<service-port>/openapi/v1.json`.

## Cấu hình `.env`

### `.env` được sử dụng ở đâu?

- `docker compose` tự đọc `.env` ở thư mục project.
- `docker-compose.yml` truyền các giá trị runtime vào backend/AI service và
  truyền build arguments vào Flutter Web.
- `flutter run` chạy trực tiếp **không đọc `.env`**. Các giá trị cho Flutter
  native phải truyền bằng `--dart-define`.
- `appsettings*.json` cung cấp cấu hình mặc định cho .NET; biến môi trường của
  Compose ghi đè chúng bằng cú pháp `Section__Key`.

Nếu dùng file khác:

```bash
docker compose --env-file .env.local up -d --build
```

Không đặt `COMPOSE_FILE` trong `.env` trừ khi bạn chủ động muốn Compose tự ghép
nhiều file. Để chọn cấu hình dev, dùng `-f docker-compose.dev.yml` rõ ràng.

### Cú pháp và secret

- Viết `KEY=value`, không thêm khoảng trắng quanh dấu `=`.
- Với giá trị chứa khoảng trắng, `$` hoặc `#`, nên dùng dấu nháy đơn:

```dotenv
SMTP_PASSWORD='app password or special#value'
```

- Dùng một JWT key riêng cho mỗi môi trường:

```bash
openssl rand -hex 32
```

- Không đưa API key, service-account JSON, App Password hoặc connection string
  production vào Git, ảnh chụp màn hình hay log hỗ trợ.

### Cấu hình tối thiểu cho local

```dotenv
MOBILE_API_URL=http://localhost:8080
MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail

JWT_SIGNING_KEY=<chuoi-random-it-nhat-32-ky-tu>

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
SMTP_FROM_NAME=MIANE

OPENAI_API_KEY=
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_IMAGE_SIZE=1536x1024
OPENAI_IMAGE_QUALITY=medium
OPENAI_IMAGE_FORMAT=jpeg
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000

VIETQR_CLIENT_ID=
VIETQR_API_KEY=
```

Giá trị trống của các connection string sẽ dùng PostgreSQL trong Compose.

### Bảng biến quan trọng

| Biến | Thành phần đọc | Khi nào cần | Mặc định/hành vi |
|---|---|---|---|
| `MOBILE_API_URL` | Flutter Web build/dev Compose | Luôn cần client gọi backend | `http://localhost:8080` |
| `MIANE_AI_IMAGE_URL` | Flutter Web build/dev Compose | Khi dùng tạo ảnh AI | Endpoint AI local |
| `JWT_SIGNING_KEY` | Identity, Trip, Expense, Notification, Gateway | Bắt buộc; mọi service phải cùng key | Có fallback chỉ dành cho development |
| `*_DB_CONNECTION_STRING` | Từng .NET service | Chỉ khi không dùng PostgreSQL Compose | Blank dùng host `postgres` |
| `SMTP_*` | Identity API | OTP đăng ký và quên mật khẩu | Blank làm luồng gửi OTP lỗi |
| `GOOGLE_CLIENT_ID` | Identity API | Xác minh Google ID token | Phải khớp audience của token |
| `GOOGLE_BYPASS_VALIDATION` | Identity API | Chỉ mock/debug có chủ đích | `false` |
| `OPENAI_API_KEY` | AI Image service | Nút tạo ảnh bằng AI | Blank trả lỗi cấu hình; upload tay vẫn hoạt động |
| `OPENAI_IMAGE_*` | AI Image service | Tùy chỉnh model/size/chất lượng/format | Xem `.env.example` |
| `AI_IMAGE_PUBLIC_BASE_URL` | AI Image service | URL ảnh trả về cho client | `http://localhost:8000` |
| `AI_IMAGE_CACHE_DIR` | AI Image service | Đổi thư mục cache trong container | `/app/cache` |
| `AI_IMAGE_USE_OLLAMA` | AI Image service | Chọn landmark bằng Ollama local | `false` |
| `OLLAMA_BASE_URL` | AI Image service | Khi bật Ollama | `http://localhost:11434` |
| `VIETQR_CLIENT_ID`, `VIETQR_API_KEY` | Expense API | Sinh VietQR | Bank list vẫn dùng được khi để trống |
| `AI_SERVICE_URL`, `AI_SERVICE_API_KEY` | .NET AI planner client | Hiện chưa có user flow gọi tới | Reserved |

Danh sách đầy đủ và hướng dẫn theo từng nhà cung cấp nằm trong
[`ENV_KEYS_GUIDE.md`](./ENV_KEYS_GUIDE.md).

### Sau khi sửa `.env`

Biến backend và AI là runtime environment của container. Tạo lại container:

```bash
docker compose --env-file .env up -d --force-recreate \
  identity-api trip-api expense-api notification-api web-gateway ai-image
```

`MOBILE_API_URL` và `MIANE_AI_IMAGE_URL` là build-time values của Flutter Web.
Build lại mobile container:

```bash
docker compose --env-file .env up -d --build mobile-client
```

## Cấu hình theo tính năng

### Email OTP

Mobile registration và forgot-password gọi SMTP thật. Với Gmail:

1. Bật 2-Step Verification.
2. Tạo Google App Password.
3. Đặt App Password vào `SMTP_PASSWORD`, không dùng mật khẩu Gmail thường.
4. `SMTP_FROM_EMAIL` thường giống `SMTP_USERNAME`.

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=you@example.com
SMTP_PASSWORD='16-character-app-password'
SMTP_FROM_EMAIL=you@example.com
SMTP_FROM_NAME=MIANE
```

Sau khi đổi:

```bash
docker compose up -d --force-recreate identity-api
docker compose logs -f identity-api
```

### OpenAI tạo ảnh bìa

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_IMAGE_SIZE=1536x1024
OPENAI_IMAGE_QUALITY=medium
OPENAI_IMAGE_FORMAT=jpeg
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
```

`medium` và `jpeg` là cấu hình local hiện tại để giảm thời gian và kích thước
ảnh. Test:

```bash
curl http://localhost:8000/health

curl -X POST http://localhost:8000/api/v1/image/generate-trip-thumbnail \
  -H 'Content-Type: application/json' \
  -d '{"placeName":"Đà Lạt","country":"Vietnam"}'
```

### Google Sign-In

Có hai phía khác nhau:

- `GOOGLE_CLIENT_ID` trong `.env`: backend dùng để xác minh `aud` của ID token.
- `GIDClientID`/`GIDServerClientID`: iOS đọc từ
  `src/Clients/mobile/ios/Runner/Info.plist`.

Hai phía phải thuộc cấu hình OAuth tương thích. Xem
[`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md).

Không bật `GOOGLE_BYPASS_VALIDATION=true` ở môi trường dùng chung hoặc
production.

### VietQR

```dotenv
VIETQR_BASE_URL=https://api.vietqr.io/
VIETQR_CLIENT_ID=
VIETQR_API_KEY=
```

- Lấy bank list: không cần credentials.
- Sinh QR: cần cả Client ID và API key.
- VietQR chỉ tạo payload/ảnh QR; code hiện không tự xác nhận tiền đã vào ngân
  hàng.

### Thông báo

Notification service lưu và trả lịch sử thông báo từ PostgreSQL. Mobile đọc,
đánh dấu từng thông báo hoặc đánh dấu tất cả đã đọc qua Gateway. Project không
tích hợp dịch vụ push bên ngoài và không cần key thông báo trong `.env`.

## Chạy Flutter trên iOS Simulator hoặc thiết bị thật

Khởi động backend trước:

```bash
docker compose --env-file .env up -d \
  postgres redis identity-api trip-api expense-api notification-api web-gateway ai-image
```

Cài dependency và generate Riverpod:

```bash
cd src/Clients/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### iOS Simulator trên cùng máy

```bash
flutter run \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
```

### iPhone thật trong cùng mạng LAN

`localhost` trên điện thoại là điện thoại, không phải máy dev. Tìm LAN IP của
máy, ví dụ `192.168.1.10`, rồi:

```bash
flutter run -d <device-id> \
  --dart-define=API_URL=http://192.168.1.10:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://192.168.1.10:8000/api/v1/image/generate-trip-thumbnail
```

Đồng thời sửa `.env`:

```dotenv
AI_IMAGE_PUBLIC_BASE_URL=http://192.168.1.10:8000
```

và tạo lại AI container:

```bash
docker compose up -d --force-recreate ai-image
```

Máy và iPhone phải cùng mạng; firewall phải cho phép các cổng cần dùng.

Project hiện có platform folders cho iOS và Web. OCR native được cài trong
`ios/Runner/AppDelegate.swift`, vì vậy luồng quét hóa đơn/biên lai hiện chỉ
được hỗ trợ đúng trên iOS/iOS Simulator.

## Chạy chế độ phát triển

### Full stack với `docker-compose.dev.yml`

File dev dùng `dotnet watch`, mount source và chạy Flutter web-server:

```bash
docker compose -f docker-compose.dev.yml --env-file .env up -d --build
```

Xem log:

```bash
docker compose -f docker-compose.dev.yml logs -f
```

Dừng:

```bash
docker compose -f docker-compose.dev.yml down
```

### Chỉ chạy PostgreSQL và Redis trong Docker

```bash
docker compose -f docker-compose.dev.yml up -d postgres redis
```

Sau đó có thể chạy từng .NET service bằng `dotnet run`. Lưu ý cấu hình gateway
mặc định chứa hostname Docker (`identity-api`, `trip-api`, ...); nếu chạy
gateway trực tiếp trên host, phải override các YARP destination sang
`http://localhost:<port>`.

## Admin Dashboard

Admin Dashboard không nằm trong Docker Compose chính.

Khởi động backend:

```bash
docker compose up -d postgres redis identity-api trip-api expense-api notification-api
```

Terminal 1:

```bash
cd admin-dashboard/server
npm install
npm start
```

Terminal 2:

```bash
cd admin-dashboard
npm install
npm run dev
```

Mở <http://localhost:5173>. Tài khoản development được seed:

```text
admin@Miane.local / Admin@123
```

Đây là credentials demo hard-coded trong seeder. Không dùng nguyên trạng ngoài
local development. Xem thêm [`admin-dashboard/README.md`](./admin-dashboard/README.md).

## Dữ liệu mẫu và reset dữ liệu

Khi chạy với `ASPNETCORE_ENVIRONMENT=Development`, service tự:

- chạy EF Core migrations;
- seed Admin/Employee;
- seed 6 người dùng demo;
- seed chuyến Đà Nẵng, expenses, debts, payment methods và trip wallet mẫu.

Vì vậy `docker compose down -v` rồi chạy lại sẽ tạo database mới nhưng **không
hoàn toàn trống**: dữ liệu development sẽ được seed lại. Hiện chưa có biến môi
trường để tắt demo seeder.

Dừng và giữ các named volume (PostgreSQL, ảnh/cache, uploads và keys):

```bash
docker compose down
```

Redis trong `docker-compose.yml` không có named volume, nên cache/session Redis
sẽ mất khi container bị xóa dù không dùng `-v`.

Xóa toàn bộ volume của riêng project:

```bash
docker compose down --volumes --remove-orphans
docker compose up -d --build
```

Lệnh trên xóa không thể khôi phục:

- PostgreSQL;
- cache ảnh AI;
- ảnh bìa và file chuyến đi trong `trip_uploads`;
- Data Protection keys của Expense API.

Không cần dùng `docker system prune`, vì lệnh đó có thể ảnh hưởng project khác.

## Kiểm thử

### Backend build

```bash
dotnet build Miane.sln
```

### Flutter

```bash
cd src/Clients/mobile
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
```

### Integration PowerShell

Full stack phải đang chạy:

```powershell
pwsh ./tests/integration-test.ps1
```

Gateway mặc định của script là `http://localhost:8080`. Có thể override:

```powershell
pwsh ./tests/integration-test.ps1 `
  -GatewayUrl "http://localhost:8080" `
  -StartupWaitSeconds 15
```

## Giới hạn hiện tại

- Apple Sign-In chưa được cấu hình.
- Thông báo hiện chỉ hiển thị trong app, không có push notification.
- AI service trong `services/ai-image` chỉ tạo ảnh bìa. Interface .NET cho AI
  trip planner có tồn tại nhưng chưa có user-facing endpoint sử dụng, và
  FastAPI hiện không triển khai `/api/planner/suggest`.
- OCR chỉ có native implementation trên iOS; parser vẫn là heuristic nên mọi
  kết quả đều cần màn hình xác nhận trước khi lưu.
- Tỷ giá trong Expense service là static provider, không phải tỷ giá live.
- Admin Dashboard giữ session trong RAM của Node server; restart server sẽ
  đăng xuất tất cả admin.
- Các API nghiệp vụ của Trip/Expense/Notification tin `X-User-Id` do Gateway
  truyền; client bình thường phải gọi qua Gateway, không gọi trực tiếp service.

## Xử lý lỗi thường gặp

### `401 Unauthorized`

- Kiểm tra tất cả service và Gateway dùng cùng `JWT_SIGNING_KEY`.
- Đăng xuất/đăng nhập lại sau khi đổi JWT key.
- Không gọi protected API trực tiếp nếu không hiểu cơ chế header/JWT của service.

### OTP không gửi

```bash
docker compose logs -f identity-api
```

Kiểm tra `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_FROM_EMAIL`; Gmail yêu cầu App
Password khi bật xác minh hai bước.

### Tạo ảnh AI lỗi hoặc chậm

```bash
docker compose logs -f ai-image
curl http://localhost:8000/health
```

Kiểm tra `OPENAI_API_KEY`, billing/quota và URL mà client có thể truy cập.

### App trên iPhone không gọi được backend

- Không dùng `localhost`.
- Dùng LAN IP của máy dev cho `API_URL`, `MIANE_AI_IMAGE_URL` và
  `AI_IMAGE_PUBLIC_BASE_URL`.
- Kiểm tra cùng Wi-Fi và firewall.

### Đổi `.env` nhưng app web vẫn dùng URL cũ

URL Flutter Web được nhúng lúc build:

```bash
docker compose up -d --build mobile-client
```

### Database mới nhưng vẫn có dữ liệu

Đó là dữ liệu từ development seeders, không phải volume cũ. Xem
[Dữ liệu mẫu và reset dữ liệu](#dữ-liệu-mẫu-và-reset-dữ-liệu).

## Tài liệu liên quan

- [Hướng dẫn biến môi trường](./ENV_KEYS_GUIDE.md)
- [Google Sign-In](./GOOGLE_SIGNIN_SETUP.md)
- [Yêu cầu OCR local](./AI_OCR_LOCAL_REQUIREMENTS.md)
- [AI Image service](./services/ai-image/README.md)
- [Admin Dashboard](./admin-dashboard/README.md)
- [SRS tiếng Việt](./SRS_vi.md)
- [Database schema](./database_schema.md)

## License

[MIT](./LICENSE)
