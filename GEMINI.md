# Project: Coconut

Coconut is an AI-powered food scanning application that helps users get honest scores and nutritional information for their food in one scan.

## Repository Structure

- `android/`: Android application (Kotlin, Jetpack Compose).
- `backend/`: Go backend server (Fiber, PostgreSQL).
- `docs/`: Technical documentation and API contracts.
- `referense/`: UI/UX design references and JSX mockups.

## Architecture

We follow **Clean Architecture** principles across both the mobile and backend modules.

### Android
- **Pattern**: MVVM (Model-View-ViewModel) + Repository + Use Cases.
- **Tech Stack**:
  - **UI**: Jetpack Compose, Material 3, Navigation Compose.
  - **Scanning**: CameraX + ML Kit Barcode Scanning.
  - **Networking**: Retrofit + OkHttp (configured with custom CookieJar and User-Agent to bypass Bitrix redirects from Roskachestvo).
  - **Images**: Coil.
  - **Auth**: Google Sign-In via Android Credentials Manager.
  - **Persistence**: SharedPreferences (JSON storage via Gson).

### Backend
- **Pattern**: Ports and Adapters (Internal folder: `core/domain`, `core/ports`, `core/services`, `adapters/handlers`, `adapters/repositories`).
- **Tech Stack**:
  - **Language**: Go (1.23+).
  - **Web Framework**: Fiber (v2).
  - **Database**: PostgreSQL (pgx/v5).
  - **Auth**: JWT for sessions, Google ID Token verification for login.

## Building and Running

### CI/CD
Automated builds and testing are performed via **GitHub Actions**. All secrets, including `GOOGLE_CLIENT_ID` and other environment variables, are stored as GitHub Actions secrets and injected during the workflow.
- **Local Builds**: Local Android builds will not support Google Authentication unless the appropriate client IDs are manually configured in a local environment.
- **Database**: For development, the PostgreSQL database is accessible at:
  - **Host**: `62.233.43.33`
  - **User**: `postgres`
  - **Password**: `aramadmin`
  - **Port**: `5432`

### Android
- **Build**: `./gradlew assembleDebug`
- **Install**: `./gradlew installDebug`
- **Lint**: `./gradlew lint`
- **Test**: `./gradlew test`

### Backend
- **Dependencies**: `go mod download`
- **Run**: `DATABASE_URL=postgres://postgres:aramadmin@62.233.43.33:5432/postgres JWT_SECRET=your_secret go run cmd/api/main.go`
- **Test**: `go test ./...`
- **Build**: `go build -o api ./cmd/api`

## Development Conventions

- **Clean Architecture**: Strictly separate domain logic from implementation details (Retrofit, PGX, etc.).
- **DIP**: Use interfaces (ports) for repositories and services.
- **Formatting**:
  - Android: Kotlin coding conventions (use `ktlint` if available).
  - Backend: Standard `go fmt`.
- **Validation**:
  - Android: Every new feature must have a corresponding ViewModel test.
  - Backend: Every handler/service should be covered by unit tests.
