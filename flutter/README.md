# Coconut Flutter Migration

This folder is the Flutter rewrite of the existing Android app.

## Migrated behavior

- Google sign-in flow that exchanges an ID token with the Coconut backend.
- Secure token storage and cached profile data.
- Current user loading, nickname update, logout, and account deletion.
- Barcode scanning with camera plus manual barcode input.
- Product lookup through `https://foodmayak.ru/api/products/{barcode}`.
- Personal scan history sync, save, clear, delete locally, daily average, and streak.
- Home, scan, product detail, replacement, and profile screens.

## Build notes

Flutter SDK was not installed in this workspace, so generated platform files were kept minimal.
After installing Flutter, run these commands from this folder:

```powershell
flutter create --platforms android,ios .
flutter pub get
flutter run
```

The Dart source in `lib/` is the migrated application code.
