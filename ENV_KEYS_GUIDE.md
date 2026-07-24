# Hướng dẫn cấu hình `.env` cho MIANE

Tài liệu này mô tả các biến môi trường đang xuất hiện trong
`docker-compose.yml`, `docker-compose.dev.yml`, Flutter build và AI Image
service.

> `.env.example` chỉ chứa tên biến và development defaults. Secret thật phải
> nằm trong `.env` local hoặc secret manager của môi trường triển khai.

## 1. Tạo và kiểm tra file

macOS/Linux:

```bash
cp .env.example .env
```

Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Kiểm tra cú pháp mà không in secret ra terminal:

```bash
docker compose --env-file .env config --quiet
```

Docker Compose tự đọc `.env` nếu chạy từ thư mục gốc, nhưng ghi rõ
`--env-file` giúp tránh nhầm file:

```bash
docker compose --env-file .env up -d --build
```

### Quy tắc an toàn

- Không commit `.env`.
- Không gửi output đầy đủ của `docker compose config`, vì secret đã được nội
  suy có thể xuất hiện trong output.
- Không dùng development JWT key ở staging/production.
- Không để `GOOGLE_BYPASS_VALIDATION=true` ngoài debug local.
- Không đưa OpenAI key, SMTP App Password hoặc VietQR key vào Flutter
  `--dart-define`; client binary không phải nơi giữ secret.

Giá trị có ký tự đặc biệt nên đặt trong nháy đơn:

```dotenv
SMTP_PASSWORD='special value with # or $'
```

Tạo JWT key local mới:

```bash
openssl rand -hex 32
```

## 2. Giá trị tối thiểu theo nhu cầu

### Chỉ chạy backend và đăng nhập tài khoản seed

```dotenv
MOBILE_API_URL=http://localhost:8080
JWT_SIGNING_KEY=<random-key-at-least-32-characters>
```

SMTP, OpenAI và VietQR có thể để trống. Bạn vẫn đăng nhập được bằng tài khoản
development đã seed.

### Test đăng ký và quên mật khẩu từ mobile

Thêm:

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=you@example.com
SMTP_PASSWORD='gmail-app-password'
SMTP_FROM_EMAIL=you@example.com
SMTP_FROM_NAME=MIANE
```

### Test tạo ảnh bìa AI

Thêm:

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_IMAGE_SIZE=1536x1024
OPENAI_IMAGE_QUALITY=medium
OPENAI_IMAGE_FORMAT=jpeg
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
```

### Test tạo VietQR

Thêm:

```dotenv
VIETQR_CLIENT_ID=<client-id>
VIETQR_API_KEY=<api-key>
```

## 3. Client URLs

### `MOBILE_API_URL`

Gateway URL được nhúng vào Flutter Web khi Docker build `mobile-client`.

```dotenv
MOBILE_API_URL=http://localhost:8080
```

Được dùng bởi:

- build argument `API_URL` trong `docker-compose.yml`;
- `--dart-define=API_URL` trong `docker-compose.dev.yml`.

Khi thay đổi:

```bash
docker compose --env-file .env up -d --build mobile-client
```

### `MIANE_AI_IMAGE_URL`

Endpoint Flutter gọi trực tiếp để tạo ảnh:

```dotenv
MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
```

Đây là URL phía **client** nhìn thấy. Không dùng hostname Docker như
`http://ai-image:8000`, vì browser/iPhone không phân giải được hostname đó.

### `AI_IMAGE_PUBLIC_BASE_URL`

Base URL được AI service đặt vào `imageUrl` của response:

```dotenv
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
```

Nó cũng phải là URL client truy cập được:

| Client | API URL | AI public URL |
|---|---|---|
| Flutter Web trên máy dev | `http://localhost:8080` | `http://localhost:8000` |
| iOS Simulator trên cùng Mac | `http://localhost:8080` | `http://localhost:8000` |
| iPhone thật | `http://<LAN-IP>:8080` | `http://<LAN-IP>:8000` |

Sau khi đổi `AI_IMAGE_PUBLIC_BASE_URL`:

```bash
docker compose up -d --force-recreate ai-image
```

## 4. Flutter native không đọc `.env`

`.env` chỉ được Docker Compose đọc. Lệnh `flutter run` trực tiếp cần
`--dart-define`.

iOS Simulator:

```bash
cd src/Clients/mobile

flutter run \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
```

iPhone thật, ví dụ máy dev là `192.168.1.10`:

```bash
flutter run -d <device-id> \
  --dart-define=API_URL=http://192.168.1.10:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://192.168.1.10:8000/api/v1/image/generate-trip-thumbnail
```

Flutter define khác đang có trong code:

```text
GOOGLE_AUTH_ALLOW_MOCK_FALLBACK
```

Chỉ bật trong debug local có chủ đích:

