-- 앱 버전 관리 테이블
-- 강제 업데이트와 소프트 업데이트를 위한 버전 정보 관리

CREATE TABLE IF NOT EXISTS app_versions (
  id BIGSERIAL PRIMARY KEY,
  platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android')),
  min_version VARCHAR(20) NOT NULL, -- 최소 지원 버전 (이보다 낮으면 강제 업데이트)
  latest_version VARCHAR(20) NOT NULL, -- 최신 버전 (소프트 업데이트 알림)
  store_url TEXT NOT NULL, -- App Store / Play Store URL
  update_message TEXT, -- 업데이트 안내 메시지
  force_update_message TEXT, -- 강제 업데이트 메시지
  is_active BOOLEAN DEFAULT true, -- 활성화 여부
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(platform, is_active)
);

-- 플랫폼별로 하나의 활성 버전만 존재하도록 제약
CREATE UNIQUE INDEX idx_app_versions_active_platform
ON app_versions(platform) WHERE is_active = true;

-- 업데이트 트리거
CREATE OR REPLACE FUNCTION update_app_versions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER app_versions_updated_at
BEFORE UPDATE ON app_versions
FOR EACH ROW
EXECUTE FUNCTION update_app_versions_updated_at();

-- 초기 데이터 삽입 (예시)
INSERT INTO app_versions (platform, min_version, latest_version, store_url, update_message, force_update_message)
VALUES
  (
    'android',
    '1.0.0',
    '1.0.1',
    'https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME',
    '새로운 버전이 출시되었습니다. 업데이트하시겠습니까?',
    '필수 업데이트가 있습니다. 계속 사용하려면 앱을 업데이트해주세요.'
  ),
  (
    'ios',
    '1.0.0',
    '1.0.1',
    'https://apps.apple.com/app/idYOUR_APP_ID',
    '새로운 버전이 출시되었습니다. 업데이트하시겠습니까?',
    '필수 업데이트가 있습니다. 계속 사용하려면 앱을 업데이트해주세요.'
  )
ON CONFLICT (platform) WHERE is_active = true
DO UPDATE SET
  min_version = EXCLUDED.min_version,
  latest_version = EXCLUDED.latest_version,
  store_url = EXCLUDED.store_url,
  update_message = EXCLUDED.update_message,
  force_update_message = EXCLUDED.force_update_message,
  updated_at = NOW();

-- Row Level Security 설정
ALTER TABLE app_versions ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 읽기 가능
CREATE POLICY "Anyone can read app versions"
ON app_versions FOR SELECT
TO public
USING (is_active = true);

-- 관리자만 수정 가능 (anon 키로는 수정 불가)
CREATE POLICY "Only admins can modify app versions"
ON app_versions FOR ALL
TO authenticated
USING (auth.jwt() ->> 'role' = 'admin');
