-- 신고 테이블 생성
CREATE TABLE IF NOT EXISTS public.reports (
  id BIGSERIAL PRIMARY KEY,
  reporter_id INTEGER NOT NULL, -- 신고자 ID
  reported_type VARCHAR(50) NOT NULL, -- 신고 대상 타입 ('post', 'chat', 'user')
  reported_id INTEGER NOT NULL, -- 신고 대상 ID (게시글 ID, 채팅방 ID, 유저 ID 등)
  reported_table VARCHAR(100), -- 신고 대상 테이블명 (community_sharing, chat_rooms 등)
  reason VARCHAR(50) NOT NULL, -- 신고 사유 ('spam', 'inappropriate', 'fraud', 'harassment', 'etc')
  description TEXT, -- 신고 상세 내용
  status VARCHAR(20) DEFAULT 'pending', -- 처리 상태 ('pending', 'reviewing', 'resolved', 'rejected')
  admin_note TEXT, -- 관리자 메모
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by INTEGER -- 처리한 관리자 ID
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON public.reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_type ON public.reports(reported_type);
CREATE INDEX IF NOT EXISTS idx_reports_reported_id ON public.reports(reported_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON public.reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON public.reports(created_at DESC);

-- RLS 활성화
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- 정책: 모든 로그인 사용자는 신고 가능 (자신의 신고만 조회)
CREATE POLICY "Users can insert their own reports"
  ON public.reports
  FOR INSERT
  WITH CHECK (auth.uid()::text::integer = reporter_id);

CREATE POLICY "Users can view their own reports"
  ON public.reports
  FOR SELECT
  USING (auth.uid()::text::integer = reporter_id);

-- 정책: 관리자는 모든 신고 조회/수정 가능 (추후 권한 테이블과 연동 필요)
-- 현재는 모든 신고를 볼 수 있는 정책은 제외 (관리자 기능 추가 시 구현)

COMMENT ON TABLE public.reports IS '신고 테이블';
COMMENT ON COLUMN public.reports.reporter_id IS '신고자 ID';
COMMENT ON COLUMN public.reports.reported_type IS '신고 대상 타입 (post, chat, user)';
COMMENT ON COLUMN public.reports.reported_id IS '신고 대상 ID';
COMMENT ON COLUMN public.reports.reported_table IS '신고 대상 테이블명';
COMMENT ON COLUMN public.reports.reason IS '신고 사유 (spam, inappropriate, fraud, harassment, etc)';
COMMENT ON COLUMN public.reports.description IS '신고 상세 내용';
COMMENT ON COLUMN public.reports.status IS '처리 상태 (pending, reviewing, resolved, rejected)';
COMMENT ON COLUMN public.reports.admin_note IS '관리자 메모';
COMMENT ON COLUMN public.reports.resolved_at IS '처리 완료 시간';
COMMENT ON COLUMN public.reports.resolved_by IS '처리한 관리자 ID';
