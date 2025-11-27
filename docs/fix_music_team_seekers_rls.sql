-- music_team_seekers 테이블의 RLS 정책 수정
-- Supabase SQL Editor에서 실행하세요

-- ============================================================
-- 방법 1: 임시로 RLS 비활성화 (개발 중에만 사용)
-- ============================================================
-- ALTER TABLE music_team_seekers DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- 방법 2: 간단한 RLS 정책 (모든 인증된 사용자가 INSERT 가능)
-- ============================================================

-- 1. 기존 정책 확인 (선택 사항)
-- SELECT * FROM pg_policies WHERE tablename = 'music_team_seekers';

-- 2. 기존 정책 모두 삭제
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON music_team_seekers;
DROP POLICY IF EXISTS "Users can insert their own posts" ON music_team_seekers;
DROP POLICY IF EXISTS "Allow authenticated users to insert" ON music_team_seekers;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON music_team_seekers;
DROP POLICY IF EXISTS "Enable update for users based on author_id" ON music_team_seekers;
DROP POLICY IF EXISTS "Enable delete for users based on author_id" ON music_team_seekers;

-- 3. 새로운 정책 생성 (간단한 버전 - 모든 인증된 사용자 허용)
CREATE POLICY "Allow all for authenticated users"
ON music_team_seekers
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. RLS 활성화
ALTER TABLE music_team_seekers ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 방법 3: users 테이블과 매핑하는 RLS 정책 (권장)
-- ============================================================
-- 이 방법은 users 테이블에 auth_id (uuid) 컬럼이 있다고 가정합니다
/*
DROP POLICY IF EXISTS "Allow all for authenticated users" ON music_team_seekers;

CREATE POLICY "Enable insert for authenticated users"
ON music_team_seekers
FOR INSERT
TO authenticated
WITH CHECK (
  author_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

CREATE POLICY "Enable select for authenticated users"
ON music_team_seekers
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Enable update for authors"
ON music_team_seekers
FOR UPDATE
TO authenticated
USING (
  author_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
)
WITH CHECK (
  author_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);

CREATE POLICY "Enable delete for authors"
ON music_team_seekers
FOR DELETE
TO authenticated
USING (
  author_id IN (
    SELECT id FROM users WHERE auth_id = auth.uid()
  )
);
*/
