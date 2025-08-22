# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Smart Yoram App is a Flutter-based church management application with cross-platform support (Android/iOS). The app integrates with Supabase backend services and Firebase for push notifications, providing comprehensive church administration features including member management, attendance tracking, bulletin distribution, and pastoral care.

## Development Commands

### Flutter Commands
```bash
# Install dependencies
flutter pub get

# Generate code (for Riverpod providers and build_runner)
flutter packages pub run build_runner build

# Generate code with conflict resolution
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run the app in debug mode
flutter run

# Run with device selection
flutter run -d <device_id>

# Clean build files
flutter clean && flutter pub get

# Build for release
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

### Testing
```bash
# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Code Generation
The project uses `build_runner` for code generation. Run this command whenever you modify Riverpod providers or other generated code:
```bash
dart run build_runner build
```

## Architecture Overview

### Core Structure
- **State Management**: Flutter Riverpod with providers for reactive state management
- **Backend**: Supabase integration for database, authentication, and real-time features
- **Push Notifications**: Firebase Cloud Messaging (FCM) integration
- **Navigation**: Bottom navigation with main sections (Home, Members, Bulletin, Notices, Settings)
- **Styling**: Custom design system with Pretendard font family and consistent color schemes

### Key Directories

#### `/lib/`
- **`main.dart`**: App entry point with Firebase/Supabase initialization and navigation setup
- **`config/`**: Configuration files for APIs and services
  - `naver_map_config.dart`: Naver Maps integration
  - `fcm_config.dart`: Firebase Cloud Messaging settings
  - `api_config.dart`: API endpoints and configurations
- **`models/`**: Data models with barrel export in `models.dart`
- **`services/`**: Business logic and API integration with barrel export in `services.dart`
- **`screens/`**: UI screens with `main_navigation.dart` as the root navigation controller
- **`components/`**: Reusable UI components library
- **`widgets/`**: Custom widgets specific to app functionality
- **`resource/`**: Design system (colors, typography, themes)
- **`utils/`**: Utility functions and helpers

#### `/docs/`
- Privacy policy guidelines and push notification implementation docs
- Feature specifications and API documentation

### Key Features
1. **Church Member Management**: Directory, profiles, family relationships
2. **Attendance Tracking**: QR code-based check-in system
3. **Bulletin System**: Digital bulletin distribution and viewing
4. **Notice Management**: Church announcements and notifications
5. **Calendar Integration**: Event scheduling and management
6. **Prayer Requests**: Community prayer management
7. **Push Notifications**: FCM-based messaging system
8. **Pastoral Care**: Request and tracking system with location services

## Important Dependencies

### Core Framework
- `flutter`: UI framework
- `flutter_riverpod`: State management
- `supabase_flutter`: Backend services

### UI & Design
- `flutter_screenutil`: Responsive design
- `google_fonts` & Custom Pretendard fonts: Typography
- `flutter_svg`: Vector graphics
- `lottie`: Animations

### Firebase & Notifications
- `firebase_core`: Firebase initialization
- `firebase_messaging`: Push notifications
- `flutter_local_notifications`: Local notifications

### Device & Permissions
- `mobile_scanner`: QR code scanning
- `permission_handler`: Runtime permissions
- `image_picker`: Camera and gallery access
- `flutter_naver_map`: Naver Maps integration

### Data & Storage
- `flutter_secure_storage`: Secure local storage
- `shared_preferences`: App preferences
- `excel`: Excel file processing
- `sqflite`: Local database (if needed)

## Configuration Notes

### Firebase Setup
- Firebase is initialized with error handling in `main.dart`
- FCM tokens are managed through `FCMService`
- Google Services configuration files are included for both platforms

### Supabase Integration
- Currently configured with dummy credentials for development
- Real Supabase configuration should be added to production builds
- Authentication flows are handled through `AuthService`

### Build Configuration
- Android: Uses release signing configuration from `key.properties`
- iOS: Standard iOS app configuration with CocoaPods dependencies
- Both platforms support Firebase and native integrations

## Development Guidelines

### State Management Patterns
- Use Riverpod providers for global state
- Service classes handle business logic and API calls
- Models are immutable data classes

### Navigation
- Bottom navigation for main sections
- Standard Flutter navigation for sub-screens
- Route definitions in `main.dart`

### Error Handling
- Services include comprehensive error handling
- Firebase and Supabase failures are gracefully handled
- User-friendly error messages throughout the app

### Code Generation
- Run `dart run build_runner build` after modifying providers
- Use `--delete-conflicting-outputs` flag if conflicts occur

## Testing Strategy
- Widget tests for UI components
- Unit tests for services and business logic
- Integration tests for critical user flows

## Build Process
1. Ensure all dependencies are installed (`flutter pub get`)
2. Generate code if needed (`dart run build_runner build`)
3. Run tests (`flutter test`)
4. Build for target platform (`flutter build apk/ios`)