# P2P 채팅 기능 백엔드 설정 가이드

## 개요
1:1 채팅 시스템을 위한 Supabase 백엔드 설정 가이드입니다.
기존 AI 채팅 테이블(`chat_histories`, `chat_messages`)과 충돌을 방지하기 위해 `p2p_` 접두사를 사용합니다.

## 테이블 구조

### 1. p2p_chat_rooms (채팅방)
- 커뮤니티 게시글과 연결된 1:1 채팅방 정보
- 마지막 메시지 캐싱으로 채팅 목록 성능 최적화

### 2. p2p_chat_participants (참여자)
- 채팅방 참여자 정보 (항상 2명: 게시글 작성자 + 문의자)
- 안 읽은 메시지 수 관리

### 3. p2p_chat_messages (메시지)
- 실제 채팅 메시지 내용
- 텍스트/이미지/시스템 메시지 지원

---

## 1단계: 테이블 생성

Supabase SQL Editor에서 아래 SQL을 실행하세요.

```sql
-- ============================================================
-- 1. p2p_chat_rooms (채팅방)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.p2p_chat_rooms (
    id BIGSERIAL PRIMARY KEY,
    post_id INTEGER,                    -- 게시글 ID
    post_table TEXT,                    -- 게시글 테이블명 (예: 'community_sharing')
    post_title TEXT,                    -- 게시글 제목
    last_message TEXT,                  -- 마지막 메시지 내용
    last_message_at TIMESTAMPTZ,        -- 마지막 메시지 시간
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_p2p_chat_rooms_post ON public.p2p_chat_rooms(post_id, post_table);
CREATE INDEX idx_p2p_chat_rooms_updated ON public.p2p_chat_rooms(updated_at DESC);

-- ============================================================
-- 2. p2p_chat_participants (참여자)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.p2p_chat_participants (
    id BIGSERIAL PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES public.p2p_chat_rooms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_read_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    unread_count INTEGER DEFAULT 0 NOT NULL,
    UNIQUE(room_id, user_id)
);

CREATE INDEX idx_p2p_chat_participants_room ON public.p2p_chat_participants(room_id);
CREATE INDEX idx_p2p_chat_participants_user ON public.p2p_chat_participants(user_id);

-- ============================================================
-- 3. p2p_chat_messages (메시지)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.p2p_chat_messages (
    id BIGSERIAL PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES public.p2p_chat_rooms(id) ON DELETE CASCADE,
    sender_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    message TEXT NOT NULL,
    message_type TEXT DEFAULT 'text' NOT NULL,  -- 'text', 'image', 'system'
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_p2p_chat_messages_room ON public.p2p_chat_messages(room_id, created_at DESC);
CREATE INDEX idx_p2p_chat_messages_sender ON public.p2p_chat_messages(sender_id);
```

---

## 2단계: RLS (Row Level Security) 정책 설정

보안을 위해 각 테이블에 RLS 정책을 적용합니다.

