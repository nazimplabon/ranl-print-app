# RANL PRINT Flutter App

Starter Flutter application for Android and iOS, designed to connect to the existing Django website at `https://ranlprint.com`.

## Included
- Premium modern home screen
- Services loaded from `GET /api/catalog/products/`
- Quote request form connected to `POST /api/quotes/create/`
- Contact form connected to `POST /api/contact/`
- No public price display
- Cookie/CSRF preparation for Django POST requests

## Requirements
- Flutter SDK (stable channel)
- Android Studio for Android builds
- Xcode on macOS for iOS builds

## Create platform folders
This ZIP contains the app source and configuration. From this folder, run:

```bash
flutter create --platforms=android,ios .
flutter pub get
flutter analyze
flutter run
```

If `flutter create` asks to overwrite `lib/main.dart`, choose **No** / keep the existing source file.

## Build
Android APK:
```bash
flutter build apk --release
```

iOS:
```bash
flutter build ios --release
```
iOS builds require macOS and Xcode. Publishing requires your own Google Play Console and Apple Developer accounts.

## Backend API assumptions
The Django site should expose:
- `GET https://ranlprint.com/api/catalog/products/`
- `GET https://ranlprint.com/api/csrf/`
- `POST https://ranlprint.com/api/quotes/create/`
- `POST https://ranlprint.com/api/contact/`

The app does not calculate or display prices. Quote requests should appear in the existing Django Admin.

## Important testing note
This is an initial source build, not a signed release APK or an App Store submission. Before production, run it against the live server, verify CSRF cookie handling on Android/iOS, validate quote submission in Django Admin, and add artwork attachment upload if required.


## Optional cloud build with GitHub Actions
The repository includes `.github/workflows/build-mobile.yml`. After uploading this source to a GitHub repository, open **Actions → Build RANL PRINT Mobile App → Run workflow**. The workflow attempts to produce an Android APK and an unsigned iOS app bundle as downloadable artifacts.

Important:
- This workflow is a build helper, not a guarantee that the project will compile without fixes.
- The app's Django endpoints and CSRF behaviour must be verified against the live server.
- The iOS artifact is unsigned. Installing on a real iPhone or publishing to the App Store requires Apple signing credentials and provisioning, typically configured through Xcode / Apple Developer account.
"# ranl-print-app" 
