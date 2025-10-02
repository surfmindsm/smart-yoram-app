# 모바일 화면과 API 문서 매핑

이 문서는 Flutter 모바일 앱의 커뮤니티 글쓰기 화면과 각 API 명세서를 매핑합니다.

---

## 개요

**글쓰기 화면**: `/lib/screens/community/community_create_screen.dart`

이 화면은 모든 커뮤니티 카테고리의 글쓰기를 처리하는 **통합 글쓰기 화면**입니다.
`CommunityListType`에 따라 다른 필드를 표시하고, 해당하는 API를 호출합니다.

---

## 카테고리별 매핑

### 1. 무료 나눔 (Free Sharing)

#### 화면 정보
- **타입**: `CommunityListType.freeSharing`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - `_isFree = true`
  - 거래 방법 (직거래/택배/직거래,택배)

#### API 문서
- **파일**: `docs/writing/mobile-api-free-sharing.md`
- **엔드포인트**: `POST /functions/v1/community-sharing`
- **테이블**: `community_sharing`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 내용 |
| _locationController | location | 지역 |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |
| _selectedImages | images | 이미지 URL 배열 |
| _isFree = true | is_free | 무료나눔 여부 |
| (드롭다운) | delivery_method | 거래방법 |

---

### 2. 물품 판매 (Item Sale)

#### 화면 정보
- **타입**: `CommunityListType.itemSale`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - `_isFree = false`
  - `_priceController` (가격 입력)
  - 거래 방법

#### API 문서
- **파일**: `docs/writing/mobile-api-sharing-offer.md`
- **엔드포인트**: `POST /functions/v1/community-sharing` (무료나눔과 동일 API)
- **테이블**: `community_sharing`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 내용 |
| _locationController | location | 지역 |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |
| _selectedImages | images | 이미지 URL 배열 |
| _isFree = false | is_free | 무료나눔 여부 (false=판매) |
| _priceController | price | 판매 가격 |
| (드롭다운) | delivery_method | 거래방법 |

---

### 3. 물품 요청 (Item Request)

#### 화면 정보
- **타입**: `CommunityListType.itemRequest`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - `_priceRangeController` (희망 가격대)
  - 긴급도 선택

#### API 문서
- **파일**: `docs/writing/mobile-api-item-request.md`
- **엔드포인트**: `POST /functions/v1/community-requests`
- **테이블**: `community_requests`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 내용 |
| _locationController | location | 지역 |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |
| _priceRangeController | price_range | 희망 가격대 (선택) |
| (드롭다운) | urgency | 긴급도 (low/normal/medium/high) |
| _selectedImages | images | 참고 이미지 (선택) |

---

### 4. 사역자 모집 (Job Posting)

#### 화면 정보
- **타입**: `CommunityListType.jobPosting`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - `_salaryController` (급여)
  - 근무 형태 (정규직/계약직/파트타임 등)

