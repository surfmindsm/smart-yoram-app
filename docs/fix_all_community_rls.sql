-- ⚠️ 긴급 수정: 모든 커뮤니티 테이블 RLS 정책 수정
-- Supabase SQL Editor에서 실행하세요

-- ============================================================
-- 방법 1: 개발용 - 모든 커뮤니티 테이블 RLS 비활성화
-- ============================================================

ALTER TABLE church_news DISABLE ROW LEVEL SECURITY;
ALTER TABLE community_sharing DISABLE ROW LEVEL SECURITY;
ALTER TABLE community_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE community_music_teams DISABLE ROW LEVEL SECURITY;
ALTER TABLE job_posts DISABLE ROW LEVEL SECURITY;
ALTER TABLE music_team_seekers DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- 실행 후 "Success. No rows returned" 메시지가 나와야 합니다
-- ============================================================

-- ============================================================
-- 방법 2: 프로덕션용 - 인증된 사용자에게 모든 권한 허용
-- (위 방법 1 대신 아래 방법을 사용하려면 주석 해제)
-- ============================================================

/*
-- church_news 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON church_news;
CREATE POLICY "Allow all for authenticated users"
ON church_news FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE church_news ENABLE ROW LEVEL SECURITY;

-- community_sharing 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON community_sharing;
CREATE POLICY "Allow all for authenticated users"
ON community_sharing FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE community_sharing ENABLE ROW LEVEL SECURITY;

-- community_requests 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON community_requests;
CREATE POLICY "Allow all for authenticated users"
ON community_requests FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE community_requests ENABLE ROW LEVEL SECURITY;

-- community_music_teams 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON community_music_teams;
CREATE POLICY "Allow all for authenticated users"
ON community_music_teams FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE community_music_teams ENABLE ROW LEVEL SECURITY;

-- job_posts 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON job_posts;
CREATE POLICY "Allow all for authenticated users"
ON job_posts FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE job_posts ENABLE ROW LEVEL SECURITY;

-- music_team_seekers 정책
DROP POLICY IF EXISTS "Allow all for authenticated users" ON music_team_seekers;
CREATE POLICY "Allow all for authenticated users"
ON music_team_seekers FOR ALL TO authenticated
USING (true) WITH CHECK (true);
ALTER TABLE music_team_seekers ENABLE ROW LEVEL SECURITY;
*/

-- ============================================================
-- 실행 후 Flutter 앱에서 모든 커뮤니티 기능 테스트하세요!
-- ============================================================
