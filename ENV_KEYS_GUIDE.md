# Hướng dẫn lấy và cấu hình key cho MIANE

File mẫu đã được cập nhật ở `.env.example`. Khi chạy local, tạo file `.env` ở thư mục gốc:

```powershell
Copy-Item .env.example .env
```

Sau đó điền các key thật vào `.env`, không commit file `.env`.

## 1. OpenAI key cho tạo ảnh chuyến đi

MIANE đang dùng service `services/ai-image` để tạo ảnh bìa từ địa điểm. Mobile app gọi endpoint:

```dotenv
MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
```

Service ảnh cần các biến:

```dotenv
OPENAI_API_KEY=sk-...
OPENAI_IMAGE_MODEL=gpt-image-1.5
OPENAI_IMAGE_SIZE=1536x1024
OPENAI_IMAGE_QUALITY=high
OPENAI_IMAGE_FORMAT=jpeg
AI_IMAGE_PUBLIC_BASE_URL=http://localhost:8000
```

Các bước lấy OpenAI API key:

1. Vào <https://platform.openai.com/>.
2. Đăng nhập tài khoản OpenAI.
3. Vào API keys trong dashboard.
4. Chọn Create new secret key hoặc tạo key trong project phù hợp.
5. Copy key vào `OPENAI_API_KEY`.
6. Kiểm tra billing/quota của project nếu request tạo ảnh trả lỗi quota hoặc billing.

Test nhanh service ảnh:

```powershell
docker compose up ai-image --build
Invoke-RestMethod http://localhost:8000/health
Invoke-RestMethod `
  -Method Post `
  -Uri http://localhost:8000/api/v1/image/generate-trip-thumbnail `
  -ContentType 'application/json' `
  -Body '{"placeName":"Đà Lạt","country":"Vietnam"}'
```

Nếu chạy app trên thiết bị thật, `localhost` là chính thiết bị, không phải máy dev. Khi đó đổi:

```dotenv
MIANE_AI_IMAGE_URL=http://<LAN-IP-may-dev>:8000/api/v1/image/generate-trip-thumbnail
AI_IMAGE_PUBLIC_BASE_URL=http://<LAN-IP-may-dev>:8000
```

Nguồn chính thức:

- OpenAI quickstart/API key: <https://developers.openai.com/api/docs/quickstart>
- OpenAI Images API: <https://developers.openai.com/api/reference/resources/images>

## 2. Google Sign-In

Biến cần kiểm tra khi đăng nhập Google bị sai tài khoản hoặc rơi vào mock:

```dotenv
GOOGLE_CLIENT_ID=135347207127-oido4n87prcqp44lvjtiovfqafr5qkbe.apps.googleusercontent.com
GOOGLE_BYPASS_VALIDATION=false
```

`GOOGLE_CLIENT_ID` phải khớp audience của `idToken` mà mobile app nhận được. Với cấu hình iOS hiện tại, client id nằm trong `ios/Runner/Info.plist`. Xem thêm `GOOGLE_SIGNIN_SETUP.md` trong repo.

## 3. Firebase push notification cho web và iOS

Firebase push notification cần 3 nhóm cấu hình:

- Backend `Notification.API` dùng Firebase Admin SDK để gửi FCM message.
- Flutter web client dùng Firebase Web App config và Web Push VAPID key để test trên Windows.
- Flutter iOS client dùng Firebase iOS App config, APNs key và capability trong Xcode để demo trên iPhone thật.

```dotenv
FIREBASE_SERVICE_ACCOUNT_PATH=C:\path\to\firebase-service-account.json
FIREBASE_PROJECT_ID=your-firebase-project-id
GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\firebase-service-account.json

FIREBASE_WEB_API_KEY=AIza...
FIREBASE_WEB_AUTH_DOMAIN=your-project-id.firebaseapp.com
FIREBASE_WEB_PROJECT_ID=your-project-id
FIREBASE_WEB_STORAGE_BUCKET=your-project-id.firebasestorage.app
FIREBASE_WEB_MESSAGING_SENDER_ID=1234567890
FIREBASE_WEB_APP_ID=1:1234567890:web:abcdef123456
FIREBASE_WEB_MEASUREMENT_ID=
FIREBASE_WEB_VAPID_KEY=BN...

FIREBASE_IOS_API_KEY=AIza...
FIREBASE_IOS_PROJECT_ID=your-firebase-project-id
FIREBASE_IOS_STORAGE_BUCKET=your-project-id.firebasestorage.app
FIREBASE_IOS_MESSAGING_SENDER_ID=1234567890
FIREBASE_IOS_APP_ID=1:1234567890:ios:abcdef123456
FIREBASE_IOS_BUNDLE_ID=com.yourcompany.miane
FIREBASE_IOS_CLIENT_ID=
```

### 3.1 Backend Admin SDK

Các bước lấy file service account cho backend:

