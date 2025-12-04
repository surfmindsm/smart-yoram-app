import 'dart:async';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:smart_yoram_app/models/api_response.dart';
import 'package:smart_yoram_app/services/supabase_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅 서비스
/// Supabase Realtime을 활용한 1:1 채팅 기능
class ChatService {
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  // Realtime 구독 관리
  final Map<int, RealtimeChannel> _messageSubscriptions = {};

  // ==========================================================================
  // 채팅방 관리
  // ==========================================================================

  /// 채팅방 생성 또는 기존 채팅방 조회
  ///
  /// [postId]: 게시글 ID
  /// [postTable]: 게시글 테이블명
  /// [postTitle]: 게시글 제목
  /// [otherUserId]: 상대방 사용자 ID
  ///
  /// 반환: ChatRoom 객체 또는 null
  Future<ChatRoom?> createOrGetChatRoom({
    required int postId,
    required String postTable,
    required String postTitle,
    required int otherUserId,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ CHAT_SERVICE: 로그인된 사용자 없음');
        return null;
      }

      final myUserId = currentUser.id;

      print('💬 CHAT_SERVICE: 채팅방 조회/생성 시작');
      print('   - postId: $postId, postTable: $postTable');
      print('   - myUserId: $myUserId, otherUserId: $otherUserId');

      // 1. 기존 채팅방 조회 (해당 게시글 & 두 사용자가 참여한 방)
      final existingRooms = await _supabaseService.client
          .from('p2p_chat_rooms')
          .select('*, p2p_chat_participants(*)')
          .eq('post_id', postId)
          .eq('post_table', postTable);

      print('📋 CHAT_SERVICE: 기존 채팅방 조회 결과: ${existingRooms.length}개');

      // 두 사용자가 모두 참여한 방 찾기
      for (var roomData in existingRooms as List) {
        final participants = roomData['p2p_chat_participants'] as List;
        final participantIds = participants.map((p) => p['user_id'] as int).toSet();

        if (participantIds.contains(myUserId) && participantIds.contains(otherUserId)) {
          print('✅ CHAT_SERVICE: 기존 채팅방 발견 - ID: ${roomData['id']}');

          // 내 참여자 정보 확인
          final myParticipant = participants.firstWhere(
            (p) => p['user_id'] == myUserId,
            orElse: () => null,
          );

          // 내가 이전에 삭제했던 채팅방이면 삭제 시점만 업데이트 (is_active는 false 유지)
          // 실제 재활성화는 첫 메시지를 보낼 때 수행
          if (myParticipant != null && myParticipant['is_active'] == false) {
            print('🔄 CHAT_SERVICE: 삭제했던 채팅방 준비 - participantId: ${myParticipant['id']}');
            final now = DateTime.now().toUtc().toIso8601String();
            final roomId = roomData['id'] as int;

            // 1. 삭제 시점만 업데이트 (is_active는 false 유지 - 메시지 보낼 때 true로 변경)
            await _supabaseService.client
                .from('p2p_chat_participants')
                .update({
                  'last_deleted_at': now, // 지금 시점을 삭제 기준으로 설정
                  'unread_count': 0,
                  'last_read_at': now,
                })
                .eq('id', myParticipant['id']);

            // 2. 채팅방의 마지막 메시지 캐시 초기화
            await _supabaseService.client
                .from('p2p_chat_rooms')
                .update({
                  'last_message': null,
                  'last_message_at': null,
                })
                .eq('id', roomId);

            print('✅ CHAT_SERVICE: 삭제 시점 업데이트 완료 (첫 메시지 전송 시 활성화됨)');

            // 3. 재조회
            final updatedRoom = await _supabaseService.client
                .from('p2p_chat_rooms')
                .select('*, p2p_chat_participants(*)')
                .eq('id', roomId)
                .single();

            return await _buildChatRoomWithDetails(updatedRoom, myUserId);
          }

          return await _buildChatRoomWithDetails(roomData, myUserId);
        }
      }

      // 2. 기존 채팅방이 없으면 새로 생성
      print('🆕 CHAT_SERVICE: 새 채팅방 생성 시작');

      final newRoom = await _supabaseService.client
          .from('p2p_chat_rooms')
          .insert({
            'post_id': postId,
            'post_table': postTable,
            'post_title': postTitle,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      final roomId = newRoom['id'] as int;
      print('✅ CHAT_SERVICE: 채팅방 생성 완료 - ID: $roomId');

      // 3. 참여자 추가 (나 + 상대방)
      await _addParticipants(roomId, [myUserId, otherUserId]);

      // 4. 채팅방 정보 재조회 (참여자 정보 포함)
      final roomWithParticipants = await _supabaseService.client
          .from('p2p_chat_rooms')
          .select('*, p2p_chat_participants(*)')
          .eq('id', roomId)
          .single();

      return await _buildChatRoomWithDetails(roomWithParticipants, myUserId);
    } catch (e) {
      print('❌ CHAT_SERVICE: 채팅방 생성/조회 실패 - $e');
      return null;
    }
  }

  /// 참여자 추가 (내부 메서드)
  Future<void> _addParticipants(int roomId, List<int> userIds) async {
    try {
      // 사용자 이름 조회
      final users = await _supabaseService.client
          .from('users')
          .select('id, full_name')
          .inFilter('id', userIds);

      final userMap = {
        for (var user in users as List) user['id'] as int: user['full_name'] as String
      };

      // 참여자 삽입
      final participants = userIds.map((userId) {
        return {
          'room_id': roomId,
          'user_id': userId,
          'user_name': userMap[userId] ?? '알 수 없음',
          'joined_at': DateTime.now().toUtc().toIso8601String(),
          'last_read_at': DateTime.now().toUtc().toIso8601String(),
          'unread_count': 0,
          'is_active': true,
        };
      }).toList();

      await _supabaseService.client.from('p2p_chat_participants').insert(participants);

      print('✅ CHAT_SERVICE: 참여자 추가 완료 - ${userIds.length}명');
    } catch (e) {
      print('❌ CHAT_SERVICE: 참여자 추가 실패 - $e');
      rethrow;
    }
  }

  /// 채팅방 상세 정보 구성 (내부 메서드)
  Future<ChatRoom> _buildChatRoomWithDetails(
    Map<String, dynamic> roomData,
    int myUserId,
  ) async {
    final participants = roomData['p2p_chat_participants'] as List;

    // 상대방 찾기
    final otherParticipant = participants.firstWhere(
      (p) => p['user_id'] != myUserId,
      orElse: () => null,
    );

    // 내 참여자 정보 찾기 (안 읽은 메시지 개수)
    final myParticipant = participants.firstWhere(
      (p) => p['user_id'] == myUserId,
      orElse: () => {'unread_count': 0},
    );

    String? otherUserPhotoUrl;
    String? otherUserChurch;
    String? otherUserLocation;
    if (otherParticipant != null) {
      final otherUserId = otherParticipant['user_id'] as int;

      // 상대방 프로필 사진, 교회 조회
      try {
        print('🔍 CHAT_SERVICE: 상대방 정보 조회 시작 - otherUserId: $otherUserId');

        // 1. members 테이블에서 프로필 사진과 church_id 조회
        final member = await _supabaseService.client
            .from('members')
            .select('profile_photo_url, church_id')
            .eq('user_id', otherUserId)
            .maybeSingle();

        print('🔍 CHAT_SERVICE: member 조회 결과 - $member');

        int? churchId;

        if (member != null) {
          // 프로필 사진 설정
          if (member['profile_photo_url'] != null) {
            otherUserPhotoUrl = _getFullProfilePhotoUrl(member['profile_photo_url'] as String);
          }
          churchId = member['church_id'] as int?;
        } else {
          // 2. members 테이블에 없으면 users 테이블에서 church_id 조회
          print('🔍 CHAT_SERVICE: members에 없음, users 테이블 조회');
          final user = await _supabaseService.client
              .from('users')
              .select('church_id')
              .eq('id', otherUserId)
              .maybeSingle();

          print('🔍 CHAT_SERVICE: user 조회 결과 - $user');

          if (user != null) {
            churchId = user['church_id'] as int?;
          }
        }

        // 3. 교회 정보 조회
        if (churchId != null) {
          print('🔍 CHAT_SERVICE: 교회 조회 시작 - church_id: $churchId');

          // 9998은 커뮤니티 회원
          if (churchId == 9998) {
            otherUserChurch = '커뮤니티 회원';
            print('✅ CHAT_SERVICE: 커뮤니티 회원으로 설정');
          } else {
            final church = await _supabaseService.client
                .from('churches')
                .select('name')
                .eq('id', churchId)
                .maybeSingle();

            print('🔍 CHAT_SERVICE: church 조회 결과 - $church');

            if (church != null) {
              otherUserChurch = church['name'] as String?;
              print('✅ CHAT_SERVICE: 교회 이름 설정 - $otherUserChurch');
            }
          }
        }
      } catch (e) {
        print('⚠️ CHAT_SERVICE: 프로필 정보 조회 실패 - $e');
      }
    }

    // 게시글 이미지, 가격, 상태, 지역 조회
    String? postImageUrl;
    int? postPrice;
    String? postStatus;
    if (roomData['post_table'] != null && roomData['post_id'] != null) {
      try {
        final postTable = roomData['post_table'] as String;
        final postId = roomData['post_id'] as int;

        print('🔍 CHAT_SERVICE: 게시글 조회 시작 - table: $postTable, id: $postId');

        final post = await _supabaseService.client
            .from(postTable)
            .select('images, price, status, location, province, district')
            .eq('id', postId)
            .maybeSingle();

        print('🔍 CHAT_SERVICE: 게시글 조회 결과 - $post');

        if (post != null) {
          // 이미지
          if (post['images'] != null) {
            final images = post['images'] as List?;
            if (images != null && images.isNotEmpty) {
              postImageUrl = images[0] as String?;
              print('✅ CHAT_SERVICE: 이미지 URL 설정 - $postImageUrl');
            }
          }
          // 가격 (실수로 저장될 수 있으므로 int로 변환)
          final priceValue = post['price'];
          if (priceValue != null) {
            if (priceValue is int) {
              postPrice = priceValue;
            } else if (priceValue is double) {
              postPrice = priceValue.toInt();
            }
            print('✅ CHAT_SERVICE: 가격 설정 - $postPrice');
          }
          // 상태
          postStatus = post['status'] as String?;
          print('✅ CHAT_SERVICE: 상태 설정 - $postStatus');

          // 지역 정보 (게시글에서 가져오기)
          // 우선순위: province + district > location (레거시 필드)
          if (post['province'] != null || post['district'] != null) {
            final provincePart = post['province'] as String? ?? '';
            final districtPart = post['district'] as String? ?? '';
            otherUserLocation = [provincePart, districtPart]
                .where((e) => e.isNotEmpty)
                .join(' ')
                .trim();
            if (otherUserLocation!.isEmpty) {
              otherUserLocation = null;
            }
            print('✅ CHAT_SERVICE: 지역 설정 (province+district) - $otherUserLocation');
          } else if (post['location'] != null && (post['location'] as String).isNotEmpty) {
            otherUserLocation = post['location'] as String;
            print('✅ CHAT_SERVICE: 지역 설정 (location) - $otherUserLocation');
          }
        }
      } catch (e) {
        print('⚠️ CHAT_SERVICE: 게시글 정보 조회 실패 - $e');
      }
    }

    return ChatRoom(
      id: roomData['id'] as int,
      postId: roomData['post_id'] as int?,
      postTable: roomData['post_table'] as String?,
      postTitle: roomData['post_title'] as String?,
      createdAt: DateTime.parse(roomData['created_at'] as String),
      updatedAt: DateTime.parse(roomData['updated_at'] as String),
      lastMessageAt: roomData['last_message_at'] != null
          ? DateTime.parse(roomData['last_message_at'] as String)
          : null,
      lastMessage: roomData['last_message'] as String?,
      otherUserName: otherParticipant?['user_name'] as String?,
      otherUserPhotoUrl: otherUserPhotoUrl,
      otherUserId: otherParticipant?['user_id'] as int?,
      otherUserChurch: otherUserChurch,
      otherUserLocation: otherUserLocation,
      postImageUrl: postImageUrl,
      postPrice: postPrice,
      postStatus: postStatus,
      unreadCount: myParticipant['unread_count'] as int? ?? 0,
      authorId: null, // 배치 조회에서 설정됨
    );
  }

  /// 프로필 사진 URL 변환
  String? _getFullProfilePhotoUrl(String? profilePhotoUrl) {
    if (profilePhotoUrl == null || profilePhotoUrl.isEmpty) return null;
    if (profilePhotoUrl.startsWith('http')) return profilePhotoUrl;

    const supabaseUrl = 'https://adzhdsajdamrflvybhxq.supabase.co';
    final cleanPath = profilePhotoUrl.startsWith('/')
        ? profilePhotoUrl.substring(1)
        : profilePhotoUrl;

    return '$supabaseUrl/storage/v1/object/public/member-photos/$cleanPath';
  }

  /// 채팅방 삭제 (소프트 삭제)
  ///
  /// [roomId]: 삭제할 채팅방 ID
  ///
  /// 실제로 채팅방을 삭제하지 않고, 현재 사용자의 참여자 상태만 is_active = false로 변경합니다.
  /// 상대방은 계속 채팅방을 볼 수 있습니다.
  Future<ApiResponse<void>> deleteChatRoom(int roomId) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('🗑️ CHAT_SERVICE: 채팅방 소프트 삭제 시작 - roomId: $roomId, userId: ${currentUser.id}');

      // 내 참여자 정보의 is_active를 false로 변경 + 삭제 시점 기록 (소프트 삭제)
      await _supabaseService.client
          .from('p2p_chat_participants')
          .update({
            'is_active': false,
            'last_deleted_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id);

      print('✅ CHAT_SERVICE: 채팅방 소프트 삭제 완료 (이전 메시지는 다시 안 보임)');

      // 구독 해제
      unsubscribeFromMessages(roomId);

      return ApiResponse(
        success: true,
        message: '채팅방이 삭제되었습니다',
        data: null,
      );
    } catch (e) {
      print('❌ CHAT_SERVICE: 채팅방 삭제 실패 - $e');
      return ApiResponse(
        success: false,
        message: '채팅방 삭제 실패: $e',
        data: null,
      );
    }
  }

  /// 총 안 읽은 메시지 개수 조회
  Future<int> getTotalUnreadCount() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return 0;
      }

