-- ⚠️ 긴급 수정: church_news RLS 정책 추가
-- Supabase SQL Editor에서 실행하세요

-- ============================================================
-- 방법 1: 가장 간단 - 모든 인증된 사용자에게 모든 권한 허용 (개발용)
-- ============================================================

-- 기존 정책 삭제
DROP POLICY IF EXISTS "Allow all for authenticated users" ON church_news;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON church_news;
DROP POLICY IF EXISTS "Enable select for authenticated users" ON church_news;
DROP POLICY IF EXISTS "Enable update for authors" ON church_news;
DROP POLICY IF EXISTS "Enable delete for authors" ON church_news;

-- 새로운 통합 정책 생성
CREATE POLICY "Allow all for authenticated users"
ON church_news
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- RLS 활성화
ALTER TABLE church_news ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 위 방법이 안 되면 아래 방법 2 실행 (임시)
-- ============================================================

-- 방법 2: 임시로 RLS 완전 비활성화 (개발용)
-- ALTER TABLE church_news DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- 실행 후 Flutter 앱에서 교회 소식 작성 테스트하세요!
-- ============================================================
