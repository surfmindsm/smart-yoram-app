# Smart Yoram App

A Flutter application integrated with Supabase for cross-platform support (Android/iOS).

## Features

- 📱 Cross-platform support (Android & iOS)
- 🔒 Supabase backend integration
- 🎨 Modern Material Design 3 UI
- 💾 Real-time data synchronization

## Setup

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode for device testing
- Git for version control

### Installation

1. Clone the repository:
```bash
git clone https://github.com/surfmindsm/smart-yoram-app.git
cd smart_yoram_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Configuration

### Supabase Setup
The app is pre-configured with Supabase integration. Configuration can be found in:
- `lib/config/supabase_config.dart`

### Build & Deploy

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── config/
│   └── supabase_config.dart    # Supabase configuration
├── main.dart                    # App entry point
└── ...
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.
