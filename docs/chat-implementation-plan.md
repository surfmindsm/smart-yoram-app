# 채팅 기능 구현 계획

## 개요
커뮤니티 게시글 상세 화면에서 게시글 작성자와 1:1 채팅을 할 수 있는 기능 구현

## 기술 스택

### 백엔드 (Supabase)
- **Realtime**: Supabase Realtime을 사용한 실시간 메시지 전송/수신
- **Database Tables**:
  - `chat_rooms`: 채팅방 정보
  - `chat_messages`: 채팅 메시지
  - `chat_participants`: 채팅 참여자

### 프론트엔드 (Flutter)
- **supabase_flutter**: Supabase 연동
- **flutter_chat_ui** 또는 직접 구현: 채팅 UI

## 데이터베이스 스키마

### 1. chat_rooms 테이블
```sql
CREATE TABLE chat_rooms (
  id BIGSERIAL PRIMARY KEY,
  post_id INT,                    -- 관련 게시글 ID (nullable)
  post_table VARCHAR(100),        -- 게시글 테이블명 (nullable)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_message_at TIMESTAMP,
  last_message TEXT
);
```

### 2. chat_participants 테이블
```sql
CREATE TABLE chat_participants (
  id BIGSERIAL PRIMARY KEY,
  room_id BIGINT REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP DEFAULT NOW(),
  last_read_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(room_id, user_id)
);
```

### 3. chat_messages 테이블
```sql
CREATE TABLE chat_messages (
  id BIGSERIAL PRIMARY KEY,
  room_id BIGINT REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id INT REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  message_type VARCHAR(20) DEFAULT 'text',  -- text, image, file
  image_url TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE
);
```

## 주요 기능

### 1. 채팅방 생성/조회
- 게시글 상세 화면에서 "문의하기" 버튼 클릭
- 해당 게시글과 작성자 간 채팅방이 이미 존재하는지 확인
- 존재하지 않으면 새 채팅방 생성
- 존재하면 기존 채팅방으로 이동

### 2. 실시간 메시지 송수신
```dart
// Realtime 구독
final subscription = supabase
  .from('chat_messages')
  .stream(primaryKey: ['id'])
  .eq('room_id', roomId)
  .listen((messages) {
    // 메시지 업데이트 처리
  });

// 메시지 전송
await supabase.from('chat_messages').insert({
  'room_id': roomId,
  'sender_id': currentUserId,
  'message': messageText,
  'message_type': 'text',
});
```

### 3. 읽음 처리
- 채팅방 진입 시 `last_read_at` 업데이트
- 안 읽은 메시지 개수 계산 및 표시

### 4. 채팅 목록 화면
- 사용자의 모든 채팅방 목록 표시
- 마지막 메시지, 시간, 안 읽은 메시지 개수 표시
- 최근 메시지 순으로 정렬

## 구현 단계

### Phase 1: 데이터베이스 설정
1. Supabase에 테이블 생성
2. RLS (Row Level Security) 정책 설정
3. Realtime 활성화

### Phase 2: 서비스 레이어 구현
1. `ChatService` 클래스 생성
   - `createOrGetChatRoom()`: 채팅방 생성/조회
   - `sendMessage()`: 메시지 전송
   - `getChatRooms()`: 채팅방 목록 조회
   - `getMessages()`: 메시지 조회
   - `subscribeToMessages()`: 실시간 메시지 구독
   - `markAsRead()`: 읽음 처리

### Phase 3: UI 구현
1. **ChatListScreen**: 채팅 목록 화면
2. **ChatRoomScreen**: 채팅방 화면
3. **MessageBubble**: 메시지 말풍선 위젯

### Phase 4: 통합
1. 커뮤니티 상세 화면에 "문의하기" 버튼 연결
2. 설정 화면에 "채팅" 메뉴 추가
3. 푸시 알림 연동 (새 메시지 알림)

## 보안 고려사항

### RLS 정책 예시
```sql
-- 채팅방 참여자만 메시지 조회 가능
CREATE POLICY "Users can view messages in their rooms"
ON chat_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM chat_participants
    WHERE room_id = chat_messages.room_id
    AND user_id = auth.uid()
  )
);

-- 채팅방 참여자만 메시지 전송 가능
CREATE POLICY "Users can send messages to their rooms"
ON chat_messages FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM chat_participants
    WHERE room_id = chat_messages.room_id
    AND user_id = auth.uid()
  )
);
```

## 성능 최적화

1. **메시지 페이지네이션**:
   - 최근 50개 메시지만 로드
   - 스크롤 시 이전 메시지 로드

2. **이미지 최적화**:
   - 썸네일 생성
   - 압축 업로드

3. **캐싱**:
   - 채팅방 목록 로컬 캐싱
   - 오프라인 지원 (선택사항)

## 향후 개선사항

1. 이미지/파일 전송
2. 읽음 확인 (체크 표시)
3. 타이핑 중 표시
4. 메시지 검색
5. 채팅방 나가기/삭제
6. 블록 기능
7. 단체 채팅 (선택사항)

## 예상 구현 시간

- Phase 1 (DB 설정): 1-2시간
- Phase 2 (서비스 레이어): 3-4시간
- Phase 3 (UI 구현): 4-6시간
- Phase 4 (통합 및 테스트): 2-3시간

**총 예상 시간**: 10-15시간

## 참고 자료

- [Supabase Realtime 문서](https://supabase.com/docs/guides/realtime)
- [Flutter Chat UI 패키지](https://pub.dev/packages/flutter_chat_ui)
- [Supabase Flutter 채팅 예제](https://github.com/supabase/supabase/tree/master/examples/slack-clone/flutter)
