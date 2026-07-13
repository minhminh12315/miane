# Google Sign-In Setup (iOS)

The app crashed on "Tiếp tục với Google" with **SIGABRT** because `GIDSignIn`
was invoked with no client id configured. It throws an `NSException`
("You must specify |clientID|…"), and the `google_sign_in` plugin re-raises
it (`[e raise]`), which a Dart `try/catch` cannot intercept — so the whole app
aborts.

**Status: wired up with a real iOS OAuth client (no separate Web client).**
Bundle id `com.example.mobile` →
`135347207127-oido4n87prcqp44lvjtiovfqafr5qkbe.apps.googleusercontent.com`,
set in `ios/Runner/Info.plist` (`GIDClientID` + reversed `CFBundleURLSchemes`)
and mirrored in `src/Services/Identity/Identity.API/appsettings.json`
(`Google:ClientId`) so the backend validates the idToken against the same
audience. No `GIDServerClientID` is set, so the idToken's audience is the iOS
client id itself — that's why both sides must use the identical id.

If you ever rotate this client id or add a separate **Web** OAuth client
(recommended if multiple platforms/backends should share one audience),
update both places again:

1. Google Cloud Console → <https://console.cloud.google.com/apis/credentials> →
   create the new client (iOS bundle id `com.example.mobile`, or Web type).
2. `ios/Runner/Info.plist`: `GIDClientID` (iOS client id), reversed id in
   `CFBundleURLSchemes[0]` (`com.googleusercontent.apps.<id-before-.apps...>`),
   and optionally `GIDServerClientID` (Web client id, if using one).
3. `src/Services/Identity/Identity.API/appsettings.json` → `Google:ClientId`:
   the **Web** client id if `GIDServerClientID` is set, otherwise the **iOS**
   client id — this must match whichever one the idToken's audience actually is.

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