1. Vào Firebase Console: <https://console.firebase.google.com/>.
2. Chọn project Firebase.
3. Vào Project settings > Service accounts.
4. Chọn Generate new private key.
5. Lưu file JSON ngoài repo.
6. Điền đường dẫn file vào `FIREBASE_SERVICE_ACCOUNT_PATH` và `GOOGLE_APPLICATION_CREDENTIALS`.
7. Điền project id vào `FIREBASE_PROJECT_ID`.

Lưu ý khi chạy backend trong container: `FIREBASE_SERVICE_ACCOUNT_PATH` hoặc `GOOGLE_APPLICATION_CREDENTIALS` phải là đường dẫn mà container đọc được. Cách gọn nhất là mount file JSON vào container bằng compose override rồi trỏ biến tới đường dẫn trong container, ví dụ `/run/secrets/firebase-service-account.json`.

### 3.2 Web push để test trên Windows

Các bước lấy Web App config:

1. Trong Firebase Console, vào Project settings > General > Your apps.
2. Chọn Add app > Web.
3. Đặt tên app, đăng ký app, sau đó copy object `firebaseConfig`.
4. Điền các giá trị tương ứng vào `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_AUTH_DOMAIN`, `FIREBASE_WEB_PROJECT_ID`, `FIREBASE_WEB_STORAGE_BUCKET`, `FIREBASE_WEB_MESSAGING_SENDER_ID`, `FIREBASE_WEB_APP_ID`, `FIREBASE_WEB_MEASUREMENT_ID`.

Các bước lấy Web Push VAPID key:

1. Trong Firebase Console, vào Project settings > Cloud Messaging.
2. Ở Web configuration > Web Push certificates, chọn Generate key pair nếu chưa có.
3. Copy public key vào `FIREBASE_WEB_VAPID_KEY`.

Với Docker Compose, `docker-compose.yml` và `docker-compose.dev.yml` sẽ tự truyền các biến `FIREBASE_WEB_*` vào Flutter build/dev server và tự sinh `web/firebase-config.json` cho service worker.

Với Flutter chạy trực tiếp trên Windows, tạo `src\Clients\mobile\web\firebase-config.json` từ `src\Clients\mobile\web\firebase-config.example.json`, điền các giá trị web config tương ứng, rồi truyền cùng các giá trị qua `--dart-define`.

### 3.3 iOS push để demo trên MacBook

Các bước lấy iOS App config:

1. Trên MacBook, nếu chưa có thư mục iOS thì chạy `flutter create --platforms ios .` trong `src/Clients/mobile`.
2. Mở Xcode hoặc đọc bundle id trong `ios/Runner.xcodeproj`; bundle id này phải khớp Firebase và Apple Developer.
3. Trong Firebase Console, vào Project settings > General > Your apps.
4. Chọn Add app > Apple > iOS, nhập đúng bundle id.
5. Tải `GoogleService-Info.plist`.
6. Copy các giá trị từ file này vào `.env`:
   - `API_KEY` -> `FIREBASE_IOS_API_KEY`
   - `GOOGLE_APP_ID` -> `FIREBASE_IOS_APP_ID`
   - `GCM_SENDER_ID` -> `FIREBASE_IOS_MESSAGING_SENDER_ID`
   - `PROJECT_ID` -> `FIREBASE_IOS_PROJECT_ID`
   - `STORAGE_BUCKET` -> `FIREBASE_IOS_STORAGE_BUCKET`
   - `BUNDLE_ID` -> `FIREBASE_IOS_BUNDLE_ID`
   - `CLIENT_ID` -> `FIREBASE_IOS_CLIENT_ID` nếu có
7. Có thể đặt thêm `GoogleService-Info.plist` vào `ios/Runner/GoogleService-Info.plist` để Xcode/Firebase native đọc được khi cần, nhưng app hiện vẫn cần các biến `FIREBASE_IOS_*` qua `--dart-define`.

Các bước APNs bắt buộc cho iOS:

1. Cần tài khoản Apple Developer đang hoạt động.
2. Trong Apple Developer > Certificates, Identifiers & Profiles > Keys, tạo APNs Auth Key, bật Apple Push Notifications service, tải file `.p8` và lưu lại Key ID.
3. Ghi lại Apple Team ID.
4. Trong Firebase Console > Project settings > Cloud Messaging, phần iOS app configuration, upload APNs auth key `.p8`, nhập Key ID và Team ID.
5. Trong Xcode, mở `ios/Runner.xcworkspace`.
6. Chọn target Runner > Signing & Capabilities.
7. Thêm capability Push Notifications.
8. Thêm capability Background Modes, bật Background fetch và Remote notifications.
9. Chạy trên iPhone thật. iOS Simulator không nhận APNs push notification như thiết bị thật.

App hiện đợi APNs token trước khi lấy FCM token trên iOS, vì FCM iOS cần APNs token sẵn sàng trước khi gọi `getToken()`.

Nguồn chính thức:

- Firebase Admin setup: <https://firebase.google.com/docs/admin/setup>
- Firebase FCM Flutter setup: <https://firebase.google.com/docs/cloud-messaging/flutter/get-started>
- FlutterFire FCM/APNs iOS setup: <https://firebase.flutter.dev/docs/messaging/apple-integration/>
- Firebase Web Push certificates: <https://firebase.google.com/docs/cloud-messaging/js/client>

## 4. VietQR cho cấu hình ngân hàng và sinh mã QR

Bank list dùng endpoint công khai của VietQR nên không cần key. Tạo QR bằng `POST /v2/generate` cần `Client ID` và `API key`, vì vậy MIANE giữ key ở backend `Expense.API`, không đưa xuống Flutter app.

```dotenv
VIETQR_BASE_URL=https://api.vietqr.io/
VIETQR_CLIENT_ID=
VIETQR_API_KEY=
```

Cách lấy key:

1. Vào <https://my.vietqr.io/>.
2. Tạo hoặc đăng nhập tài khoản VietQR.
3. Lấy `Client ID` và `API Key`.
4. Điền vào `.env`, sau đó chạy lại `expense-api` hoặc toàn bộ Docker Compose.

Các endpoint MIANE đang dùng:

- `GET /expenses/vietqr/banks`: lấy danh sách ngân hàng/BIN từ VietQR, cache 24 giờ.
- `PUT /expenses/payment-methods/default-receive`: lưu tài khoản ngân hàng nhận tiền mặc định của người dùng.
- `POST /expenses/vietqr/generate`: sinh QR từ tài khoản đã cấu hình hoặc từ thông tin tài khoản gửi trực tiếp.

Lưu ý: VietQR giúp tạo mã QR chuyển khoản, chưa tự xác nhận giao dịch đã thanh toán. Muốn đối soát tự động cần thêm webhook/bank reconciliation từ Casso, payOS, ngân hàng, hoặc provider tương đương.

## 5. Chạy lại sau khi điền key

Với Docker Compose:

```powershell
docker compose --env-file .env up --build
```

Với Flutter web chạy trực tiếp trên Windows:

```powershell
cd src\Clients\mobile
flutter run `
  --dart-define=API_URL=http://localhost:8080 `
  --dart-define=MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail `
  --dart-define=FIREBASE_WEB_API_KEY=<FIREBASE_WEB_API_KEY> `
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=<FIREBASE_WEB_AUTH_DOMAIN> `
  --dart-define=FIREBASE_WEB_PROJECT_ID=<FIREBASE_WEB_PROJECT_ID> `
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=<FIREBASE_WEB_STORAGE_BUCKET> `
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=<FIREBASE_WEB_MESSAGING_SENDER_ID> `
  --dart-define=FIREBASE_WEB_APP_ID=<FIREBASE_WEB_APP_ID> `
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID=<FIREBASE_WEB_MEASUREMENT_ID> `
  --dart-define=FIREBASE_WEB_VAPID_KEY=<FIREBASE_WEB_VAPID_KEY>
```

Với Flutter iOS chạy trực tiếp trên MacBook:

```bash
cd src/Clients/mobile
flutter run -d <iphone-device-id> \
  --dart-define=API_URL=http://<LAN-IP-may-dev>:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://<LAN-IP-may-dev>:8000/api/v1/image/generate-trip-thumbnail \
  --dart-define=FIREBASE_IOS_API_KEY=<FIREBASE_IOS_API_KEY> \
  --dart-define=FIREBASE_IOS_PROJECT_ID=<FIREBASE_IOS_PROJECT_ID> \
  --dart-define=FIREBASE_IOS_STORAGE_BUCKET=<FIREBASE_IOS_STORAGE_BUCKET> \
  --dart-define=FIREBASE_IOS_MESSAGING_SENDER_ID=<FIREBASE_IOS_MESSAGING_SENDER_ID> \
  --dart-define=FIREBASE_IOS_APP_ID=<FIREBASE_IOS_APP_ID> \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=<FIREBASE_IOS_BUNDLE_ID> \
  --dart-define=FIREBASE_IOS_CLIENT_ID=<FIREBASE_IOS_CLIENT_ID>
```

Khi iPhone gọi backend đang chạy trên máy dev trong cùng mạng LAN, không dùng `localhost` cho `API_URL` hoặc `MIANE_AI_IMAGE_URL`; dùng IP LAN của máy đang chạy backend.

## 6. Kiểm tra tài khoản ngân hàng/ví

App hiện đã:

- Bắt chọn Ngân hàng/Ví nhận tiền từ danh sách cố định để tránh nhập sai tên.
- Bắt nhập Tên tài khoản.
- Kiểm tra định dạng số tài khoản ngân hàng hoặc số điện thoại ví.

Điều app chưa thể tự xác minh nếu chưa nối đối tác ngân hàng:

- Số tài khoản có tồn tại thật không.
- Số tài khoản có đúng tên chủ tài khoản không.

Muốn xác minh thật cần thêm API đối soát từ ngân hàng, NAPAS, VietQR Pro hoặc provider thanh toán được cấp quyền. Khi chọn provider cụ thể, mới nên thêm key riêng vào `.env.example`.
