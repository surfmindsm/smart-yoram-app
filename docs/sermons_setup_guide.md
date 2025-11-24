# 명설교 기능 설정 가이드

명설교 기능이 성공적으로 구현되었습니다! 이 가이드는 개발자가 Supabase에서 테이블을 설정하고, 유튜브 동영상을 관리하는 방법을 안내합니다.

## 📋 목차
1. [Supabase 테이블 생성](#1-supabase-테이블-생성)
2. [유튜브 동영상 추가 방법](#2-유튜브-동영상-추가-방법)
3. [앱에서 확인하기](#3-앱에서-확인하기)
4. [관리 및 유지보수](#4-관리-및-유지보수)

---

## 1. Supabase 테이블 생성

### 1.1 Supabase Dashboard 접속
1. Supabase Dashboard (https://supabase.com/dashboard)에 로그인
2. 프로젝트 선택
3. 좌측 메뉴에서 **SQL Editor** 클릭

### 1.2 SQL 스크립트 실행
1. `docs/sermons_table_schema.sql` 파일 열기
2. 파일 내용 전체를 복사
3. Supabase SQL Editor에 붙여넣기
4. 우측 상단의 **RUN** 버튼 클릭

### 1.3 생성되는 항목
- `sermons` 테이블 (명설교 데이터 저장)
- 6개의 인덱스 (성능 최적화)
- RLS (Row Level Security) 정책
- 자동 업데이트 트리거
- 샘플 데이터 3개 (테스트용)

---

## 2. 유튜브 동영상 추가 방법

### 2.1 Supabase Table Editor를 통한 추가 (권장)

1. Supabase Dashboard > **Table Editor** 이동
2. `sermons` 테이블 선택
3. **Insert row** 버튼 클릭
4. 다음 필드 입력:

| 필드명 | 설명 | 예시 | 필수 여부 |
|--------|------|------|-----------|
| `title` | 설교 제목 | "은혜와 진리가 충만하신 예수" | ✅ 필수 |
| `youtube_url` | 유튜브 전체 URL | https://www.youtube.com/watch?v=dQw4w9WgXcQ | ✅ 필수 |
| `youtube_video_id` | 유튜브 비디오 ID | dQw4w9WgXcQ | ✅ 필수 |
| `preacher_name` | 설교자 이름 | "김목사" | ⚪ 선택 |
| `description` | 설교 설명 | "요한복음 1장을 통해..." | ⚪ 선택 |
| `category` | 카테고리 | "주일설교", "수요예배", "특별집회" | ⚪ 선택 |
| `sermon_date` | 설교 날짜 | 2024-01-07 | ⚪ 선택 |
| `is_featured` | 추천 설교 여부 | true / false | ⚪ 선택 (기본: false) |
| `display_order` | 표시 순서 | 1, 2, 3... | ⚪ 선택 (기본: 0) |
| `is_active` | 활성화 여부 | true / false | ⚪ 선택 (기본: true) |

5. **Save** 버튼 클릭

### 2.2 유튜브 비디오 ID 추출 방법

**방법 1: URL에서 직접 추출**
- `https://www.youtube.com/watch?v=VIDEO_ID` → `VIDEO_ID` 부분 복사
- `https://youtu.be/VIDEO_ID` → `VIDEO_ID` 부분 복사

**방법 2: 유튜브에서 공유 링크 사용**
1. 유튜브 동영상에서 "공유" 버튼 클릭
2. "복사" 버튼 클릭 → `https://youtu.be/VIDEO_ID` 형식으로 복사됨
3. 마지막 슬래시(`/`) 뒤의 `VIDEO_ID` 부분만 추출

### 2.3 SQL을 통한 직접 추가

```sql
INSERT INTO public.sermons (
  title,
  youtube_url,
  youtube_video_id,
  preacher_name,
  description,
  category,
  sermon_date,
  is_featured,
  display_order
) VALUES (
  '설교 제목',
  'https://www.youtube.com/watch?v=VIDEO_ID',
  'VIDEO_ID',
  '설교자 이름',
  '설교 설명',
  '주일설교',
  '2024-01-07',
  false,
  0
);
```

---

## 3. 앱에서 확인하기

### 3.1 앱 실행
```bash
flutter run
```

### 3.2 명설교 탭 확인
1. 앱 실행 후 로그인
2. 하단 탭바에서 **"명설교"** 탭 클릭 (비디오 라이브러리 아이콘)
3. 설교 목록 확인

### 3.3 주요 기능
- **추천 설교 섹션**: `is_featured = true`인 설교들을 가로 스크롤로 표시
- **카테고리 필터**: 카테고리별로 설교 필터링
- **전체 설교 리스트**: 모든 활성 설교 목록
- **설교 상세 화면**: 유튜브 플레이어로 동영상 재생
- **조회수 카운트**: 설교를 볼 때마다 자동으로 조회수 증가

---

## 4. 관리 및 유지보수

### 4.1 추천 설교 관리
추천 설교로 표시하려면:
```sql
UPDATE public.sermons
SET is_featured = true, display_order = 1
WHERE id = '설교 UUID';
```

`display_order`가 작을수록 상위에 표시됩니다.

### 4.2 설교 비활성화 (삭제 대신 권장)
```sql
UPDATE public.sermons
SET is_active = false
WHERE id = '설교 UUID';
```

### 4.3 카테고리 목록 조회
```sql
SELECT DISTINCT category
FROM public.sermons
WHERE is_active = true
ORDER BY category;
```

### 4.4 최신 설교 조회
```sql
SELECT *
FROM public.sermons
WHERE is_active = true
ORDER BY sermon_date DESC
LIMIT 10;
```

### 4.5 조회수 많은 설교 조회
```sql
SELECT *
FROM public.sermons
WHERE is_active = true
ORDER BY view_count DESC
LIMIT 10;
```

---

## 📝 참고 사항

### 카테고리 추천 목록
- 주일설교
- 수요예배
- 금요기도회
- 새벽기도회
- 특별집회
- 부흥회
- 전도집회
- 성경공부

### 썸네일 자동 생성
앱에서 유튜브 비디오 ID를 사용하여 자동으로 썸네일을 생성합니다:
- 기본 화질: `https://img.youtube.com/vi/VIDEO_ID/default.jpg`
- 중간 화질: `https://img.youtube.com/vi/VIDEO_ID/mqdefault.jpg`
- 고화질: `https://img.youtube.com/vi/VIDEO_ID/hqdefault.jpg`

### RLS (Row Level Security) 정책
- **조회 (SELECT)**: 모든 사용자가 활성화된 설교(`is_active = true`)를 조회 가능
- **생성/수정/삭제**: 인증된 사용자만 가능 (관리자 권한 필요)

---

## 🔧 문제 해결

### 동영상이 재생되지 않는 경우
1. 유튜브 비디오 ID가 정확한지 확인
2. 유튜브 동영상이 공개 상태인지 확인 (비공개/제한된 동영상은 재생 불가)
3. 네트워크 연결 상태 확인

### 설교가 목록에 표시되지 않는 경우
1. `is_active` 필드가 `true`로 설정되어 있는지 확인
2. Supabase RLS 정책이 올바르게 설정되어 있는지 확인

### 썸네일이 표시되지 않는 경우
- 유튜브 API 제한으로 인해 일부 동영상의 썸네일이 표시되지 않을 수 있습니다.
- 이 경우 앱에서 기본 플레이 아이콘이 대신 표시됩니다.

---

## 📞 문의 및 지원

추가 질문이나 문제가 있을 경우, 개발팀에 문의하세요.
