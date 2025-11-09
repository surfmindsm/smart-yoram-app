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
flutter build apk --release         # Android APK
flutter build appbundle --release   # Android App Bundle (권장 - Google Play)
flutter build ios --release         # iOS
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
  - Services follow a consistent pattern: fetch data from Supabase, transform to models, cache where appropriate
  - **IMPORTANT**: Always use batch queries (`.inFilter()`) instead of individual queries to avoid N+1 problems
- **`screens/`**: UI screens with `main_navigation.dart` as the root navigation controller
  - `community/`: Community features (sharing, requests, job postings, music teams, news)
    - `community_list_screen.dart`: Generic list screen for all community types with filtering
    - `community_detail_screen.dart`: Generic detail view supporting multiple content types
    - `community_create_screen.dart`: Unified creation form handling all community post types
- **`components/`**: Reusable UI components library
- **`widgets/`**: Custom widgets specific to app functionality
- **`resource/`**: Design system (colors, typography, themes)
  - `color_style_new.dart`: NewAppColor palette
  - `text_style_new.dart`: FigmaTextStyles for typography
- **`utils/`**: Utility functions and helpers
  - `location_data.dart`: Korean administrative divisions (cities, districts)

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
9. **Community Features**:
   - Free Sharing / Item Sales (unified with `is_free` flag)
   - Item Requests
   - Job Postings (사역자 모집)
   - Music Team Recruitment (행사팀 모집)
   - Music Team Seeking (행사팀 지원)
   - Church News (행사 소식)

## Important Dependencies

### Core Framework
- `flutter`: UI framework (Dart 3.6.0, Flutter 3.27.1)
- `flutter_riverpod` (3.0.0-dev.3): State management
- `supabase_flutter` (2.9.1): Backend services

### UI & Design
- `flutter_screenutil` (5.9.0): Responsive design (기준: 390x844)
- `google_fonts` (6.1.0) & Custom Pretendard fonts: Typography
- `flutter_svg` (2.0.7): Vector graphics
- `lottie` (3.1.0): Animations
- `fl_chart` (0.66.2): Charts and graphs

### Firebase & Notifications
- `firebase_core` (2.24.2): Firebase initialization
- `firebase_messaging` (14.7.10): Push notifications
- `flutter_local_notifications` (17.2.2): Local notifications

### Device & Permissions
- `mobile_scanner` (5.0.0): QR code scanning
- `qr_flutter` (4.1.0): QR code generation
- `permission_handler` (11.3.1): Runtime permissions
- `image_picker` (1.0.4): Camera and gallery access
- `flutter_naver_map` (1.4.1+1): Naver Maps integration
- `saver_gallery` (4.0.1): Save images to gallery

### Data & Storage
- `flutter_secure_storage` (9.0.0): Secure local storage
- `shared_preferences` (2.2.2): App preferences
- `excel` (4.0.6): Excel file processing
- `file_picker` (8.0.0): File selection
- `cached_network_image` (3.3.1): Image caching
- `photo_view` (0.15.0): Image viewer
- `syncfusion_flutter_pdfviewer` (26.2.14): PDF viewer

### Network & HTTP
- `http` (1.1.0): HTTP client
- `connectivity_plus` (5.0.1): Network connectivity
- `url_launcher` (6.2.2): URL launching
- `share_plus` (10.1.1): Sharing functionality

### Code Generation (dev dependencies)
- `build_runner` (2.4.6): Code generation runner
- `riverpod_generator` (3.0.0-dev.11): Riverpod code generation
- `flutter_launcher_icons` (0.13.1): App icon generation
- `flutter_native_splash` (2.3.9): Splash screen generation
- `mockito` (5.4.2): Testing mocks

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
- Android:
  - Uses release signing configuration from `key.properties`
  - compileSdk: 36, minSdk: 23
  - Gradle Plugin: 8.1.1 (자동으로 16KB 페이지 크기 지원)
  - NDK ABI filters: arm64-v8a, armeabi-v7a, x86_64
- iOS: Standard iOS app configuration with CocoaPods dependencies
- Both platforms support Firebase and native integrations
- **중요**: Google Play는 2025년 11월 1일부터 16KB 메모리 페이지 크기 지원 필수 (현재 구성 충족)

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

### UI Consistency
- All form inputs should use the `_buildInputDecoration` helper method pattern
- Standard decoration: borderless with filled background (`NewAppColor.neutral100`)
- Example pattern in `community_create_screen.dart`:
  ```dart
  InputDecoration _buildInputDecoration({
    required String hintText,
    String? counterText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: FigmaTextStyles().body2.copyWith(
        color: NewAppColor.neutral400,
      ),
      counterText: counterText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: NewAppColor.neutral100,
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
    );
  }
  ```