      final myUserId = currentUser.id;

      // 내가 참여한 활성 채팅방의 unread_count 합계
      final result = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('unread_count')
          .eq('user_id', myUserId)
          .eq('is_active', true);

      int totalUnread = 0;
      for (var participant in result as List) {
        totalUnread += (participant['unread_count'] as int? ?? 0);
      }

      return totalUnread;
    } catch (e) {
      print('❌ CHAT_SERVICE: 안 읽은 메시지 개수 조회 실패 - $e');
      return 0;
    }
  }

  /// 내 채팅방 목록 조회
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ CHAT_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      final myUserId = currentUser.id;

      print('📋 CHAT_SERVICE: 채팅방 목록 조회 - userId: $myUserId');

      // 내가 참여한 채팅방 ID 조회 (is_active = true인 것만)
      final myParticipations = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('room_id, unread_count')
          .eq('user_id', myUserId)
          .eq('is_active', true);

      if ((myParticipations as List).isEmpty) {
        print('📋 CHAT_SERVICE: 참여 중인 채팅방 없음');
        return [];
      }

      final roomIds = myParticipations.map((p) => p['room_id'] as int).toList();
      final unreadMap = {
        for (var p in myParticipations) p['room_id'] as int: p['unread_count'] as int
      };

      // 채팅방 정보 조회 (참여자 포함)
      final rooms = await _supabaseService.client
          .from('p2p_chat_rooms')
          .select('*, p2p_chat_participants(*)')
          .inFilter('id', roomIds)
          .order('last_message_at', ascending: false);

      print('📋 CHAT_SERVICE: 채팅방 ${(rooms as List).length}개 조회 완료');

      // 게시글 작성자 ID를 배치로 조회
      final authorIdMap = await _batchFetchAuthorIds(rooms as List);

      // ChatRoom 객체 리스트 생성
      final chatRooms = <ChatRoom>[];
      for (var roomData in rooms) {
        final chatRoom = await _buildChatRoomWithDetails(roomData, myUserId);

        final roomId = chatRoom.id;
        final postKey = '${chatRoom.postTable}_${chatRoom.postId}';
        final authorId = authorIdMap[postKey];

        print('🔍 CHAT_SERVICE: 채팅방 $roomId - postTable: ${chatRoom.postTable}, postId: ${chatRoom.postId}, authorId: $authorId');

        // 안 읽은 메시지 개수 업데이트 + authorId 추가
        final updatedChatRoom = ChatRoom(
          id: chatRoom.id,
          postId: chatRoom.postId,
          postTable: chatRoom.postTable,
          postTitle: chatRoom.postTitle,
          createdAt: chatRoom.createdAt,
          updatedAt: chatRoom.updatedAt,
          lastMessageAt: chatRoom.lastMessageAt,
          lastMessage: chatRoom.lastMessage,
          otherUserName: chatRoom.otherUserName,
          otherUserPhotoUrl: chatRoom.otherUserPhotoUrl,
          otherUserId: chatRoom.otherUserId,
          otherUserChurch: chatRoom.otherUserChurch,
          otherUserLocation: chatRoom.otherUserLocation,
          postImageUrl: chatRoom.postImageUrl,
          postPrice: chatRoom.postPrice,
          postStatus: chatRoom.postStatus,
          unreadCount: unreadMap[roomId] ?? 0,
          authorId: authorId,
        );

        chatRooms.add(updatedChatRoom);
      }

      return chatRooms;
    } catch (e) {
      print('❌ CHAT_SERVICE: 채팅방 목록 조회 실패 - $e');
      return [];
    }
  }

  /// 게시글 작성자 ID를 배치로 조회 (N+1 문제 방지)
  Future<Map<String, int>> _batchFetchAuthorIds(List rooms) async {
    final authorIdMap = <String, int>{};

    // postTable별로 그룹화
    final postsByTable = <String, List<int>>{};
    for (var roomData in rooms) {
      final postTable = roomData['post_table'] as String?;
      final postId = roomData['post_id'] as int?;

      if (postTable != null && postId != null) {
        if (!postsByTable.containsKey(postTable)) {
          postsByTable[postTable] = [];
        }
        postsByTable[postTable]!.add(postId);
      }
    }

    print('🔍 CHAT_SERVICE: 배치 조회 시작 - ${postsByTable.keys.length}개 테이블');

    // 각 테이블별로 배치 조회
    for (var entry in postsByTable.entries) {
      final tableName = entry.key;
      final postIds = entry.value;

      try {
        print('🔍 CHAT_SERVICE: $tableName 테이블에서 ${postIds.length}개 게시글 작성자 조회');

        final posts = await _supabaseService.client
            .from(tableName)
            .select('id, author_id')
            .inFilter('id', postIds);

        print('✅ CHAT_SERVICE: $tableName 테이블에서 ${(posts as List).length}개 작성자 조회 완료');

        for (var post in posts) {
          final postId = post['id'] as int;
          final authorId = post['author_id'] as int?;
          if (authorId != null) {
            final key = '${tableName}_$postId';
            authorIdMap[key] = authorId;
            print('   - postId: $postId, authorId: $authorId');
          }
        }
      } catch (e) {
        print('⚠️ CHAT_SERVICE: $tableName 테이블 조회 실패 - $e');
      }
    }

    print('✅ CHAT_SERVICE: 총 ${authorIdMap.length}개 작성자 ID 조회 완료');
    return authorIdMap;
  }

  // ==========================================================================
  // 메시지 관리
  // ==========================================================================

  /// 메시지 조회
  ///
  /// [roomId]: 채팅방 ID
  /// [limit]: 조회할 메시지 개수 (기본 50개)
  /// [offset]: 페이지네이션 오프셋 (기본 0)
  ///
  /// 내가 채팅방을 삭제했다가 다시 시작한 경우,
  /// last_deleted_at 이후의 메시지만 조회합니다.
  Future<List<ChatMessage>> getMessages(
    int roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ CHAT_SERVICE: 로그인된 사용자 없음');
        return [];
      }

      print('📨 CHAT_SERVICE: 메시지 조회 - roomId: $roomId, limit: $limit');

      // 내 참여자 정보 조회 (last_deleted_at 확인)
      final participant = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('last_deleted_at')
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      DateTime? lastDeletedAt;
      if (participant != null && participant['last_deleted_at'] != null) {
        lastDeletedAt = DateTime.parse(participant['last_deleted_at'] as String);
        print('📨 CHAT_SERVICE: 삭제 시점 발견 - $lastDeletedAt');
      }

      // 메시지 조회 (last_deleted_at 이후만)
      var query = _supabaseService.client
          .from('p2p_chat_messages')
          .select()
          .eq('room_id', roomId);

      // 삭제 시점 이후 메시지만 필터링
      if (lastDeletedAt != null) {
        query = query.gt('created_at', lastDeletedAt.toIso8601String());
      }

      final messages = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('📨 CHAT_SERVICE: 메시지 ${(messages as List).length}개 조회 완료');

      return (messages)
          .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList()
          .reversed
          .toList(); // 오래된 메시지가 위로 오도록 역순
    } catch (e) {
      print('❌ CHAT_SERVICE: 메시지 조회 실패 - $e');
      return [];
    }
  }

  /// 메시지 전송
  ///
  /// [roomId]: 채팅방 ID
  /// [message]: 메시지 내용
  /// [messageType]: 메시지 타입 (text, image)
  /// [imageUrl]: 이미지 URL (messageType이 image일 때)
  Future<ApiResponse<ChatMessage>> sendMessage({
    required int roomId,
    required String message,
    String messageType = 'text',
    String? imageUrl,
  }) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        return ApiResponse(
          success: false,
          message: '로그인이 필요합니다',
          data: null,
        );
      }

      print('📤 CHAT_SERVICE: 메시지 전송 시작');

      // 1. 메시지 삽입
      final newMessage = await _supabaseService.client
          .from('p2p_chat_messages')
          .insert({
            'room_id': roomId,
            'sender_id': currentUser.id,
            'sender_name': currentUser.fullName ?? '알 수 없음',
            'message': message,
            'message_type': messageType,
            'image_url': imageUrl,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'is_read': false,
          })
          .select()
          .single();

      print('✅ CHAT_SERVICE: 메시지 전송 완료 - ID: ${newMessage['id']}');

      // 2. 내 참여자를 활성화 (is_active = true) - 메시지를 보냈으니 채팅 목록에 표시
      await _supabaseService.client
          .from('p2p_chat_participants')
          .update({'is_active': true})
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id);

      print('✅ CHAT_SERVICE: 내 참여자 활성화 완료 (채팅 목록에 표시됨)');

      // 3. 채팅방 last_message 업데이트
      await _supabaseService.client.from('p2p_chat_rooms').update({
        'last_message': message,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', roomId);

      // 4. 상대방 unread_count 증가
      await _incrementUnreadCount(roomId, currentUser.id);

      return ApiResponse(
        success: true,
        message: '메시지 전송 완료',
        data: ChatMessage.fromJson(newMessage as Map<String, dynamic>),
      );
    } catch (e) {
      print('❌ CHAT_SERVICE: 메시지 전송 실패 - $e');
      return ApiResponse(
        success: false,
        message: '메시지 전송 실패: $e',
        data: null,
      );
    }
  }

  /// 상대방 안 읽은 메시지 개수 증가 (내부 메서드)
  ///
  /// 상대방이 채팅방을 삭제했더라도(is_active = false),
  /// 새 메시지를 보내면 자동으로 재활성화(is_active = true)됩니다.
  Future<void> _incrementUnreadCount(int roomId, int myUserId) async {
    try {
      // 상대방 참여자 조회
      final participants = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('id, user_id, unread_count, is_active')
          .eq('room_id', roomId)
          .neq('user_id', myUserId);

      for (var participant in participants as List) {
        final currentCount = participant['unread_count'] as int? ?? 0;
        final isActive = participant['is_active'] as bool? ?? true;

        // 안 읽은 메시지 증가 + 삭제했던 채팅방이면 재활성화
        await _supabaseService.client
            .from('p2p_chat_participants')
            .update({
              'unread_count': currentCount + 1,
              'is_active': true, // 삭제했어도 새 메시지 오면 다시 활성화
            })
            .eq('id', participant['id']);

        if (!isActive) {
          print('🔄 CHAT_SERVICE: 상대방이 삭제한 채팅방 재활성화 (새 메시지 도착)');
        }
      }

      print('✅ CHAT_SERVICE: 상대방 unread_count 증가 완료');
    } catch (e) {
      print('❌ CHAT_SERVICE: unread_count 증가 실패 - $e');
    }
  }

  /// 읽음 처리
  ///
  /// [roomId]: 채팅방 ID
  ///
  /// last_deleted_at 이후의 메시지만 읽음 처리합니다.
  Future<void> markAsRead(int roomId) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ CHAT_SERVICE: 로그인된 사용자 없음');
        return;
      }

      print('✅ CHAT_SERVICE: 읽음 처리 시작 - roomId: $roomId');

      // 내 참여자 정보 조회 (last_deleted_at 확인)
      final participant = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('last_deleted_at')
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      // 1. 내가 읽지 않은 메시지들(상대방이 보낸 메시지)의 is_read를 true로 업데이트
      var query = _supabaseService.client
          .from('p2p_chat_messages')
          .update({'is_read': true})
          .eq('room_id', roomId)
          .neq('sender_id', currentUser.id)
          .eq('is_read', false);

      // 삭제 시점 이후 메시지만 읽음 처리
      if (participant != null && participant['last_deleted_at'] != null) {
        final lastDeletedAt = DateTime.parse(participant['last_deleted_at'] as String);
        query = query.gt('created_at', lastDeletedAt.toIso8601String());
      }

      await query;

      // 2. 내 참여자 정보 업데이트 (unread_count를 0으로)
      await _supabaseService.client
          .from('p2p_chat_participants')
          .update({
            'last_read_at': DateTime.now().toUtc().toIso8601String(),
            'unread_count': 0,
          })
          .eq('room_id', roomId)
          .eq('user_id', currentUser.id);

      print('✅ CHAT_SERVICE: 읽음 처리 완료');
    } catch (e) {
      print('❌ CHAT_SERVICE: 읽음 처리 실패 - $e');
    }
  }

  // ==========================================================================
  // Realtime 구독
  // ==========================================================================

  /// 실시간 메시지 구독
  ///
  /// [roomId]: 채팅방 ID
  /// [onMessage]: 새 메시지 수신 시 콜백
  /// [onMessageUpdate]: 메시지 업데이트(읽음 상태 등) 시 콜백
  RealtimeChannel subscribeToMessages(
    int roomId,
    void Function(ChatMessage message) onMessage, {
    void Function(ChatMessage message)? onMessageUpdate,
  }) {
    print('🔔 CHAT_SERVICE: 실시간 메시지 구독 시작 - roomId: $roomId');

    // 기존 구독이 있으면 제거
    if (_messageSubscriptions.containsKey(roomId)) {
      _messageSubscriptions[roomId]?.unsubscribe();
      _messageSubscriptions.remove(roomId);
    }

    // 새 구독 생성
    final channel = _supabaseService.client
        .channel('p2p_chat_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'p2p_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            print('🔔 CHAT_SERVICE: 새 메시지 수신 - ${payload.newRecord}');
            final message = ChatMessage.fromJson(payload.newRecord);
            onMessage(message);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'p2p_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            print('🔔 CHAT_SERVICE: 메시지 업데이트 수신 - ${payload.newRecord}');
            if (onMessageUpdate != null) {
              final message = ChatMessage.fromJson(payload.newRecord);
              onMessageUpdate(message);
            }
          },
        )
        .subscribe();

    _messageSubscriptions[roomId] = channel;

    return channel;
  }

  /// 구독 해제
  ///
  /// [roomId]: 채팅방 ID
  void unsubscribeFromMessages(int roomId) {
    if (_messageSubscriptions.containsKey(roomId)) {
      print('🔕 CHAT_SERVICE: 구독 해제 - roomId: $roomId');
      _messageSubscriptions[roomId]?.unsubscribe();
      _messageSubscriptions.remove(roomId);
    }
  }

  /// 모든 구독 해제
  void unsubscribeAll() {
    print('🔕 CHAT_SERVICE: 모든 구독 해제');
    for (var channel in _messageSubscriptions.values) {
      channel.unsubscribe();
    }
    _messageSubscriptions.clear();
  }
}
