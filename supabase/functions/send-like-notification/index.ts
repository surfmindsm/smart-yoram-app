// supabase/functions/send-like-notification/index.ts
// FCM v1 API를 사용한 좋아요 알림 전송

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v5.2.0/index.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface NotificationPayload {
  author_id: number;
  liker_id: number;
  liker_name: string;
  post_title: string;
  post_id: number;
  table_name: string;
  category_title: string;
}

// OAuth2 액세스 토큰 생성 (FCM v1 API용)
async function getAccessToken(serviceAccountJson: string): Promise<string> {
  try {
    const serviceAccount = JSON.parse(serviceAccountJson);

    // JWT 생성을 위한 클레임
    const now = Math.floor(Date.now() / 1000);

    // Private Key를 jose의 importPKCS8로 import
    const privateKey = await importPKCS8(serviceAccount.private_key, 'RS256');

    // JWT 생성 (jose의 SignJWT 사용)
    const jwt = await new SignJWT({
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
    })
      .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
      .setIssuer(serviceAccount.client_email)
      .setAudience('https://oauth2.googleapis.com/token')
      .setIssuedAt(now)
      .setExpirationTime(now + 3600) // 1시간 유효
      .sign(privateKey);

    console.log('🔐 JWT 생성 완료');

    // OAuth2 토큰 요청
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text();
      console.error('❌ OAuth2 토큰 요청 실패:', error);
      throw new Error(`OAuth2 토큰 요청 실패: ${error}`);
    }

    const tokenData = await tokenResponse.json();
    console.log('🔑 OAuth2 액세스 토큰 생성 완료');
    return tokenData.access_token;
  } catch (error) {
    console.error('❌ 액세스 토큰 생성 실패:', error);
    throw error;
  }
}

serve(async (req) => {
  // CORS preflight 처리
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const serviceAccountJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')!;
    const projectId = Deno.env.get('FIREBASE_PROJECT_ID') || 'smart-yoram';

    if (!serviceAccountJson) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT 환경변수가 설정되지 않았습니다');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 요청 본문 파싱
    const payload: NotificationPayload = await req.json();
    const { author_id, liker_id, liker_name, post_title, post_id, table_name, category_title } = payload;

    console.log('💗 좋아요 알림 발송:', {
      authorId: author_id,
      likerId: liker_id,
      likerName: liker_name,
      postTitle: post_title,
    });

    // 1. 작성자의 FCM 토큰 조회
    const { data: devices, error: devicesError } = await supabase
      .from('device_tokens')
      .select('fcm_token, platform')
      .eq('user_id', author_id)
      .eq('is_active', true);

    if (devicesError) {
      console.error('❌ FCM 토큰 조회 실패:', devicesError);
      throw devicesError;
    }

    if (!devices || devices.length === 0) {
      console.log('⚠️ 작성자의 FCM 토큰이 없습니다 (user_id:', author_id, ')');
      return new Response(
        JSON.stringify({ success: true, message: '수신자 토큰 없음' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`📱 FCM 토큰 조회 완료: ${devices.length}개`);

    // 2. OAuth2 액세스 토큰 생성
    const accessToken = await getAccessToken(serviceAccountJson);
    console.log('🔑 OAuth2 액세스 토큰 생성 완료');

    // 3. 각 디바이스에 FCM v1 API로 알림 발송
    const notifications = [];

    for (const device of devices) {
      // FCM v1 API Payload
      const fcmPayload = {
        message: {
          token: device.fcm_token,
          notification: {
            title: '새 좋아요',
            body: `${liker_name}님이 회원님의 게시글을 좋아합니다 - ${post_title}`,
          },
          data: {
            type: 'community_like',
            notification_type: 'custom',
            post_id: post_id.toString(),
            table_name: table_name,
            category_title: category_title,
            liker_id: liker_id.toString(),
            liker_name: liker_name,
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
          // 플랫폼별 설정
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channel_id: 'custom_channel',
            },
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        },
      };

      console.log(`🚀 FCM v1 알림 발송 시도 (user_id: ${author_id}, platform: ${device.platform})`);

      // FCM v1 API 호출
      const fcmResponse = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify(fcmPayload),
        }
      );

      const fcmResult = await fcmResponse.json();

      if (fcmResponse.ok) {
        console.log(`✅ FCM 알림 발송 성공 (user_id: ${author_id}, platform: ${device.platform})`);
        notifications.push({
          userId: author_id,
          platform: device.platform,
          success: true,
        });

        // 🆕 Supabase notifications 테이블에 저장
        try {
          await supabase.from('notifications').insert({
            user_id: author_id,
            title: '새 좋아요',
            body: `${liker_name}님이 회원님의 게시글을 좋아합니다 - ${post_title}`,
            type: 'community_like',
            is_read: false,
            related_id: post_id,
            related_type: table_name,
            data: {
              liker_id: liker_id,
              liker_name: liker_name,
              post_title: post_title,
              category_title: category_title,
            },
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          });
          console.log(`💾 좋아요 알림 저장 완료 (user_id: ${author_id})`);
        } catch (saveError) {
          console.error(`⚠️ 알림 저장 실패 (user_id: ${author_id}):`, saveError);
          // 저장 실패해도 FCM은 발송되었으므로 계속 진행
        }
      } else {
        console.error(`❌ FCM 알림 발송 실패 (user_id: ${author_id}):`, fcmResult);
        notifications.push({
          userId: author_id,
          platform: device.platform,
          success: false,
          error: fcmResult,
        });
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `${notifications.length}개 디바이스에 알림 발송`,
        notifications,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('❌ Edge Function 실행 오류:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
