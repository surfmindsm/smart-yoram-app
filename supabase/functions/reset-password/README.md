# reset-password Edge Function

비밀번호 재설정을 위한 Supabase Edge Function입니다. 임시 비밀번호를 생성하고 Resend를 통해 이메일로 전송합니다.

## 기능

1. **이메일 + 전화번호로 사용자 조회** (`users` 테이블)
   - 두 정보가 모두 일치해야 본인 확인 성공
2. 임시 비밀번호 생성 (8자리 영문 대소문자 + 숫자)
3. `users` 테이블의 `hashed_password` 업데이트
4. `is_first` 플래그를 `true`로 설정 (로그인 시 비밀번호 변경 다이얼로그 표시)
5. Resend API를 통해 임시 비밀번호 이메일 전송

## 환경 변수 설정

Supabase Dashboard > Settings > Edge Functions > Secrets에서 다음 환경 변수를 설정해야 합니다:

```bash
RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxx
```

### Resend API 키 발급 방법

1. [Resend](https://resend.com)에 가입
2. Dashboard > API Keys 메뉴로 이동
3. "Create API Key" 클릭
4. Name: `ChurchRound Production` (또는 원하는 이름)
5. Permission: `Sending access` 선택
6. 생성된 API 키를 복사하여 Supabase Secrets에 등록

## 배포 방법

### 1. Supabase CLI 설치

```bash
# macOS
brew install supabase/tap/supabase

# Windows (scoop 사용)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux
brew install supabase/tap/supabase
```

### 2. Supabase 프로젝트 연결

```bash
# 프로젝트 루트에서 실행
cd /path/to/smart_yoram_app

# Supabase 로그인
supabase login

# 프로젝트 연결 (프로젝트 ID는 Supabase Dashboard에서 확인)
supabase link --project-ref <your-project-ref>
```

### 3. Edge Function 배포

```bash
# reset-password 함수만 배포
supabase functions deploy reset-password

# 또는 모든 함수 배포
supabase functions deploy
```

### 4. 환경 변수 설정

```bash
# Resend API 키 설정
supabase secrets set RESEND_API_KEY=re_xxxxxxxxxxxxxxxxxxxxx

# 환경 변수 확인
supabase secrets list
```

## 사용 방법

### Flutter 앱에서 호출

```dart
// AuthService에서 이미 구현됨
final result = await _authService.requestPasswordReset(
  'user@example.com',
  '01012345678'  // 전화번호 (숫자만)
);

if (result.success) {
  print(result.message); // "임시 비밀번호가 이메일로 전송되었습니다..."
}
```

### 직접 API 호출 (테스트용)

```bash
curl -i --location --request POST 'https://<project-ref>.supabase.co/functions/v1/reset-password' \
  --header 'Authorization: Bearer <anon-key>' \
  --header 'Content-Type: application/json' \
  --data '{"email":"user@example.com","phone":"01012345678"}'
```

## 응답 형식

### 성공

```json
{
  "success": true,
  "message": "임시 비밀번호가 이메일로 전송되었습니다. 로그인 후 비밀번호를 변경해주세요."
}
```

### 실패

```json
{
  "success": false,
  "message": "비밀번호 재설정 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
  "error": "에러 메시지"
}
```

## 보안 고려사항

1. **2단계 본인 확인**: 이메일과 전화번호가 모두 일치해야만 비밀번호 재설정이 가능합니다.
2. **정보 존재 여부 노출 방지**: 사용자가 존재하지 않거나 정보가 일치하지 않아도 동일한 성공 메시지를 반환합니다.
3. **비활성화된 사용자 처리**: `is_active=false`인 사용자도 성공 메시지를 반환하지만 실제로는 이메일을 보내지 않습니다.
4. **임시 비밀번호 복잡도**: 혼동되기 쉬운 문자(0, O, 1, l, I)를 제외하고 8자리 랜덤 생성합니다.
5. **첫 로그인 강제**: `is_first=true`로 설정하여 로그인 시 반드시 비밀번호를 변경하도록 유도합니다.

## 이메일 템플릿

이메일은 다음과 같은 내용으로 전송됩니다:

- **제목**: `[ChurchRound] 임시 비밀번호 안내`
- **발신자**: `ChurchRound <noreply@churchround.com>`
- **내용**:
  - 인사말 (사용자 이름 포함)
  - 임시 비밀번호 (강조 표시)
  - 보안 안내 사항
  - 앱으로 이동하기 버튼

## 로그

Edge Function 실행 로그는 Supabase Dashboard > Edge Functions > reset-password > Logs에서 확인할 수 있습니다.

```
📧 비밀번호 재설정 요청: user@example.com 01012345678
✅ 사용자 조회 성공: user@example.com (ID: 123)
🔑 임시 비밀번호 생성: Abc12345
✅ 임시 비밀번호 설정 완료 (is_first=true)
✅ Resend 이메일 전송 성공: {...}
✅ 비밀번호 재설정 완료
```

## 문제 해결

### Resend 이메일 전송 실패

- **증상**: `❌ Resend 이메일 전송 실패`
- **원인**:
  - Resend API 키가 잘못되었거나 만료됨
  - Resend 계정의 발송 제한 초과
  - 발신자 이메일 도메인이 인증되지 않음
- **해결**:
  1. Resend Dashboard에서 API 키 확인
  2. Resend Dashboard > Domains에서 도메인 인증 상태 확인
  3. 무료 플랜인 경우 발송 제한 확인 (월 100통)

### 사용자 조회 실패

- **증상**: `❌ 사용자 조회 오류`
- **원인**: Supabase `users` 테이블 접근 권한 문제
- **해결**: Edge Function은 `SUPABASE_SERVICE_ROLE_KEY`를 사용하므로 권한 문제가 없어야 합니다. Row Level Security (RLS) 정책을 확인하세요.

## 관련 파일

- **Edge Function**: `supabase/functions/reset-password/index.ts`
- **AuthService**: `lib/services/auth_service.dart` (line 187-224)
- **UI**: `lib/screens/login_screen.dart` (비밀번호 찾기 다이얼로그)