```sql
-- ============================================================
-- p2p_chat_rooms RLS 정책
-- ============================================================
ALTER TABLE public.p2p_chat_rooms ENABLE ROW LEVEL SECURITY;

-- 조회: 사용자는 자신이 참여한 채팅방만 조회 가능
CREATE POLICY "Users can view their own chat rooms"
ON public.p2p_chat_rooms FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.p2p_chat_participants
        WHERE p2p_chat_participants.room_id = p2p_chat_rooms.id
        AND p2p_chat_participants.user_id = auth.uid()::integer
    )
);

-- 생성: 인증된 사용자는 채팅방 생성 가능
CREATE POLICY "Authenticated users can create chat rooms"
ON public.p2p_chat_rooms FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- 업데이트: 사용자는 자신이 참여한 채팅방만 업데이트 가능
CREATE POLICY "Users can update their own chat rooms"
ON public.p2p_chat_rooms FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.p2p_chat_participants
        WHERE p2p_chat_participants.room_id = p2p_chat_rooms.id
        AND p2p_chat_participants.user_id = auth.uid()::integer
    )
);

-- ============================================================
-- p2p_chat_participants RLS 정책
-- ============================================================
ALTER TABLE public.p2p_chat_participants ENABLE ROW LEVEL SECURITY;

-- 조회: 사용자는 자신이 참여한 채팅방의 참여자 목록만 조회 가능
CREATE POLICY "Users can view participants in their rooms"
ON public.p2p_chat_participants FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.p2p_chat_participants AS my_rooms
        WHERE my_rooms.room_id = p2p_chat_participants.room_id
        AND my_rooms.user_id = auth.uid()::integer
    )
);

-- 생성: 인증된 사용자는 참여자로 추가 가능
CREATE POLICY "Authenticated users can join chat rooms"
ON public.p2p_chat_participants FOR INSERT
WITH CHECK (auth.role() = 'authenticated');

-- 업데이트: 사용자는 자신의 참여자 정보만 업데이트 가능
CREATE POLICY "Users can update their own participant info"
ON public.p2p_chat_participants FOR UPDATE
USING (user_id = auth.uid()::integer);

-- ============================================================
-- p2p_chat_messages RLS 정책
-- ============================================================
ALTER TABLE public.p2p_chat_messages ENABLE ROW LEVEL SECURITY;

-- 조회: 사용자는 자신이 참여한 채팅방의 메시지만 조회 가능
CREATE POLICY "Users can view messages in their rooms"
ON public.p2p_chat_messages FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.p2p_chat_participants
        WHERE p2p_chat_participants.room_id = p2p_chat_messages.room_id
        AND p2p_chat_participants.user_id = auth.uid()::integer
    )
);

-- 생성: 사용자는 자신이 참여한 채팅방에만 메시지 전송 가능
CREATE POLICY "Users can send messages to their rooms"
ON public.p2p_chat_messages FOR INSERT
WITH CHECK (
    sender_id = auth.uid()::integer
    AND EXISTS (
        SELECT 1 FROM public.p2p_chat_participants
        WHERE p2p_chat_participants.room_id = p2p_chat_messages.room_id
        AND p2p_chat_participants.user_id = auth.uid()::integer
    )
);
```

---

## 3단계: Realtime 활성화

실시간 메시지 수신을 위해 Realtime을 활성화합니다.

### 방법 1: Supabase 대시보드에서 설정
1. Supabase 프로젝트 대시보드 접속
2. **Database** → **Replication** 메뉴 이동
3. 다음 3개 테이블에 대해 Realtime 활성화:
   - `p2p_chat_rooms`
   - `p2p_chat_participants`
   - `p2p_chat_messages`

### 방법 2: SQL로 직접 활성화
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE public.p2p_chat_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE public.p2p_chat_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.p2p_chat_messages;
```

---

## 설정 완료 확인

모든 설정이 완료되면 다음을 확인하세요:

1. **테이블 생성 확인**
   - Supabase Dashboard → Database → Tables에서 3개 테이블 확인

2. **RLS 정책 확인**
   - 각 테이블의 Policies 탭에서 정책 확인

3. **Realtime 활성화 확인**
   - Database → Replication에서 3개 테이블 활성화 상태 확인

---

## 프론트엔드 연동

백엔드 설정이 완료되면 Flutter 앱에서 바로 사용 가능합니다:

### 채팅 시작하기
1. 커뮤니티 게시글 상세 화면에서 **"문의하기"** 버튼 클릭
2. 자동으로 채팅방 생성 또는 기존 채팅방으로 이동
3. 실시간으로 메시지 송수신

### 채팅 목록 보기
- 메인 네비게이션에서 채팅 아이콘 탭
- 안 읽은 메시지 배지 표시
- 최근 대화 순으로 정렬

---

## 관련 파일

### 모델
- `lib/models/chat_models.dart`

### 서비스
- `lib/services/chat_service.dart`

### 화면
- `lib/screens/chat/chat_room_screen.dart` - 채팅방 화면
- `lib/screens/chat/chat_list_screen.dart` - 채팅 목록 화면

### 위젯
- `lib/widgets/chat/message_bubble.dart` - 메시지 말풍선

---

## 문제 해결

### 메시지가 실시간으로 수신되지 않는 경우
- Realtime이 활성화되어 있는지 확인
- Supabase 프로젝트 설정에서 Realtime quota 확인

### RLS 정책 오류가 발생하는 경우
- 사용자가 올바르게 인증되었는지 확인
- auth.uid()가 users 테이블의 id와 매칭되는지 확인

### 채팅방 생성이 실패하는 경우
- users 테이블에 해당 user_id가 존재하는지 확인
- RLS INSERT 정책이 올바르게 설정되었는지 확인
