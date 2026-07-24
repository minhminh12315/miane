# MIANE Flutter client

Flutter client của MIANE, hiện có platform folders cho iOS và Web.

## Chạy trên iOS Simulator

Backend cần chạy ở gateway `http://localhost:8080`:

```bash
cd src/Clients/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs

flutter run \
  --dart-define=API_URL=http://localhost:8080 \
  --dart-define=MIANE_AI_IMAGE_URL=http://localhost:8000/api/v1/image/generate-trip-thumbnail
```

`flutter run` không tự đọc `.env` ở root. Với iPhone thật, thay `localhost`
bằng LAN IP của máy đang chạy Docker/backend.

## Generate code và kiểm tra

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build ios --simulator --no-codesign
```

## Lưu ý hiện tại

- OCR hóa đơn/biên lai dùng Apple Vision trong
  `ios/Runner/AppDelegate.swift`, nên chỉ hỗ trợ iOS/iOS Simulator.
- `API_URL` và `MIANE_AI_IMAGE_URL` là compile-time `--dart-define`.
- Google Sign-In native đọc cấu hình trong `ios/Runner/Info.plist`.
- Apple Sign-In chưa được tích hợp; thông báo hiện chỉ hiển thị trong app.

Xem hướng dẫn đầy đủ tại [README gốc](../../../README.md) và
[`ENV_KEYS_GUIDE.md`](../../../ENV_KEYS_GUIDE.md).