#### API 문서
- **파일**: `docs/writing/mobile-api-job-posting.md`
- **엔드포인트**: `POST /api/v1/job-posts` (레거시 API)
- **테이블**: `job_posts`
- **인증**: JWT Token (`Authorization: Bearer` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 공고 제목 |
| _descriptionController | description | 상세 설명 |
| _locationController | location | 근무지 |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |
| _salaryController | salary | 급여 |
| (드롭다운) | employment_type | 근무형태 (full-time/part-time/contract) |
| (입력필드) | position | 모집 직책 |
| (입력필드) | job_type | 직종 |

**주의**: 사역자 모집은 **레거시 REST API**를 사용하며, JWT Token 인증이 필요합니다.

---

### 5. 행사팀 모집 (Music Team Recruitment)

#### 화면 정보
- **타입**: `CommunityListType.musicTeamRecruit`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - 모집 파트 (보컬/건반/기타/베이스/드럼 등)
  - 필요 인원
  - 연습 일정

#### API 문서
- **파일**: `docs/writing/mobile-api-music-team-recruit.md`
- **엔드포인트**: `POST /functions/v1/music-team-recruitment`
- **테이블**: `community_music_teams`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 상세 설명 |
| _locationController | location | 활동 지역 |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |
| (멀티선택) | instruments_needed | 필요 파트 (배열) |
| (입력필드) | recruitment_type | 모집 유형 (new_member/substitute/project) |
| (입력필드) | schedule | 연습 일정 (선택) |

---

### 6. 행사팀 지원 (Music Team Seeking)

#### 화면 정보
- **타입**: `CommunityListType.musicTeamSeeking`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - 전공 파트
  - 경력
  - 포트폴리오 파일 업로드
  - 가능한 시간대

#### API 문서
- **파일**: `docs/writing/mobile-api-music-team-seeking.md`
- **엔드포인트**: `POST /functions/v1/music-team-seekers`
- **테이블**: `music_team_seekers`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 자기소개 |
| (입력필드) | name | 이름 |
| (드롭다운) | instrument | 전공 파트 |
| (멀티선택) | instruments | 가능한 파트 (배열, 선택) |
| (입력필드) | experience | 경력 |
| (텍스트) | portfolio | 포트폴리오 설명 |
| (파일업로드) | portfolio_file | 포트폴리오 파일 URL (선택) |
| (멀티선택) | preferred_location | 선호 지역 (배열) |
| (멀티선택) | available_days | 가능한 요일 (배열) |
| (입력필드) | available_time | 가능한 시간대 (선택) |
| _contactPhoneController | contact_phone | 연락처 |
| _contactEmailController | contact_email | 이메일 (선택) |

---

### 7. 교회 소식 (Church News)

#### 화면 정보
- **타입**: `CommunityListType.churchNews`
- **화면 제목**: "글쓰기"
- **특수 필드**:
  - 행사 일시
  - 대상
  - 참가비

#### API 문서
- **파일**: `docs/writing/mobile-api-church-news.md`
- **엔드포인트**: `POST /functions/v1/church-news`
- **테이블**: `church_news`
- **인증**: Custom Token (`X-Custom-Auth` 헤더)

#### 필수 필드 매핑
| 화면 필드 | API 필드 | 설명 |
|----------|---------|------|
| _titleController | title | 제목 |
| _descriptionController | description | 내용 |
| (입력필드) | category | 카테고리 (예배/행사/수련회 등) |
| (날짜선택) | event_date | 행사 날짜 (선택) |
| (시간선택) | event_time | 행사 시간 (선택) |
| _locationController | location | 장소 (선택) |
| (입력필드) | organizer | 주최 (선택) |
| (입력필드) | target_audience | 대상 (선택) |
| (입력필드) | participation_fee | 참가비 (선택) |
| (드롭다운) | priority | 중요도 (urgent/important/normal) |
| _contactPhoneController | contact_phone | 연락처 (선택) |
| _contactEmailController | contact_email | 이메일 (선택) |
| _selectedImages | images | 이미지 URL 배열 (선택) |

---

## 공통 사항

### 인증 방식

#### Custom Token 방식 (대부분의 API)
```dart
// AuthService에서 생성
String? getTempToken() {
  if (_currentUser == null) return null;
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'temp_token_${_currentUser!.id}_$timestamp';
}
```

**헤더 설정**:
```dart
headers: {
  'Authorization': 'Bearer {SUPABASE_ANON_KEY}',
  'X-Custom-Auth': 'temp_token_{user_id}_{timestamp}',
  'Content-Type': 'application/json',
}
```

#### JWT Token 방식 (사역자 모집만)
```dart
headers: {
  'Authorization': 'Bearer {JWT_TOKEN}',
  'Content-Type': 'application/json',
}
```

### 이미지 업로드

모든 카테고리는 **Supabase Storage**를 사용하여 이미지를 업로드합니다.

1. **먼저 이미지 업로드**:
   - Storage 경로: `community-images/{category}/{timestamp}_{filename}`
   - 반환값: Public URL

2. **이미지 URL을 배열로 변환**:
   ```dart
   List<String> imageUrls = ['https://...', 'https://...'];
   ```

3. **글 작성 API에 전달**:
   ```json
   {
     "images": ["https://...", "https://..."]
   }
   ```

### 현재 구현 상태

#### ✅ 구현 완료
- 무료 나눔 (Free Sharing)
- 물품 판매 (Item Sale)
- 물품 요청 (Item Request)
- 사역자 모집 (Job Posting) - 기본 구조

#### ⚠️ 부분 구현
- 행사팀 모집 (Music Team Recruitment) - UI만 있음
- 행사팀 지원 (Music Team Seeking) - UI만 있음
- 교회 소식 (Church News) - UI만 있음

#### ❌ 미구현
- 각 카테고리별 상세 필드
- 파일 업로드 (포트폴리오)
- 드롭다운 옵션 데이터
- 입력 검증 로직
- API 연동 (`_submit()` 메서드)

---

## 개발자 가이드

### 새로운 카테고리 추가 시

1. **API 문서 작성** (`docs/writing/` 디렉토리)
2. **모델 정의** (`lib/models/community_models.dart`)
3. **서비스 메서드 추가** (`lib/services/community_service.dart`)
4. **화면 필드 추가** (`lib/screens/community/community_create_screen.dart`)
   - `_buildTypeSpecificFields()` 에 case 추가
   - 필요한 컨트롤러 추가
5. **제출 로직 구현** (`_submit()` 메서드)

### 테스트 방법

1. **로컬 개발 환경**:
   - Supabase URL: `https://adzhdsajdamrflvybhxq.supabase.co`
   - Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

2. **테스트 사용자**:
   - API 문서의 "테스트 정보" 섹션 참조

3. **Postman/Thunder Client**:
   - docs/writing/ 의 각 API 문서에 요청 예시 포함

---

## 참고 링크

- [커뮤니티 서비스 구현](../lib/services/community_service.dart)
- [커뮤니티 모델 정의](../lib/models/community_models.dart)
- [글쓰기 화면](../lib/screens/community/community_create_screen.dart)
- [API 명세서 디렉토리](./)