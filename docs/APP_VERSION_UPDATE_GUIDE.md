# 앱 버전 업데이트 시스템 가이드

## 개요

이 문서는 Smart Yoram App의 강제 업데이트 및 소프트 업데이트 시스템 구현 가이드입니다.

## 구조

### 1. 데이터베이스 (Supabase)

**테이블: `app_versions`**

```sql
CREATE TABLE app_versions (
  id BIGSERIAL PRIMARY KEY,
  platform VARCHAR(20) NOT NULL, -- 'ios' 또는 'android'
  min_version VARCHAR(20) NOT NULL, -- 최소 지원 버전
  latest_version VARCHAR(20) NOT NULL, -- 최신 버전
  store_url TEXT NOT NULL, -- 스토어 URL
  update_message TEXT, -- 선택적 업데이트 메시지
  force_update_message TEXT, -- 강제 업데이트 메시지
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 2. 버전 체크 흐름

```
앱 시작
  ↓
AuthWrapper 초기화
  ↓
로그인 상태 확인
  ↓
버전 체크 (AppVersionService.checkVersion())
  ↓
┌─────────────────────────────────┐
│ 현재 버전 vs 최소 버전 비교      │
└─────────────────────────────────┘
  │
  ├─ 현재 < 최소 → 강제 업데이트 팝업 (닫기 불가)
  │
  ├─ 현재 < 최신 → 소프트 업데이트 팝업 (나중에 가능)
  │
  └─ 현재 >= 최신 → 업데이트 불필요
```

### 3. 주요 컴포넌트

#### AppVersionService (`lib/services/app_version_service.dart`)
- 버전 정보 조회
- 버전 비교 로직
- Semantic Versioning 지원 (예: 1.0.0, 1.2.3)

#### UpdateDialog (`lib/widgets/update_dialog.dart`)
- 강제 업데이트 다이얼로그
- 소프트 업데이트 다이얼로그
- 스토어 연결 기능

#### AuthWrapper (`lib/main.dart`)
- 앱 시작 시 버전 체크 실행

## 설정 방법

### 1. Supabase 테이블 생성

```bash
# Supabase SQL Editor에서 실행
psql -h your-project.supabase.co -U postgres -d postgres -f docs/app_version_schema.sql
```

또는 Supabase Dashboard → SQL Editor에서 `docs/app_version_schema.sql` 내용을 복사하여 실행

### 2. 스토어 URL 설정

#### Android (Google Play)
```
https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME
```

예: `https://play.google.com/store/apps/details?id=com.smartyoram.app`

#### iOS (App Store)
```
https://apps.apple.com/app/idYOUR_APP_ID
```

예: `https://apps.apple.com/app/id1234567890`

**App ID 확인 방법:**
1. App Store Connect 로그인
2. 내 앱 선택
3. 앱 정보 → 일반 정보 → Apple ID 확인

### 3. 버전 정보 업데이트

Supabase Dashboard → Table Editor → app_versions에서 직접 수정하거나, SQL로 업데이트:

```sql
-- Android 버전 업데이트
UPDATE app_versions
SET
  min_version = '1.0.0',  -- 최소 지원 버전
  latest_version = '1.0.6', -- 최신 버전
  store_url = 'https://play.google.com/store/apps/details?id=com.smartyoram.app',
  update_message = '새로운 기능이 추가되었습니다. 지금 업데이트하세요!',
  force_update_message = '보안 업데이트가 있습니다. 앱을 계속 사용하려면 업데이트해주세요.',
  updated_at = NOW()
WHERE platform = 'android' AND is_active = true;

-- iOS 버전 업데이트
UPDATE app_versions
SET
  min_version = '1.0.0',
  latest_version = '1.0.6',
  store_url = 'https://apps.apple.com/app/id1234567890',
  update_message = '새로운 기능이 추가되었습니다. 지금 업데이트하세요!',
  force_update_message = '보안 업데이트가 있습니다. 앱을 계속 사용하려면 업데이트해주세요.',
  updated_at = NOW()
WHERE platform = 'ios' AND is_active = true;
```

