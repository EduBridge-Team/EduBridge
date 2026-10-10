# Flutter Web for iPhone (PWA)

This is the **Flutter application** at `edubridge-app/`, not the React website at `edubridge-web/`. Do not point the existing `edubridge.win` web deployment at these files.

## Build and test

```bash
cd edubridge-app
flutter pub get
flutter analyze
flutter build web --release --base-href /
```

The output is `edubridge-app/build/web`. GitHub Actions workflow **Flutter Web PWA** uploads this build as an artifact when successful. The workflow does not deploy or replace the existing website.

## Proposed hosting

Host the Flutter bundle at a dedicated HTTPS origin such as `https://app.edubridge.win` with SPA fallback to `index.html`. Serve the files with correct MIME types, and keep the existing React site unchanged. Ensure that `https://api.edubridge.win` explicitly permits the application origin via Laravel CORS configuration (including authorization headers). Never use wildcard CORS combined with credentials.

## iPhone installation

1. Open the dedicated HTTPS application URL in Safari.
2. Use Share > Add to Home Screen.
3. Open the EduBridge icon from the home screen.

The PWA manifest and Apple web-app metadata are included. iOS support must be validated on a physical device.

## Browser-specific acceptance checklist

- Login, logout, token persistence and account recovery
- Google Sign-In on web: Google's browser flow differs from mobile; do not assume the mobile authenticate() path works
- TTS / microphone permissions, child voice interaction, video and audio playback after user gesture
- Camera, file picker, uploads, and PDF downloads
- App lifecycle after Safari suspension and returning from background
- Portrait and landscape, RTL, VoiceOver and dynamic text size
- Notifications while the app is open versus browser push (not equivalent to Android)
- Cache update behavior and first load on slow connections

Keep sensitive student information out of browser caches. Neither a successful compilation nor iPhone home-screen installation confirms feature parity. Do not deploy until the browser-specific checklist is completed.
