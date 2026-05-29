# Android Module: Coconut

## Tech Stack
- **UI**: Jetpack Compose
- **Navigation**: Compose Navigation
- **Networking**: Retrofit + OkHttp (Customized with Browser User-Agent and CookieJar to bypass Bitrix redirects).
- **Images**: Coil (sharing the same custom OkHttpClient).
- **Scanning**: CameraX + ML Kit Barcode Scanning.
- **Architecture**: MVVM + Repository + Use Cases.

## Data Flow
1. `CameraView` scans barcode -> `onAnalyze` callback.
2. `CoconutViewModel.searchBarcode(barcode)` is called.
3. `SearchBarcodeUseCase` invokes `ProductRepository`.
4. `ProductRepositoryImpl` fetches from `RoskachestvoApi`.
5. Data is mapped from `ProductDetailDto` to `Product` domain model.
6. Local cache (`SharedPreferences`) is updated.
7. UI observes `productState` and navigates to `DetailScreen`.

## Local Persistence
History and Streak are stored as JSON in `SharedPreferences` (`coconut_prefs`).