```bash
flutter run \
  --dart-define=GOOGLE_AUTH_ALLOW_MOCK_FALLBACK=true
```

Khi bật, client có thể gửi `mock_google_token` nếu native Google Sign-In lỗi.
Backend hiện chấp nhận token mock chính xác này trong code development. Không
đưa build/cấu hình này lên môi trường public.

## 5. JWT

```dotenv
JWT_SIGNING_KEY=<unique-random-secret>
```

Key được truyền vào:

- Identity API;
- Trip API;
- Expense API;
- Notification API;
- Web Gateway.

Tất cả phải dùng cùng một key để JWT do Identity phát hành được Gateway và các
admin endpoint xác minh.

Sau khi đổi JWT key:

```bash
docker compose up -d --force-recreate \
  identity-api trip-api expense-api notification-api web-gateway
```

Token cũ sẽ không còn hợp lệ. Xóa session local hoặc đăng xuất/đăng nhập lại.

## 6. PostgreSQL

```dotenv
IDENTITY_DB_CONNECTION_STRING=
TRIP_DB_CONNECTION_STRING=
EXPENSE_DB_CONNECTION_STRING=
NOTIFICATION_DB_CONNECTION_STRING=
```

Để trống nghĩa là Compose dùng:

```text
Host=postgres
Port=5432
Username=Miane
Password=Miane_password
```

và database tương ứng:

- `Miane_identity`
- `Miane_trip`
- `Miane_expense`
- `Miane_notification`

Ví dụ dùng PostgreSQL ngoài:

```dotenv
IDENTITY_DB_CONNECTION_STRING='Host=db.example;Port=5432;Database=Miane_identity;Username=miane;Password=...'
TRIP_DB_CONNECTION_STRING='Host=db.example;Port=5432;Database=Miane_trip;Username=miane;Password=...'
EXPENSE_DB_CONNECTION_STRING='Host=db.example;Port=5432;Database=Miane_expense;Username=miane;Password=...'
NOTIFICATION_DB_CONNECTION_STRING='Host=db.example;Port=5432;Database=Miane_notification;Username=miane;Password=...'
```

Khi dùng database ngoài, `docker/postgres-init.sql` không chạy trên server đó.
Bạn phải tạo đủ bốn database trước. Các service sẽ tự chạy EF migrations khi
`ASPNETCORE_ENVIRONMENT=Development`.

## 7. SMTP cho OTP

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_FROM_EMAIL=
SMTP_FROM_NAME=MIANE
```

`Identity.API` yêu cầu username, password và from email khi gửi:

- OTP đăng ký;
- OTP đặt lại mật khẩu.

Nếu thiếu, endpoint gửi OTP trả lỗi cấu hình. Không có cơ chế tự in OTP ra log.

### Gmail

1. Bật 2-Step Verification.
2. Tạo App Password.
3. Dùng App Password làm `SMTP_PASSWORD`.
4. Đặt `SMTP_FROM_EMAIL` giống `SMTP_USERNAME` nếu tài khoản không có alias
   được phép.

Áp dụng thay đổi:

```bash
docker compose up -d --force-recreate identity-api
docker compose logs -f identity-api
```

## 8. Google Sign-In

```dotenv
GOOGLE_CLIENT_ID=...
GOOGLE_BYPASS_VALIDATION=false
```

### Backend

`GOOGLE_CLIENT_ID` là audience mà `Identity.API` yêu cầu khi xác minh Google ID
token.

`GOOGLE_BYPASS_VALIDATION=true` cho phép fallback mock khi token validation
thất bại. Đây là development switch nguy hiểm và phải giữ `false` theo mặc
định.

### iOS

Native Google Sign-In không đọc `GOOGLE_CLIENT_ID` từ `.env`. Nó đọc:

- `GIDClientID`;
- `GIDServerClientID`;
- URL scheme.

từ `src/Clients/mobile/ios/Runner/Info.plist`. Cấu hình chi tiết tại
[`GOOGLE_SIGNIN_SETUP.md`](./GOOGLE_SIGNIN_SETUP.md).

## 9. AI Image service

```dotenv
OPENAI_API_KEY=
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_IMAGE_SIZE=1536x1024
OPENAI_IMAGE_QUALITY=medium
OPENAI_IMAGE_FORMAT=jpeg
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
AI_IMAGE_CACHE_DIR=/app/cache
```

| Biến | Ý nghĩa |
|---|---|
| `OPENAI_API_KEY` | Secret gọi OpenAI Images API |
| `OPENAI_IMAGE_MODEL` | Model ảnh |
| `OPENAI_IMAGE_SIZE` | Kích thước request |
| `OPENAI_IMAGE_QUALITY` | `medium` đang cân bằng tốc độ/chất lượng cho cover |
| `OPENAI_IMAGE_FORMAT` | `jpeg` giảm dung lượng so với PNG |
| `AI_IMAGE_PUBLIC_BASE_URL` | URL ảnh mà client truy cập |
| `AI_IMAGE_CACHE_DIR` | Thư mục cache bên trong container |

Không có `OPENAI_API_KEY` thì health endpoint vẫn chạy, nhưng endpoint tạo ảnh
trả lỗi cấu hình. Upload cover thủ công không phụ thuộc OpenAI.

Test:

```bash
curl http://localhost:8000/health

