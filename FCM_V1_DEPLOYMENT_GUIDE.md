# P2P 채팅 푸시 알림 배포 가이드 (FCM v1 API)

## 📌 개요

FCM Legacy API가 2024년 6월에 종료되었으므로, **FCM v1 API**를 사용하는 Edge Function으로 업데이트되었습니다.

## ✅ 완료된 작업

1. ✅ Edge Function 코드를 FCM v1 API로 업데이트
2. ✅ 앱의 FCM 서비스는 **수정 불필요** (Firebase Messaging SDK는 동일하게 작동)
3. ✅ `.gitignore`에 Firebase Service Account JSON 추가

## 🚀 배포 단계

### 1단계: Firebase Service Account JSON 다운로드

1. **Firebase Console** 접속: https://console.firebase.google.com/
2. 프로젝트 선택: **`smart-yoram`**
3. ⚙️ **프로젝트 설정** → **서비스 계정** 탭
4. **새 비공개 키 생성** 버튼 클릭
5. JSON 파일 다운로드 (예: `smart-yoram-firebase-adminsdk-xxxxx.json`)

> **주의**: 이 JSON 파일에는 민감한 비공개 키가 포함되어 있으므로 절대 Git에 커밋하지 마세요!

### 2단계: Firebase Cloud Messaging API (v1) 활성화

1. **Google Cloud Console** 접속: https://console.cloud.google.com/
2. 프로젝트 선택: **`smart-yoram`**
3. **API 및 서비스** → **라이브러리**
4. "Firebase Cloud Messaging API" 검색
5. **사용 설정** 클릭

또는 직접 링크: https://console.cloud.google.com/apis/library/fcm.googleapis.com

### 3단계: Edge Function 배포

프로젝트 루트 디렉토리에서 다음 명령어 실행:

```bash
# 1. Supabase 프로젝트 링크 (최초 1회만)
cd /Users/admin/Desktop/workspace/smart_yoram_app
supabase link --project-ref adzhdsajdamrflvybhxq

# 2. Edge Function 배포
supabase functions deploy send-chat-notification

# 3. Firebase Service Account JSON을 Supabase Secret으로 설정
# 다운로드한 JSON 파일 경로를 입력하세요
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat ~/Downloads/smart-yoram-firebase-adminsdk-xxxxx.json | tr -d '\n')"

# 4. Firebase 프로젝트 ID 설정 (선택사항, 기본값: smart-yoram)
supabase secrets set FIREBASE_PROJECT_ID=smart-yoram

# 5. 환경변수 설정 확인
supabase secrets list
```

**기대 출력:**
```
FIREBASE_SERVICE_ACCOUNT
FIREBASE_PROJECT_ID
SUPABASE_URL (자동 설정)
SUPABASE_SERVICE_ROLE_KEY (자동 설정)
```

### 4단계: Database Trigger 확인

이미 SQL로 설정했다고 하셨으므로, 정상 작동하는지 확인:

```sql
-- Trigger 확인
SELECT
  tgname AS trigger_name,
  tgenabled AS enabled,
  relname AS table_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE tgname = 'on_chat_message_created';

-- pg_net 확장 확인
SELECT * FROM pg_extension WHERE extname = 'pg_net';

-- device_tokens 테이블 데이터 확인
SELECT user_id, platform, is_active, created_at
FROM device_tokens
ORDER BY created_at DESC
LIMIT 5;
```

### 5단계: 테스트

#### A. Edge Function 로그 모니터링

1. **Supabase Dashboard** 접속
2. **Edge Functions** → **`send-chat-notification`** 클릭
3. **Logs** 탭 선택 (실시간 로그 확인)

#### B. 실제 채팅 메시지 전송

1. 앱에서 두 개의 계정으로 로그인 (서로 다른 디바이스)
2. 한 쪽에서 채팅 메시지 전송
3. 다른 쪽에서 푸시 알림 수신 확인

#### C. 예상 로그 출력

