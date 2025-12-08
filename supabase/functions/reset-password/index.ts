// supabase/functions/reset-password/index.ts
// 비밀번호 재설정: 임시 비밀번호 생성 및 이메일 전송 (Resend 사용)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ResetPasswordRequest {
  email: string;
  phone: string;
}

// 임시 비밀번호 생성 (8자리: 영문 대소문자 + 숫자)
function generateTemporaryPassword(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'; // 혼동되기 쉬운 문자 제외 (0, O, 1, l, I)
  let password = '';
  for (let i = 0; i < 8; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

// Resend를 사용한 이메일 전송
async function sendEmailViaResend(
  resendApiKey: string,
  to: string,
  subject: string,
  html: string
): Promise<void> {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${resendApiKey}`,
    },
    body: JSON.stringify({
      from: 'ChurchRound <noreply@churchround.com>',
      to: [to],
      subject: subject,
      html: html,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error('❌ Resend 이메일 전송 실패:', error);
    throw new Error(`이메일 전송 실패: ${error}`);
  }

  const result = await response.json();
  console.log('✅ Resend 이메일 전송 성공:', result);
}

serve(async (req) => {
  // CORS preflight 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const resendApiKey = Deno.env.get('RESEND_API_KEY')!;

    if (!resendApiKey) {
      throw new Error('RESEND_API_KEY 환경변수가 설정되지 않았습니다');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 요청 본문 파싱
    const { email, phone }: ResetPasswordRequest = await req.json();

    if (!email || !phone) {
      return new Response(
        JSON.stringify({ success: false, message: '이메일과 전화번호를 모두 입력해주세요' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('📧 비밀번호 재설정 요청:', email, phone);

    // 1. users 테이블에서 이메일과 전화번호로 사용자 조회
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('id, email, phone, full_name, is_active')
      .eq('email', email)
      .eq('phone', phone)
      .maybeSingle();

    if (userError) {
      console.error('❌ 사용자 조회 오류:', userError);
      throw userError;
    }

    if (!user) {
      // 보안상 사용자가 존재하지 않아도 성공 메시지 반환 (이메일/전화번호 존재 여부 노출 방지)
      console.log('⚠️ 사용자가 존재하지 않음 (이메일 또는 전화번호 불일치) - 보안상 성공 메시지 반환');
      return new Response(
        JSON.stringify({
          success: true,
          message: '이메일과 전화번호가 일치한다면 임시 비밀번호가 전송됩니다.',
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (!user.is_active) {
      console.log('⚠️ 비활성화된 사용자 - 보안상 성공 메시지 반환');
      return new Response(
        JSON.stringify({
          success: true,
          message: '이메일과 전화번호가 일치한다면 임시 비밀번호가 전송됩니다.',
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`✅ 사용자 조회 성공: ${user.email} (ID: ${user.id})`);

    // 2. 임시 비밀번호 생성
    const temporaryPassword = generateTemporaryPassword();
    console.log(`🔑 임시 비밀번호 생성: ${temporaryPassword}`);

    // 3. users 테이블 업데이트 (임시 비밀번호 설정 & is_first = true)
    const { error: updateError } = await supabase
      .from('users')
      .update({
        hashed_password: temporaryPassword, // 단순 문자열 저장 (현재 시스템과 동일)
        is_first: true, // 첫 로그인으로 처리 (비밀번호 변경 다이얼로그 표시)
        updated_at: new Date().toISOString(),
      })
      .eq('id', user.id);

    if (updateError) {
      console.error('❌ 비밀번호 업데이트 오류:', updateError);
      throw updateError;
    }

    console.log('✅ 임시 비밀번호 설정 완료 (is_first=true)');

    // 4. Resend를 통해 이메일 전송
    const userName = user.full_name || '사용자';
    const emailHtml = `
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>임시 비밀번호 안내</title>
</head>
<body style="margin: 0; padding: 0; font-family: 'Apple SD Gothic Neo', 'Malgun Gothic', sans-serif; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">ChurchRound</h1>
      <p style="color: rgba(255, 255, 255, 0.9); margin: 10px 0 0 0; font-size: 16px;">교회 생활의 새로운 시작</p>
    </div>

    <!-- Body -->
    <div style="padding: 40px 30px;">
      <h2 style="color: #333333; margin: 0 0 20px 0; font-size: 24px; font-weight: 600;">임시 비밀번호 안내</h2>

      <p style="color: #666666; line-height: 1.6; margin: 0 0 20px 0;">
        안녕하세요, <strong>${userName}</strong>님!
      </p>

      <p style="color: #666666; line-height: 1.6; margin: 0 0 30px 0;">
        등록하신 이메일과 전화번호로 본인 확인이 완료되어 임시 비밀번호를 발급해드립니다.<br>
        아래 임시 비밀번호로 로그인하신 후, 반드시 새로운 비밀번호로 변경해주세요.
      </p>

      <!-- 임시 비밀번호 박스 -->
      <div style="background-color: #f8f9fa; border-left: 4px solid #667eea; padding: 20px; margin: 0 0 30px 0; border-radius: 4px;">
        <p style="color: #666666; margin: 0 0 10px 0; font-size: 14px;">임시 비밀번호</p>
        <p style="color: #333333; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 2px; font-family: 'Courier New', monospace;">
          ${temporaryPassword}
        </p>
      </div>

      <!-- 안내 사항 -->
      <div style="background-color: #fff3cd; border: 1px solid #ffc107; border-radius: 6px; padding: 16px; margin: 0 0 30px 0;">
        <p style="color: #856404; margin: 0; font-size: 14px; line-height: 1.5;">
          <strong>⚠️ 보안 안내</strong><br>
          • 로그인 후 비밀번호를 반드시 변경해주세요<br>
          • 이 이메일은 재전송되지 않으니 안전하게 보관해주세요<br>
          • 비밀번호 재설정을 요청하지 않으셨다면, 즉시 관리자에게 연락해주세요
        </p>
      </div>

      <!-- CTA 버튼 -->
      <div style="text-align: center; margin: 30px 0;">
        <a href="https://churchround.com"
           style="display: inline-block; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; padding: 14px 40px; border-radius: 8px; font-weight: 600; font-size: 16px;">
          앱으로 이동하기
        </a>
      </div>
    </div>

    <!-- Footer -->
    <div style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #e9ecef;">
      <p style="color: #999999; margin: 0; font-size: 12px; line-height: 1.5; text-align: center;">
        이 이메일은 ChurchRound 비밀번호 재설정 요청에 따라 자동으로 발송되었습니다.<br>
        문의사항이 있으시면 <a href="mailto:support@churchround.com" style="color: #667eea; text-decoration: none;">support@churchround.com</a>으로 연락해주세요.
      </p>
    </div>
  </div>
</body>
</html>
    `;

    await sendEmailViaResend(
      resendApiKey,
      email,
      '[ChurchRound] 임시 비밀번호 안내',
      emailHtml
    );

    console.log('✅ 비밀번호 재설정 완료');

    return new Response(
      JSON.stringify({
        success: true,
        message: '임시 비밀번호가 이메일로 전송되었습니다. 로그인 후 비밀번호를 변경해주세요.',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('❌ Edge Function 실행 오류:', error);
    return new Response(
      JSON.stringify({
        success: false,
        message: '비밀번호 재설정 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        error: error.message
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
