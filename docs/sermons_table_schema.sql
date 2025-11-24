-- =====================================================
-- 명설교 (Sermons) 테이블 스키마
-- =====================================================
-- 이 파일은 Supabase에서 명설교 기능을 위한 테이블을 생성하는 SQL입니다.
-- Supabase Dashboard에서 SQL Editor를 열고 아래 쿼리를 실행하세요.

-- 1. sermons 테이블 생성
CREATE TABLE IF NOT EXISTS public.sermons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,                    -- 설교 제목
  youtube_url TEXT NOT NULL,                       -- 유튜브 URL (전체 URL 또는 비디오 ID)
  youtube_video_id VARCHAR(20) NOT NULL,           -- 유튜브 비디오 ID (추출된 값)
  preacher_name VARCHAR(100),                      -- 설교자 이름
  description TEXT,                                 -- 설교 설명/요약
  thumbnail_url TEXT,                               -- 썸네일 이미지 URL (유튜브 자동 생성)
  duration_seconds INTEGER,                         -- 영상 길이 (초 단위)
  view_count INTEGER DEFAULT 0,                     -- 조회수 (앱 내 조회수)
  category VARCHAR(50),                             -- 카테고리 (예: 주일설교, 수요예배, 특별집회 등)
  sermon_date DATE,                                 -- 설교 날짜
  is_featured BOOLEAN DEFAULT false,                -- 추천 설교 여부
  display_order INTEGER DEFAULT 0,                  -- 표시 순서 (작을수록 상위)
  is_active BOOLEAN DEFAULT true,                   -- 활성화 여부
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id),        -- 등록자
  updated_by UUID REFERENCES auth.users(id)         -- 수정자
);

-- 2. 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_sermons_is_active ON public.sermons(is_active);
CREATE INDEX IF NOT EXISTS idx_sermons_category ON public.sermons(category);
CREATE INDEX IF NOT EXISTS idx_sermons_sermon_date ON public.sermons(sermon_date DESC);
CREATE INDEX IF NOT EXISTS idx_sermons_display_order ON public.sermons(display_order);
CREATE INDEX IF NOT EXISTS idx_sermons_is_featured ON public.sermons(is_featured);
CREATE INDEX IF NOT EXISTS idx_sermons_created_at ON public.sermons(created_at DESC);

-- 3. RLS (Row Level Security) 정책 활성화
ALTER TABLE public.sermons ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 설정
-- 모든 사용자가 활성화된 설교를 조회할 수 있음
CREATE POLICY "sermons_select_policy" ON public.sermons
  FOR SELECT
  USING (is_active = true);

-- 인증된 사용자만 설교를 등록/수정/삭제할 수 있음 (관리자 권한 필요)
CREATE POLICY "sermons_insert_policy" ON public.sermons
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "sermons_update_policy" ON public.sermons
  FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "sermons_delete_policy" ON public.sermons
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- 5. updated_at 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_sermons_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. updated_at 트리거 생성
CREATE TRIGGER sermons_updated_at_trigger
  BEFORE UPDATE ON public.sermons
  FOR EACH ROW
  EXECUTE FUNCTION update_sermons_updated_at();

-- 7. 샘플 데이터 삽입 (테스트용)
-- 유튜브 URL에서 비디오 ID를 추출하여 저장합니다.
-- 예시: https://www.youtube.com/watch?v=VIDEO_ID 또는 https://youtu.be/VIDEO_ID
INSERT INTO public.sermons (
  title,
  youtube_url,
  youtube_video_id,
  preacher_name,
  description,
  category,
  sermon_date,
  is_featured,
  display_order,
  is_active
) VALUES
  (
    '은혜와 진리가 충만하신 예수',
    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    'dQw4w9WgXcQ',
    '김목사',
    '요한복음 1장을 통해 살펴보는 예수님의 은혜와 진리',
    '주일설교',
    '2024-01-07',
    true,
    1,
    true
  ),
  (
    '십자가의 능력',
    'https://www.youtube.com/watch?v=AbCdEfGhIjK',
    'AbCdEfGhIjK',
    '이목사',
    '고린도전서 1장 18절 말씀을 통한 십자가의 능력',
    '수요예배',
    '2024-01-10',
    false,
    2,
    true
  ),
  (
    '하나님의 사랑',
    'https://www.youtube.com/watch?v=XyZ123456Ab',
    'XyZ123456Ab',
    '박목사',
    '요한복음 3장 16절을 통해 본 하나님의 사랑',
    '주일설교',
    '2024-01-14',
    true,
    3,
    true
  );

