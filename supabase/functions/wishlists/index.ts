import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, temp-token",
};

serve(async (req) => {
  // CORS preflight 처리
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Supabase 클라이언트 생성
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // temp-token에서 사용자 ID 추출
    const tempToken = req.headers.get("temp-token");
    if (!tempToken) {
      return new Response(
        JSON.stringify({ success: false, message: "인증 토큰이 필요합니다" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // temp-token 파싱 (temp_token_userId_timestamp 형식)
    const parts = tempToken.split("_");
    if (parts.length < 3) {
      return new Response(
        JSON.stringify({ success: false, message: "유효하지 않은 토큰 형식입니다" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const userId = parseInt(parts[2]); // parts[0]='temp', parts[1]='token', parts[2]=userId

    if (!userId || isNaN(userId)) {
      return new Response(
        JSON.stringify({ success: false, message: "유효하지 않은 토큰입니다" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // GET: 찜한 글 목록 조회
    if (req.method === "GET") {
      const url = new URL(req.url);
      const page = parseInt(url.searchParams.get("page") || "1");
      const limit = parseInt(url.searchParams.get("limit") || "20");
      const offset = (page - 1) * limit;

      console.log(`📋 찜한 글 조회 - userId: ${userId}, page: ${page}, limit: ${limit}`);

      // wishlists 테이블에서 찜한 글 ID 목록 조회
      const { data: wishlists, error: wishlistError } = await supabase
        .from("wishlists")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .range(offset, offset + limit - 1);

      if (wishlistError) {
        console.error("❌ wishlists 조회 오류:", wishlistError);
        return new Response(
          JSON.stringify({ success: false, message: "찜한 글 조회 실패" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // 총 개수 조회
      const { count } = await supabase
        .from("wishlists")
        .select("*", { count: "exact", head: true })
        .eq("user_id", userId);

      // 각 게시물의 상세 정보 조회
      const items = [];
      for (const wishlist of wishlists || []) {
        let postData: any = {
          id: wishlist.id,
          post_type: wishlist.post_type,
          post_id: wishlist.post_id,
          post_title: wishlist.post_title,
          post_description: wishlist.post_description,
          post_image_url: wishlist.post_image_url,
          created_at: wishlist.created_at,
          price: null,
          is_free: null,
          location: null,
          church_location: null,
          view_count: null,
          likes: null,
        };

        // 게시물 타입에 따라 원본 데이터 조회
        try {
          if (wishlist.post_type === "community-sharing" || wishlist.post_type === "sharing-offer") {
            const { data: sharing } = await supabase
              .from("community_sharing")
              .select("price, is_free, province, district, view_count, likes, images, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (sharing) {
              postData.price = sharing.price;
              postData.is_free = sharing.is_free;
              postData.church_location = sharing.province && sharing.district
                ? `${sharing.province} ${sharing.district}`
                : sharing.province || sharing.district;
              postData.view_count = sharing.view_count;
              postData.likes = sharing.likes;
              postData.created_at = sharing.created_at; // 원본 게시글 작성일
              // 이미지 배열에서 첫 번째 이미지 추출
              if (sharing.images && sharing.images.length > 0) {
                postData.post_image_url = sharing.images[0];
              }
            }
          } else if (wishlist.post_type === "item-request") {
            const { data: request } = await supabase
              .from("community_requests")
              .select("location, view_count, likes, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (request) {
              postData.location = request.location;
              postData.view_count = request.view_count;
              postData.likes = request.likes;
              postData.created_at = request.created_at; // 원본 게시글 작성일
            }
          } else if (wishlist.post_type === "job-posting") {
            const { data: job } = await supabase
              .from("job_posts")
              .select("location, view_count, likes, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (job) {
              postData.location = job.location;
              postData.view_count = job.view_count;
              postData.likes = job.likes;
              postData.created_at = job.created_at; // 원본 게시글 작성일
            }
          } else if (wishlist.post_type === "music-team-recruit") {
            const { data: musicTeam } = await supabase
              .from("community_music_teams")
              .select("location, view_count, likes, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (musicTeam) {
              postData.location = musicTeam.location;
              postData.view_count = musicTeam.view_count;
              postData.likes = musicTeam.likes;
              postData.created_at = musicTeam.created_at; // 원본 게시글 작성일
            }
          } else if (wishlist.post_type === "music-team-seeking") {
            const { data: seeker } = await supabase
              .from("music_team_seekers")
              .select("view_count, likes, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (seeker) {
              postData.view_count = seeker.view_count;
              postData.likes = seeker.likes;
              postData.created_at = seeker.created_at; // 원본 게시글 작성일
            }
          } else if (wishlist.post_type === "church-events") {
            const { data: news } = await supabase
              .from("church_news")
              .select("location, view_count, likes, images, created_at")
              .eq("id", wishlist.post_id)
              .single();

            if (news) {
              postData.location = news.location;
              postData.view_count = news.view_count;
              postData.likes = news.likes;
              postData.created_at = news.created_at; // 원본 게시글 작성일
              // 이미지 배열에서 첫 번째 이미지 추출
              if (news.images && news.images.length > 0) {
                postData.post_image_url = news.images[0];
              }
            }
          }
        } catch (error) {
          console.error(`❌ ${wishlist.post_type} 상세 정보 조회 실패:`, error);
        }

        items.push(postData);
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: "찜한 글 조회 성공",
          data: {
            items,
            pagination: {
              page,
              limit,
              total: count || 0,
              totalPages: Math.ceil((count || 0) / limit),
            },
          },
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // POST: 찜하기 추가
    if (req.method === "POST") {
      const body = await req.json();
      const { post_type, post_id, post_title, post_description, post_image_url } = body;

      console.log(`💗 찜하기 추가 - userId: ${userId}, postType: ${post_type}, postId: ${post_id}`);

      // 이미 찜한 글인지 확인
      const { data: existing } = await supabase
        .from("wishlists")
        .select("id")
        .eq("user_id", userId)
        .eq("post_type", post_type)
        .eq("post_id", post_id)
        .single();

      if (existing) {
        return new Response(
          JSON.stringify({ success: false, message: "이미 찜한 글입니다" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // 찜하기 추가
      const { data, error } = await supabase
        .from("wishlists")
        .insert({
          user_id: userId,
          post_type,
          post_id,
          post_title,
          post_description,
          post_image_url,
        })
        .select()
        .single();

      if (error) {
        console.error("❌ 찜하기 추가 오류:", error);
        return new Response(
          JSON.stringify({ success: false, message: "찜하기 추가 실패" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: "찜하기에 추가되었습니다",
          data,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // DELETE: 찜하기 제거
    if (req.method === "DELETE") {
      const body = await req.json();
      const { post_type, post_id } = body;

      console.log(`💔 찜하기 제거 - userId: ${userId}, postType: ${post_type}, postId: ${post_id}`);

      const { error } = await supabase
        .from("wishlists")
        .delete()
        .eq("user_id", userId)
        .eq("post_type", post_type)
        .eq("post_id", post_id);

      if (error) {
        console.error("❌ 찜하기 제거 오류:", error);
        return new Response(
          JSON.stringify({ success: false, message: "찜하기 제거 실패" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: "찜하기에서 제거되었습니다",
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: false, message: "지원하지 않는 HTTP 메서드입니다" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ 오류:", error);
    return new Response(
      JSON.stringify({ success: false, message: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
