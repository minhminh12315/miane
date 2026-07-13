# Google Sign-In Setup (iOS)

The app crashed on "Tiếp tục với Google" with **SIGABRT** because `GIDSignIn`
was invoked with no client id configured. It throws an `NSException`
("You must specify |clientID|…"), and the `google_sign_in` plugin re-raises
it (`[e raise]`), which a Dart `try/catch` cannot intercept — so the whole app
aborts.

The scaffolding is now in place with **placeholders**. Follow the steps below
to make real Google login work. Until you do, the app falls back to the
backend's mock Google tester (`mock_google_token`) so the dev flow stays usable.

---

## 1. Create an iOS OAuth client

1. Go to <https://console.cloud.google.com/apis/credentials> (select or create a
   project).
2. **Create Credentials → OAuth client ID → iOS**.
3. Bundle ID: `com.example.mobile` (current value in
   `ios/Runner.xcodeproj`; change both if you rename the bundle).
4. Copy the generated **iOS client ID**: `NNNNNN-xxxx.apps.googleusercontent.com`.

If the backend should validate against a **Web** client (recommended for a
shared audience), also create an **OAuth client ID → Web application** and copy
that id too.

---

## 2. Wire the iOS app

Edit `src/Clients/mobile/ios/Runner/Info.plist` and replace the placeholders:

| Key | Replace with |
|-----|--------------|
| `GIDClientID` | your **iOS** client id (`…apps.googleusercontent.com`) |
| `GIDServerClientID` | your **Web** client id (or delete this key if unused) |
| `CFBundleURLSchemes[0]` | the **reversed** iOS client id: `com.googleusercontent.apps.NNNNNN-xxxx` |

> The reversed client id = take the iOS client id, drop the
> `.apps.googleusercontent.com` suffix, and prefix with
> `com.googleusercontent.apps.`.

(Alternatively, drop a `GoogleService-Info.plist` from Firebase into
`ios/Runner/` and add it to the Xcode target — it carries `CLIENT_ID` and the
plugin reads it automatically. The Info.plist keys above are the no-Firebase
path.)

---

## 3. Wire the backend

Set the audience the backend validates the idToken against in
`src/Services/Identity/Identity.API/appsettings.json` (or via env
`Google__ClientId`):

```jsonc
"Google": {
  // If the Dart side sets GIDServerClientID -> use the WEB client id here.
  // If not -> use the iOS client id (that's the idToken audience).
  "ClientId": "NNNNNN-xxxx.apps.googleusercontent.com",
  "BypassValidation": false
}
```

`AuthService.LoginGoogleAsync` validates the token with
`GoogleJsonWebSignature.ValidateAsync` and this `Audience`.

---

## 4. Remove the dev fallback (optional)

Once real login works, delete the `catch` mock fallback in
`_signInWithGoogle` (`lib/features/auth/presentation/screens/auth_gate_screen.dart`)
and the `mock_google_token` branch in `AuthService.LoginGoogleAsync` if you no
longer want the mock tester path.

---

## Verify

- `flutter run` on a real device / simulator.
- Tap "Tiếp tục với Google" → the Google account sheet appears (no SIGABRT).
- Pick an account → app receives a real idToken → backend validates → logged in.