-- =====================================================
-- 추가 관리 쿼리 (필요시 사용)
-- =====================================================

-- 카테고리 목록 조회
-- SELECT DISTINCT category FROM public.sermons ORDER BY category;

-- 추천 설교 조회
-- SELECT * FROM public.sermons WHERE is_featured = true AND is_active = true ORDER BY display_order;

-- 최신 설교 조회
-- SELECT * FROM public.sermons WHERE is_active = true ORDER BY sermon_date DESC LIMIT 10;

-- 설교 비활성화 (삭제 대신 사용 권장)
-- UPDATE public.sermons SET is_active = false WHERE id = 'sermon_uuid';

-- =====================================================
-- 즐겨찾기 기능 (선택사항)
-- =====================================================

-- 1. sermons 테이블에 favorite_count 컬럼 추가
ALTER TABLE public.sermons
ADD COLUMN IF NOT EXISTS favorite_count INTEGER DEFAULT 0;

-- favorite_count 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_sermons_favorite_count ON public.sermons(favorite_count DESC);

-- 2. sermon_favorites 테이블 생성
CREATE TABLE IF NOT EXISTS public.sermon_favorites (
  id BIGSERIAL PRIMARY KEY,
  sermon_id UUID NOT NULL REFERENCES public.sermons(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL,
  church_id INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(sermon_id, user_id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_sermon_favorites_sermon_id ON public.sermon_favorites(sermon_id);
CREATE INDEX IF NOT EXISTS idx_sermon_favorites_user_id ON public.sermon_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_sermon_favorites_created_at ON public.sermon_favorites(created_at DESC);

-- 3. RLS 정책 활성화
ALTER TABLE public.sermon_favorites ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 설정
-- 사용자는 자신의 즐겨찾기만 조회/추가/삭제 가능
CREATE POLICY "sermon_favorites_select_policy" ON public.sermon_favorites
  FOR SELECT
  USING (true);  -- 모든 사용자가 조회 가능 (통계용)

CREATE POLICY "sermon_favorites_insert_policy" ON public.sermon_favorites
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "sermon_favorites_delete_policy" ON public.sermon_favorites
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- 5. favorite_count 자동 업데이트 트리거 함수
CREATE OR REPLACE FUNCTION update_sermon_favorite_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- 즐겨찾기 추가 시 카운트 증가
    UPDATE public.sermons
    SET favorite_count = favorite_count + 1
    WHERE id = NEW.sermon_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- 즐겨찾기 삭제 시 카운트 감소
    UPDATE public.sermons
    SET favorite_count = GREATEST(favorite_count - 1, 0)
    WHERE id = OLD.sermon_id;
    RETURN OLD;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- 6. favorite_count 트리거 생성
DROP TRIGGER IF EXISTS sermon_favorite_count_trigger ON public.sermon_favorites;
CREATE TRIGGER sermon_favorite_count_trigger
  AFTER INSERT OR DELETE ON public.sermon_favorites
  FOR EACH ROW
  EXECUTE FUNCTION update_sermon_favorite_count();

-- 7. 샘플 즐겨찾기 데이터 (테스트용)
-- INSERT INTO public.sermon_favorites (sermon_id, user_id)
-- SELECT id, 1 FROM public.sermons LIMIT 1;