## 사용 시나리오

### 시나리오 1: 소프트 업데이트 (권장 업데이트)

**상황:**
- 현재 앱 버전: 1.0.3
- 최소 버전: 1.0.0
- 최신 버전: 1.0.6

**결과:**
- 소프트 업데이트 팝업 표시
- "나중에" 버튼으로 건너뛰기 가능
- "업데이트" 버튼으로 스토어 이동

### 시나리오 2: 강제 업데이트 (필수 업데이트)

**상황:**
- 현재 앱 버전: 0.9.5
- 최소 버전: 1.0.0
- 최신 버전: 1.0.6

**결과:**
- 강제 업데이트 팝업 표시
- 닫기 불가 (뒤로가기 막힘)
- 배경 터치로 닫기 불가
- "업데이트" 버튼만 활성화
- 업데이트 전까지 앱 사용 불가

### 시나리오 3: 업데이트 불필요

**상황:**
- 현재 앱 버전: 1.0.6
- 최소 버전: 1.0.0
- 최신 버전: 1.0.6

**결과:**
- 팝업 표시 안 함
- 정상 앱 사용

## 버전 관리 전략

### Semantic Versioning 사용

버전 형식: `MAJOR.MINOR.PATCH` (예: 1.2.3)

- **MAJOR**: 주요 변경사항 (하위 호환성 없음)
- **MINOR**: 새로운 기능 추가 (하위 호환성 유지)
- **PATCH**: 버그 수정

### 최소 버전 설정 기준

다음과 같은 경우 최소 버전을 올려야 합니다:

1. **보안 취약점 수정**: 심각한 보안 문제가 발견된 경우
2. **API 변경**: 백엔드 API가 변경되어 이전 버전과 호환되지 않는 경우
3. **필수 기능 추가**: 앱의 핵심 기능이 추가되어 이전 버전으로는 사용이 어려운 경우
4. **데이터베이스 스키마 변경**: Supabase 테이블 구조가 변경되어 이전 버전과 호환되지 않는 경우

### 최신 버전 설정 기준

다음과 같은 경우 최신 버전만 업데이트합니다:

1. **UI 개선**: 사용자 경험 개선
2. **새로운 기능 추가**: 선택적 기능 추가
3. **성능 개선**: 앱 속도 향상
4. **버그 수정**: 심각하지 않은 버그 수정

## 배포 프로세스

### 1. 앱 버전 업데이트

`pubspec.yaml` 파일에서 버전 수정:

```yaml
version: 1.0.6+36  # 1.0.6: 버전 이름, 36: 빌드 번호
```

### 2. 앱 빌드 및 배포

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 3. 스토어 등록

- Google Play Console / App Store Connect에서 새 버전 등록
- 심사 대기

### 4. Supabase 버전 정보 업데이트

심사 승인 후 Supabase의 `app_versions` 테이블 업데이트:

```sql
-- 소프트 업데이트만 필요한 경우
UPDATE app_versions
SET latest_version = '1.0.6', updated_at = NOW()
WHERE platform = 'android' AND is_active = true;

-- 강제 업데이트가 필요한 경우
UPDATE app_versions
SET
  min_version = '1.0.6',  -- 최소 버전도 함께 올림
  latest_version = '1.0.6',
  updated_at = NOW()
WHERE platform = 'android' AND is_active = true;
```

### 5. 사용자 알림

- 앱 실행 시 자동으로 업데이트 팝업 표시됨
- 필요 시 푸시 알림으로 추가 안내

## 테스트 방법

### 1. 로컬 테스트

현재 앱 버전을 낮춰서 테스트:

```yaml
# pubspec.yaml
version: 0.9.0+1  # 낮은 버전으로 설정
```

