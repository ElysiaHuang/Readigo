# Google sign-in setup

Google sign-in must be configured in the Firebase project **readigo** for every
Android signing certificate that runs Bookfania.

## Resolved deleted-client failure (October 3, 2026)

Google's OAuth endpoint returned `Error 401: deleted_client` and
`The OAuth client was deleted.` for the web client configured in
`lib/util/google_services.dart`:

```
550818826311-9okroqsll4hhrma17qsfplkcc2er76ek.apps.googleusercontent.com
```

Google Cloud's deleted-credentials list showed this Web client was deleted on
September 26, 2026. With user approval, it was restored on October 3, 2026.
The console confirmed restoration and Google's OAuth endpoint subsequently
opened its normal sign-in page instead of the deleted-client error. The
existing ID remains valid, so the app and Firebase need no client-ID change.
Successful account sign-in inside the app still needs a user check.

The installed Android APK's SHA-1 matches the Android client in the current
`google-services.json`. Reinstalling the same build cannot repair a deleted
web client. If this error recurs, restore the web client in Google Auth Platform → Clients →
Restore deleted credentials, if it is still recoverable. Otherwise create a
Web application OAuth client in **readigo**, configure that client in Firebase
Authentication → Sign-in method → Google → Web SDK configuration, and use its
client ID as `serverClientId` in the app. Never put its client secret in Flutter
source. Download the updated Android Firebase configuration and rebuild only
if the client ID or configuration changed.

This web client identifies the audience of the Google ID token used by Firebase
Authentication. It does not require Cloud Functions.

## Android development build

In Firebase Console, open **readigo** → Project settings → Your apps → Android
app `com.elysiahuang.readigo` and add this SHA-1 fingerprint:

```
E6:C4:F3:66:42:86:AC:BD:01:68:B7:CD:62:F6:E6:63:29:8A:E1:4A
```

Then enable **Google** under Authentication → Sign-in method, download the
updated `google-services.json`, and replace
`android/app/google-services.json`. Rebuild and reinstall the app.

For a release build, add the SHA-1 from the release keystore as well. Do not
reuse the debug fingerprint for a published app.

## iOS

The checked-in `ios/Runner/GoogleService-Info.plist` currently belongs to a
different Firebase project. Download the iOS configuration for **readigo** and
replace that file before shipping iOS. The iOS OAuth client in
`lib/firebase_options.dart` and `ios/Runner/Info.plist` must remain associated
with the `com.elysiahuang.testapp3` bundle ID.
