// supabase/functions/send-chat-notification/index.ts
// FCM v1 API 사용 (Legacy API는 2024년 6월 종료됨)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0';
import { SignJWT, importPKCS8 } from 'https://deno.land/x/jose@v5.2.0/index.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChatMessage {
  id: number;
  room_id: number;
  sender_id: number;
  sender_name: string;
  message: string;
  message_type: string;
  created_at: string;
}

interface NotificationPayload {
  message: ChatMessage;
  room_info?: {
    post_title?: string;
    other_user_name?: string;
  };
}

// OAuth2 액세스 토큰 생성 (FCM v1 API용) - jose 라이브러리 사용
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
    const { message, room_info } = payload;

    console.log('📩 새 채팅 메시지 알림 발송:', {
      messageId: message.id,
      roomId: message.room_id,
      senderId: message.sender_id,
    });

    // 1. 채팅방 참여자 조회 (발신자 제외)
    const { data: participants, error: participantsError } = await supabase
      .from('p2p_chat_participants')
      .select('user_id, user_name')
      .eq('room_id', message.room_id)
      .neq('user_id', message.sender_id);

    if (participantsError) {
      console.error('❌ 참여자 조회 실패:', participantsError);
      throw participantsError;
    }

    if (!participants || participants.length === 0) {
      console.log('⚠️ 알림 수신자가 없습니다 (발신자 본인만 있음)');
      return new Response(
        JSON.stringify({ success: true, message: '수신자 없음' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`👥 수신자 조회 완료: ${participants.length}명`);

    // 2. OAuth2 액세스 토큰 생성
    const accessToken = await getAccessToken(serviceAccountJson);
    console.log('🔑 OAuth2 액세스 토큰 생성 완료');

    // 3. 각 수신자의 FCM 토큰 조회 및 알림 발송
    const notifications = [];

    for (const participant of participants) {
      // 수신자의 총 unread count 계산 (채팅 + 알림)
      const { data: chatUnreadData } = await supabase
        .from('p2p_chat_participants')
        .select('unread_count')
        .eq('user_id', participant.user_id)
        .eq('is_active', true);

      const { data: notificationUnreadData } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', participant.user_id)
        .eq('is_read', false);

      const chatUnreadCount = chatUnreadData?.reduce((sum, p) => sum + (p.unread_count || 0), 0) || 0;
      const notificationUnreadCount = notificationUnreadData?.length || 0;
      const totalUnreadCount = chatUnreadCount + notificationUnreadCount;

      console.log(`📊 Unread count (user_id: ${participant.user_id}): 채팅=${chatUnreadCount}, 알림=${notificationUnreadCount}, 총=${totalUnreadCount}`);

      // 수신자의 FCM 토큰 조회
      const { data: devices, error: devicesError } = await supabase
        .from('device_tokens')
        .select('fcm_token, platform')
        .eq('user_id', participant.user_id)
        .eq('is_active', true);

      if (devicesError) {
        console.error(`❌ FCM 토큰 조회 실패 (user_id: ${participant.user_id}):`, devicesError);
        continue;
      }

      if (!devices || devices.length === 0) {
        console.log(`⚠️ FCM 토큰이 없습니다 (user_id: ${participant.user_id})`);
        continue;
      }

      console.log(`📱 FCM 토큰 조회: user_id=${participant.user_id}, platform=${devices[0].platform}, token=${devices[0].fcm_token.substring(0, 20)}...`);

      // 4. 각 디바이스에 FCM v1 API로 알림 발송
      for (const device of devices) {
        // 알림 본문 구성: "{보낸사람}: {메시지 내용}"
        const messageBody = message.message_type === 'text'
          ? message.message
          : '[이미지]';
        const notificationBody = `${message.sender_name}: ${messageBody}`;

        // FCM v1 API Payload
        const fcmPayload = {
          message: {
            token: device.fcm_token,
            notification: {
              title: '채팅 알림',
              body: notificationBody,
            },
            data: {
              type: 'chat_message',
              notification_type: 'custom',
              room_id: message.room_id.toString(),
              sender_id: message.sender_id.toString(),
              message_id: message.id.toString(),
              post_title: room_info?.post_title || '',
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
                  badge: totalUnreadCount, // 실제 unread count 설정
                },
              },
            },
          },
        };

        console.log(`🚀 FCM v1 알림 발송 시도 (user_id: ${participant.user_id})`);

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
          console.log(`✅ FCM 알림 발송 성공 (user_id: ${participant.user_id}, platform: ${device.platform})`);
          notifications.push({
            userId: participant.user_id,
            platform: device.platform,
            success: true,
          });
        } else {
          console.error(`❌ FCM 알림 발송 실패 (user_id: ${participant.user_id}):`, fcmResult);
          notifications.push({
            userId: participant.user_id,
            platform: device.platform,
            success: false,
            error: fcmResult,
          });
        }
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