```sql
-- Supabase에서 최소/최신 버전 설정
UPDATE app_versions
SET
  min_version = '1.0.0',  -- 강제 업데이트 테스트
  latest_version = '1.0.6', -- 소프트 업데이트 테스트
  updated_at = NOW()
WHERE platform = 'android' AND is_active = true;
```

### 2. 시나리오별 테스트

**강제 업데이트 테스트:**
1. `pubspec.yaml`: `version: 0.9.0+1`
2. Supabase: `min_version = '1.0.0'`
3. 앱 실행 → 강제 업데이트 팝업 확인
4. 뒤로가기 차단 확인
5. "업데이트" 버튼 → 스토어 이동 확인

**소프트 업데이트 테스트:**
1. `pubspec.yaml`: `version: 1.0.3+25`
2. Supabase: `min_version = '1.0.0'`, `latest_version = '1.0.6'`
3. 앱 실행 → 소프트 업데이트 팝업 확인
4. "나중에" 버튼 → 앱 정상 사용 확인
5. "업데이트" 버튼 → 스토어 이동 확인

**업데이트 불필요 테스트:**
1. `pubspec.yaml`: `version: 1.0.6+36`
2. Supabase: `latest_version = '1.0.6'`
3. 앱 실행 → 팝업 없이 정상 진행 확인

## 주의사항

1. **스토어 URL 정확성**: 잘못된 URL은 사용자를 혼란스럽게 합니다
2. **점진적 롤아웃**: 강제 업데이트는 신중하게 결정하세요
3. **메시지 명확성**: 업데이트 이유를 명확히 전달하세요
4. **테스트 필수**: 배포 전 충분한 테스트를 진행하세요
5. **버전 체계 일관성**: Semantic Versioning을 일관되게 사용하세요

## FAQ

**Q: 버전 체크에 실패하면 어떻게 되나요?**
A: 앱은 정상적으로 실행됩니다. 버전 체크 실패는 앱 사용을 막지 않습니다.

**Q: 네트워크가 없을 때는요?**
A: Supabase 조회 실패 시 업데이트 팝업이 표시되지 않고 정상 진행됩니다.

**Q: 강제 업데이트를 취소할 수 있나요?**
A: Supabase에서 `min_version`을 낮추면 즉시 반영됩니다 (앱 재시작 시).

**Q: iOS와 Android 버전을 다르게 관리할 수 있나요?**
A: 네, `platform` 필드로 구분하여 각각 다른 버전 정책을 적용할 수 있습니다.

## 트러블슈팅

### 문제: 업데이트 팝업이 표시되지 않음

**원인:**
- Supabase 연결 실패
- `is_active = false`로 설정됨
- 플랫폼 필터링 오류

**해결:**
```sql
-- 활성 상태 확인
SELECT * FROM app_versions WHERE is_active = true;

-- 플랫폼별 확인
SELECT * FROM app_versions WHERE platform = 'android' AND is_active = true;
```

### 문제: 스토어 페이지가 열리지 않음

**원인:**
- 잘못된 스토어 URL
- URL scheme 권한 문제

**해결:**
1. 스토어 URL 형식 확인
2. AndroidManifest.xml / Info.plist에 URL scheme 권한 추가

### 문제: 버전 비교가 정확하지 않음

**원인:**
- 버전 형식 불일치 (예: 1.0 vs 1.0.0)

**해결:**
- 항상 `MAJOR.MINOR.PATCH` 형식 사용 (예: 1.0.0)

## 관련 파일

- **백엔드 스키마**: `docs/app_version_schema.sql`
- **모델**: `lib/models/app_version.dart`
- **서비스**: `lib/services/app_version_service.dart`
- **UI**: `lib/widgets/update_dialog.dart`
- **통합**: `lib/main.dart` (AuthWrapper)

## 문의

버전 업데이트 시스템 관련 문의사항은 개발팀에 연락해주세요.