**성공 시:**
```
📩 새 채팅 메시지 알림 발송: { messageId: X, roomId: Y, senderId: Z }
👥 수신자 조회 완료: 1명
🔑 OAuth2 액세스 토큰 생성 완료
📱 FCM 토큰 조회: user_id=56, platform=ios, token=del_FyfT-kikth7GqvlC...
🚀 FCM v1 알림 발송 시도 (user_id: 56)
✅ FCM 알림 발송 성공 (user_id: 56, platform: ios)
```

**실패 시 확인:**
```
❌ FIREBASE_SERVICE_ACCOUNT 환경변수가 설정되지 않았습니다
❌ 액세스 토큰 생성 실패: ...
❌ FCM 알림 발송 실패: UNAUTHENTICATED
```

## 🔧 문제 해결

### 오류: "FIREBASE_SERVICE_ACCOUNT 환경변수가 설정되지 않았습니다"

**해결:**
```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat your-firebase-adminsdk.json | tr -d '\n')"
```

### 오류: "UNAUTHENTICATED" 또는 "PERMISSION_DENIED"

**원인**: Service Account 권한 부족 또는 FCM API 미활성화

**해결:**
1. Google Cloud Console에서 Firebase Cloud Messaging API (v1) 활성화 확인
2. Service Account에 "Firebase Cloud Messaging API Admin" 역할 부여:
   - Firebase Console → 프로젝트 설정 → 서비스 계정
   - 해당 Service Account → 권한 확인

### 오류: "UNREGISTERED" (FCM 토큰 무효)

**원인**: 앱을 재설치하거나 토큰이 만료됨

**해결:**
```sql
-- 무효한 토큰 비활성화
UPDATE device_tokens
SET is_active = false
WHERE fcm_token = 'INVALID_TOKEN';
```

앱에서 로그아웃 후 다시 로그인하면 새 토큰이 자동 등록됩니다.

### 오류: "unknown/unsupported ASN.1 DER tag: 0x2d"

**원인**: Service Account JSON의 private_key 형식 오류

**해결:**
- JSON 파일을 다시 다운로드
- `tr -d '\n'`으로 줄바꿈 제거 후 Secrets에 등록
- JSON 파일이 손상되지 않았는지 확인

## 📝 참고 사항

1. **앱 코드는 수정 불필요**
   - FCM v1 API는 서버 측(Edge Function)에서만 사용
   - 앱은 기존 Firebase Messaging SDK를 그대로 사용

2. **Service Account JSON 보안**
   - 절대 Git에 커밋하지 마세요 (`.gitignore`에 이미 추가됨)
   - Supabase Secrets로만 관리

3. **FCM v1 API vs Legacy API**
   - Legacy API: `https://fcm.googleapis.com/fcm/send` (종료됨)
   - v1 API: `https://fcm.googleapis.com/v1/projects/{projectId}/messages:send`

4. **토큰 저장 확인**
   ```sql
   SELECT * FROM device_tokens WHERE user_id = YOUR_USER_ID;
   ```

## 🎯 완료 체크리스트

- [ ] Firebase Service Account JSON 다운로드 완료
- [ ] Firebase Cloud Messaging API (v1) 활성화 완료
- [ ] Edge Function 배포 완료
- [ ] Supabase Secrets 설정 완료 (`FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`)
- [ ] Database Trigger 생성 완료 (`on_chat_message_created`)
- [ ] pg_net 확장 설치 완료
- [ ] device_tokens 테이블에 FCM 토큰 저장 확인
- [ ] Edge Function 로그에서 성공 메시지 확인
- [ ] 실제 디바이스에서 푸시 알림 수신 확인

## 📚 관련 문서

- [전체 설정 가이드](/docs/p2p_chat_push_notification_setup.md)
- [Firebase Cloud Messaging 공식 문서](https://firebase.google.com/docs/cloud-messaging)
- [Supabase Edge Functions 문서](https://supabase.com/docs/guides/functions)
