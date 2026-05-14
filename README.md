# YOU(th) Mobile App

The official Flutter client for the YOU(th) health tracking application. This mobile app allows users to log in, securely connect their cloud-based wearables (like the Oura Ring or Fitbit) via the Junction Link widget, and instantly sync their health metrics directly from their devices into the backend.

## Architecture & Stack
- **Framework:** Flutter & Dart
- **State Management:** Provider
- **Integrations:** `webview_flutter` for the Junction Link OAuth flow, `shared_preferences` for session persistence.

## Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure `flutter doctor` passes)
- An active iOS Simulator or Android Emulator
- The **YOU(th) Backend** must be running locally on port 8080.

## Running Locally

1. Ensure the Rust backend is running first. (The app automatically detects if you are on an Android Emulator and connects to `http://10.0.2.2:8080`, otherwise it defaults to `http://127.0.0.1:8080` for iOS Simulators).
2. Fetch the Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Key Features
- **Authentication**: Seamless login interacting with the backend user database.
- **Wearable Connectivity**: An in-app WebView launches the Junction Sandbox connection flow to authorize access to wearables.
- **Data Sync**: Direct synchronization of sleep/activity summaries from the Junction network down to the local Postgres database.
