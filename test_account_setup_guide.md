# 테스터 계정 생성 가이드

앱 마켓 심사용 테스터 계정을 생성하는 방법입니다.

## 계정 정보
- **이메일**: tester1@test.com
- **비밀번호**: test123!@#
- **교회 ID**: 10번
- **교회명**: 테스트교회

## 방법 1: 앱을 통한 회원가입 (권장)

가장 안전하고 간단한 방법입니다.

1. 앱을 실행합니다
2. 회원가입 화면으로 이동합니다
3. 다음 정보를 입력합니다:
   - 이메일: `tester1@test.com`
   - 비밀번호: `test123!@#`
   - 이름: `테스터1`
   - 교회: `10번 - 테스트교회` (먼저 교회가 생성되어 있어야 함)
   - 기타 필수 정보 입력

## 방법 2: Supabase Dashboard 사용

Supabase에서 직접 생성하는 방법입니다.

### 단계 1: 10번 교회 생성

1. Supabase Dashboard에 로그인
2. SQL Editor로 이동
3. 다음 SQL 실행:

```sql
INSERT INTO public.churches (
    id,
    name,
    address,
    phone,
    pastor_name,
    denomination,
    description,
    website,
    established_date,
    is_active,
    created_at,
    updated_at
) VALUES (
    10,
    '테스트교회',
    '서울특별시 강남구 테헤란로 123',
    '02-1234-5678',
    '테스트목사',
    '대한예수교장로회',
    '앱 마켓 심사를 위한 테스트 교회입니다.',
    'https://test-church.example.com',
    '2024-01-01',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    phone = EXCLUDED.phone,
    pastor_name = EXCLUDED.pastor_name,
    updated_at = NOW();
```

### 단계 2: Auth 사용자 생성

1. Supabase Dashboard > Authentication > Users 메뉴로 이동
2. "Add user" 버튼 클릭
3. 다음 정보 입력:
   - Email: `tester1@test.com`
   - Password: `test123!@#`
   - Auto Confirm User: **체크** (이메일 인증 우회)
4. 생성된 사용자의 UUID 복사 (예: `550e8400-e29b-41d4-a716-446655440000`)

### 단계 3: 멤버 정보 생성

1. SQL Editor로 돌아가기
2. 다음 SQL에서 `YOUR_AUTH_USER_UUID`를 실제 UUID로 교체 후 실행:

```sql
INSERT INTO public.members (
    church_id,
    user_id,
    name,
    email,
    phone,
    birth_date,
    gender,
    address,
    address_detail,
    join_date,
    member_type,
    is_active,
    created_at,
    updated_at
) VALUES (
    10,
    'YOUR_AUTH_USER_UUID',  -- 여기를 교체하세요!
    '테스터1',
    'tester1@test.com',
    '010-1234-5678',
    '1990-01-01',
    'male',
    '서울특별시 강남구 테헤란로 123',
    '101동 101호',
    CURRENT_DATE,
    'regular',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    church_id = EXCLUDED.church_id,
    name = EXCLUDED.name,
    updated_at = NOW();
```

### 단계 4: 확인

```sql
SELECT
    c.id as church_id,
    c.name as church_name,
    m.id as member_id,
    m.name as member_name,
    m.email,
    m.phone
FROM public.churches c
LEFT JOIN public.members m ON m.church_id = c.id
WHERE c.id = 10;
```

## 방법 3: 백엔드 API 사용

백엔드 API가 있다면 이를 사용할 수도 있습니다.

```bash
# 1. 10번 교회 생성 (관리자 권한 필요)
curl -X POST https://api.surfmind-team.com/api/v1/churches/ \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "id": 10,
    "name": "테스트교회",
    "address": "서울특별시 강남구 테헤란로 123",
    "phone": "02-1234-5678",
    "pastor_name": "테스트목사",
    "denomination": "대한예수교장로회"
  }'

# 2. 회원가입 (앱의 회원가입 API 사용)
# 앱의 회원가입 플로우를 따르세요
```

## 테스트 확인사항

계정 생성 후 다음 기능들을 테스트하세요:

- [ ] 로그인
- [ ] 교회 정보 조회
- [ ] 멤버 프로필 조회
- [ ] 공지사항 확인
- [ ] 주보 확인
- [ ] 출석 체크 (QR 코드)
- [ ] 커뮤니티 기능
- [ ] 푸시 알림 수신

## 주의사항

1. **프로덕션 환경**: 실제 프로덕션 데이터베이스에서 작업 중인지 확인하세요
2. **ID 충돌**: 10번 교회가 이미 존재하는 경우 다른 ID를 사용하세요
3. **이메일 중복**: `tester1@test.com`이 이미 존재하는 경우 다른 이메일을 사용하세요
4. **비밀번호 정책**: 백엔드의 비밀번호 정책을 만족하는지 확인하세요

## 문제 해결

### "auth.users에 삽입 권한 없음" 오류
→ Supabase Dashboard의 Authentication UI를 사용하세요

### "이메일 중복" 오류
→ 기존 계정을 삭제하거나 다른 이메일을 사용하세요

### "교회 ID 충돌" 오류
→ 다른 ID를 사용하거나 ON CONFLICT 절이 제대로 동작하는지 확인하세요

## 심사 제출 시 제공할 정보

```
테스트 계정 정보:
- 이메일: tester1@test.com
- 비밀번호: test123!@#
- 교회: 테스트교회 (ID: 10)
- 멤버명: 테스터1

앱의 모든 기능을 테스트할 수 있는 계정입니다.
```
