-- ============================================
-- Notifications 테이블 재생성 스크립트
-- ============================================
-- 설명: 앱 내 알림 센터에서 사용할 알림 데이터 저장
-- 작성일: 2025-12-02
-- 수정일: 2025-12-02 (기존 테이블 삭제 후 재생성)
-- ============================================

-- 0. 기존 테이블 삭제 (구조 변경을 위해)
-- 주의: 기존 데이터가 모두 삭제됩니다!
DROP TABLE IF EXISTS public.notifications CASCADE;

-- 1. notifications 테이블 생성
CREATE TABLE public.notifications (
    id BIGSERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'notice', -- 'notice', 'chat', 'like', 'comment', 'important', 'schedule', 'attendance'
    is_read BOOLEAN DEFAULT false,
    related_id INTEGER, -- 관련 리소스 ID (게시글, 댓글 등)
    related_type TEXT, -- 관련 리소스 타입 (post, comment, chat 등)
    data JSONB, -- 추가 데이터 (JSON 형태)
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 코멘트 추가
COMMENT ON TABLE public.notifications IS '사용자 알림 저장 테이블';
COMMENT ON COLUMN public.notifications.id IS '알림 고유 ID';
COMMENT ON COLUMN public.notifications.user_id IS '알림을 받는 사용자 ID';
COMMENT ON COLUMN public.notifications.title IS '알림 제목';
COMMENT ON COLUMN public.notifications.body IS '알림 본문';
COMMENT ON COLUMN public.notifications.type IS '알림 타입 (notice, chat, like, comment, important, schedule, attendance)';
COMMENT ON COLUMN public.notifications.is_read IS '읽음 여부';
COMMENT ON COLUMN public.notifications.related_id IS '관련된 리소스의 ID (선택)';
COMMENT ON COLUMN public.notifications.related_type IS '관련된 리소스의 타입 (선택)';
COMMENT ON COLUMN public.notifications.data IS '추가 데이터 (JSON 형태)';
COMMENT ON COLUMN public.notifications.created_at IS '생성 일시';
COMMENT ON COLUMN public.notifications.updated_at IS '수정 일시';

-- 3. 인덱스 생성
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_type ON public.notifications(type);

-- 4. RLS (Row Level Security) 활성화
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성

-- 5-1. 본인 알림만 조회 가능
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications"
    ON public.notifications
    FOR SELECT
    USING (
        user_id = (
            SELECT id FROM public.users
            WHERE email = auth.jwt()->>'email'
        )
    );

-- 5-2. 본인 알림만 업데이트 가능 (읽음 처리 등)
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications"
    ON public.notifications
    FOR UPDATE
    USING (
        user_id = (
            SELECT id FROM public.users
            WHERE email = auth.jwt()->>'email'
        )
    );

-- 5-3. 시스템/관리자가 알림 생성 가능 (서비스 계정)
DROP POLICY IF EXISTS "Service can insert notifications" ON public.notifications;
CREATE POLICY "Service can insert notifications"
    ON public.notifications
    FOR INSERT
    WITH CHECK (true); -- Edge Function이나 트리거에서 생성 가능

-- 6. 알림 자동 생성 헬퍼 함수 (선택사항)
CREATE OR REPLACE FUNCTION public.create_notification(
    p_user_id INTEGER,
    p_title TEXT,
    p_body TEXT,
    p_type TEXT DEFAULT 'notice',
    p_related_id INTEGER DEFAULT NULL,
    p_related_type TEXT DEFAULT NULL,
    p_data JSONB DEFAULT NULL
)
RETURNS public.notifications AS $$
DECLARE
    v_notification public.notifications;
BEGIN
    INSERT INTO public.notifications (
        user_id, title, body, type, related_id, related_type, data
    ) VALUES (
        p_user_id, p_title, p_body, p_type, p_related_id, p_related_type, p_data
    )
    RETURNING * INTO v_notification;

    RETURN v_notification;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.create_notification IS '알림 생성 헬퍼 함수';

-- 7. 읽지 않은 알림 개수 조회 함수 (선택사항)
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(p_user_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)::INTEGER
        FROM public.notifications
        WHERE user_id = p_user_id
        AND is_read = false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.get_unread_notification_count IS '읽지 않은 알림 개수 조회';


