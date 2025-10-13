-- 테스터 계정 및 10번 교회 생성 SQL
-- 실행 전 주의사항:
-- 1. Supabase Dashboard의 SQL Editor에서 실행하세요
-- 2. auth.users 테이블에 직접 삽입이 불가능할 수 있으므로, Supabase Auth UI를 통해 계정을 먼저 생성하는 것을 권장합니다
-- 3. 이 스크립트는 이미 생성된 auth 계정의 UUID를 사용한다고 가정합니다

-- Step 1: 먼저 Supabase Dashboard > Authentication에서 수동으로 계정을 생성하거나
-- 앱의 회원가입 기능을 통해 tester1@test.com / test123!@# 계정을 생성하세요

-- Step 2: 생성된 사용자의 UUID를 확인합니다
-- SELECT id FROM auth.users WHERE email = 'tester1@test.com';

-- Step 3: 아래 스크립트에서 'YOUR_AUTH_USER_UUID'를 실제 UUID로 교체하세요

-- 10번 교회 생성
INSERT INTO public.churches (
    id,
    name,
    address,
    phone,
    pastor_name,
    denomination,
    description,
    website,
    established_date,
    is_active,
    created_at,
    updated_at
) VALUES (
    10,
    '테스트교회',
    '서울특별시 강남구 테헤란로 123',
    '02-1234-5678',
    '테스트목사',
    '대한예수교장로회',
    '앱 마켓 심사를 위한 테스트 교회입니다.',
    'https://test-church.example.com',
    '2024-01-01',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    phone = EXCLUDED.phone,
    pastor_name = EXCLUDED.pastor_name,
    updated_at = NOW();

-- 테스터 멤버 생성
-- 주의: auth.users에서 tester1@test.com의 UUID를 확인한 후 아래 'YOUR_AUTH_USER_UUID'를 교체하세요
INSERT INTO public.members (
    church_id,
    user_id,  -- auth.users의 UUID
    name,
    email,
    phone,
    birth_date,
    gender,
    address,
    address_detail,
    join_date,
    member_type,
    is_active,
    created_at,
    updated_at
) VALUES (
    10,  -- 10번 교회
    'YOUR_AUTH_USER_UUID',  -- 이 부분을 실제 UUID로 교체하세요
    '테스터1',
    'tester1@test.com',
    '010-1234-5678',
    '1990-01-01',
    'male',
    '서울특별시 강남구 테헤란로 123',
    '101동 101호',
    CURRENT_DATE,
    'regular',
    true,
    NOW(),
    NOW()
)
ON CONFLICT (email) DO UPDATE SET
    church_id = EXCLUDED.church_id,
    name = EXCLUDED.name,
    updated_at = NOW();

-- 확인 쿼리
SELECT
    c.id as church_id,
    c.name as church_name,
    m.id as member_id,
    m.name as member_name,
    m.email,
    m.phone
FROM public.churches c
LEFT JOIN public.members m ON m.church_id = c.id
WHERE c.id = 10;