### Performance Optimization
- **Avoid N+1 queries**: Use `.inFilter()` for batch fetching related data (authors, churches, etc.)
- **Cache filtered results**: Use cached variables instead of computed getters in StatefulWidget build methods
- **Update filters explicitly**: Call update methods only when filter values change, not on every build
- Example pattern from `community_list_screen.dart`:
  ```dart
  // Bad: Computed getter called multiple times per build
  List<dynamic> get _filteredItems { /* filtering logic */ }

  // Good: Cached variable updated only when filters change
  List<dynamic> _filteredItemsCache = [];
  void _updateFilteredItems() {
    _filteredItemsCache = /* filtering logic */;
  }
  ```

### Community Screen Architecture
- `CommunityListScreen` is a generic list screen supporting multiple content types via `CommunityListType` enum
- Filtering is unified across types: location, category, status, price (for sharing/sales), delivery availability
- `CommunityDetailScreen` handles display logic polymorphically based on item type
- `CommunityCreateScreen` contains all creation forms in a single file, switching via category selection

## Testing Strategy
- Widget tests for UI components
- Unit tests for services and business logic
- Integration tests for critical user flows

## Build Process
1. Ensure all dependencies are installed (`flutter pub get`)
2. Generate code if needed (`dart run build_runner build`)
3. Run tests (`flutter test`)
4. Build for target platform:
   - Android: `flutter build appbundle --release` (Google Play 권장)
   - iOS: `flutter build ios --release`

## API Endpoints

### REST API (api.surfmind-team.com/api/v1)
주요 엔드포인트는 `lib/config/api_config.dart`에 정의되어 있습니다:
- 인증: `/auth/member/login`, `/auth/member/change-password`
- 교인: `/members/`, `/members/{id}/upload-photo`
- 심방: `/pastoral-care/requests`
- 기도: `/prayer-requests/`
- 공지: `/announcements/`, `/announcements/categories`
- 통계: `/statistics/`, `/statistics/attendance/summary`
- SMS: `/sms/send`, `/sms/send-bulk`
- QR코드: `/qr-codes/`, `/qr-codes/generate/{member_id}`
- 주보: `/bulletins/`
- 출석: `/attendances/`

### Supabase Edge Functions
커뮤니티 관련 기능은 Supabase Edge Functions를 사용합니다:
- `/community-sharing`: 무료 나눔/물품 판매
- `/community-requests`: 물품 요청
- `/music-team-recruit`: 행사팀 모집
- `/music-seekers`: 행사팀 지원
- `/worship-services`: 예배 서비스
- 기타 통계 및 심방 요청 기능

자세한 API 명세는 `docs/CURRENT_SUPABASE_API_REFERENCE.md`를 참조하세요.

## Icon & Splash Configuration

### App Icon
앱 아이콘은 `assets/icons/logo.png` (또는 `assets/images/app_icon.png`)에서 관리됩니다.

아이콘 변경 시:
```bash
# 1. 새 아이콘 파일을 assets/images/app_icon.png에 저장
# 2. flutter_launcher_icons 실행
dart run flutter_launcher_icons

# 3. iOS용 알파 채널 제거가 필요한 경우
# pubspec.yaml에 remove_alpha_ios: true 추가
```

**중요**: Google Play 스토어 등록 아이콘과 앱 내 아이콘이 일치해야 합니다 (혼동을 야기하는 주장 정책).

## Version & Release Management

현재 버전: 1.0.1+26 (pubspec.yaml)
- 버전 형식: `major.minor.patch+buildNumber`
- 브랜치 전략: `release/x.x.x` 브랜치에서 릴리스 빌드
- Git 브랜치: `main` (메인), `release/1.0.1` (현재 릴리스)

## Documentation

프로젝트 문서는 `/docs/` 디렉토리에 있습니다:
- `community-spec.md`: 커뮤니티 기능 상세 명세
- `CURRENT_SUPABASE_API_REFERENCE.md`: Supabase API 참조
- `mobile-signup-specification.md`: 회원가입 플로우
- `PRD_CHURCH_ADMIN_DASHBOARD.md`: 관리자 기능 기획
- `chat-implementation-plan.md`: 채팅 구현 계획

추가 문서:
- `GOOGLE_PLAY_CONSOLE_SETUP.md`: Google Play 배포 설정
- `test_account_setup_guide.md`: 테스트 계정 설정
