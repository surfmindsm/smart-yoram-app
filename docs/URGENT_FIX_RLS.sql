-- ⚠️ 긴급 수정: music_team_seekers RLS 정책 추가
-- Supabase SQL Editor에서 실행하세요

-- 방법 1: 가장 간단 - 모든 인증된 사용자에게 모든 권한 허용
DROP POLICY IF EXISTS "Allow all for authenticated users" ON music_team_seekers;

CREATE POLICY "Allow all for authenticated users"
ON music_team_seekers
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- RLS 활성화
ALTER TABLE music_team_seekers ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 위 방법이 안 되면 아래 방법 2 실행
-- ============================================================

-- 방법 2: 임시로 RLS 완전 비활성화 (개발용)
-- ALTER TABLE music_team_seekers DISABLE ROW LEVEL SECURITY;
