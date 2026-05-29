# Project: Coconut

## Overview
Coconut is an AI-powered food scanning application that helps users get honest scores and nutritional information for their food in one scan.

## Repository Structure
- `android/`: The Android application (Kotlin, Jetpack Compose).
- `backend/`: Future backend server.
- `docs/`: Technical documentation and API contracts.

## Architecture
We follow **Clean Architecture** principles to ensure the frontend can easily switch from third-party APIs (like Roskachestvo) to our internal backend later.

## Technology Stack
- **Android**: Kotlin, Jetpack Compose, MVVM, Retrofit, Coil, CameraX, ML Kit.
- **Backend**: (TBD)
- **Local Storage**: SharedPreferences with Gson serialization.