curl -X POST http://localhost:8000/api/v1/image/generate-trip-thumbnail \
  -H 'Content-Type: application/json' \
  -d '{"placeName":"Hội An","country":"Vietnam"}'
```

### Ollama tùy chọn

```dotenv
AI_IMAGE_USE_OLLAMA=false
OLLAMA_BASE_URL=http://localhost:11434
AI_IMAGE_LANDMARK_MODEL=llama3.2:3b
```

Ollama chỉ chọn landmark để làm giàu prompt; ảnh cuối vẫn do OpenAI tạo.

Nếu Ollama chạy trên host còn AI service chạy trong Docker Desktop, dùng:

```dotenv
OLLAMA_BASE_URL=http://host.docker.internal:11434
```

Không bật Ollama nếu chưa pull model hoặc không cần bước chọn landmark.

## 10. VietQR

```dotenv
VIETQR_BASE_URL=https://api.vietqr.io/
VIETQR_CLIENT_ID=
VIETQR_API_KEY=
```

- `GET /expenses/vietqr/banks`: dùng public bank list, không cần key.
- Các endpoint generate QR: cần Client ID và API key.
- Key chỉ nằm ở Expense API; không đưa xuống Flutter.
- VietQR tạo QR chuyển khoản, không phải webhook xác nhận thanh toán.

Sau khi đổi:

```bash
docker compose up -d --force-recreate expense-api
```

## 11. AI planner variables: reserved

```dotenv
AI_SERVICE_URL=http://localhost:8000
AI_SERVICE_API_KEY=
```

Expense API hiện đăng ký `IAiTripPlannerService`, nhưng:

- không có user-facing controller/handler đang gọi service này;
- `services/ai-image` không triển khai `/api/planner/suggest`.

Hai biến trên hiện không ảnh hưởng các luồng đang dùng. Chúng được giữ để mô tả
đúng phần client scaffold còn tồn tại trong code.

## 12. Admin Dashboard environment

Admin Node server đọc trực tiếp environment của process, không tự đọc `.env`
gốc bằng `dotenv`.

Các biến optional:

```text
IDENTITY_API_URL   default http://localhost:5127
TRIP_API_URL       default http://localhost:5128
EXPENSE_API_URL    default http://localhost:5129
FRONTEND_ORIGIN    default http://localhost:5173
PGHOST             default localhost
PGPORT             default 5432
PGUSER             default Miane
PGPASSWORD         default Miane_password
```

Ví dụ:

```bash
cd admin-dashboard/server
IDENTITY_API_URL=http://localhost:5127 \
TRIP_API_URL=http://localhost:5128 \
EXPENSE_API_URL=http://localhost:5129 \
npm start
```

## 13. Khi thay đổi biến nào thì restart gì?

| Nhóm biến | Lệnh áp dụng |
|---|---|
| `JWT_*`, DB, SMTP, Google backend | `docker compose up -d --force-recreate identity-api trip-api expense-api notification-api web-gateway` |
| `OPENAI_*`, `AI_IMAGE_*`, Ollama | `docker compose up -d --force-recreate ai-image` |
| VietQR | `docker compose up -d --force-recreate expense-api` |
| `MOBILE_API_URL`, `MIANE_AI_IMAGE_URL` | `docker compose up -d --build mobile-client` |
| Flutter native `--dart-define` | Dừng app và chạy lại `flutter run` |

Nếu không chắc service nào dùng biến vừa đổi:

```bash
docker compose --env-file .env up -d --build --force-recreate
```

## 14. Chẩn đoán

```bash
docker compose ps
docker compose logs -f identity-api
docker compose logs -f expense-api
docker compose logs -f ai-image
```

Kiểm tra Gateway và AI:

```bash
curl http://localhost:8080/
curl http://localhost:8000/health
```

Các lỗi thường gặp:

- App web vẫn gọi URL cũ: chưa rebuild `mobile-client`.
- iPhone gọi `localhost`: phải đổi sang LAN IP.
- AI trả URL xem được trên Mac nhưng không xem được trên iPhone:
  `AI_IMAGE_PUBLIC_BASE_URL` vẫn là localhost.
- OTP lỗi: SMTP App Password/FromEmail chưa đúng.
- JWT 401 sau khi đổi key: token cũ không còn hợp lệ.
- PostgreSQL mới vẫn có dữ liệu: Development seeders tự tạo lại demo data.
