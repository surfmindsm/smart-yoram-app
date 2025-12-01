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
    if (otherParticipant != null) {
      final otherUserId = otherParticipant['user_id'] as int;

      // 상대방 프로필 사진 조회
      try {
        final member = await _supabaseService.client
            .from('members')
            .select('profile_photo_url')
            .eq('user_id', otherUserId)
            .maybeSingle();

        if (member != null && member['profile_photo_url'] != null) {
          otherUserPhotoUrl = _getFullProfilePhotoUrl(member['profile_photo_url'] as String);
        }
      } catch (e) {
        print('⚠️ CHAT_SERVICE: 프로필 사진 조회 실패 - $e');
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
      unreadCount: myParticipant['unread_count'] as int? ?? 0,
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

      // 내가 참여한 채팅방 ID 조회
      final myParticipations = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('room_id, unread_count')
          .eq('user_id', myUserId);

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

      // ChatRoom 객체 리스트 생성
      final chatRooms = <ChatRoom>[];
      for (var roomData in rooms) {
        final chatRoom = await _buildChatRoomWithDetails(roomData, myUserId);

        // 안 읽은 메시지 개수 업데이트
        final roomId = chatRoom.id;
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
          unreadCount: unreadMap[roomId] ?? 0,
        );

        chatRooms.add(updatedChatRoom);
      }

      return chatRooms;
    } catch (e) {
      print('❌ CHAT_SERVICE: 채팅방 목록 조회 실패 - $e');
      return [];
    }
  }

  // ==========================================================================
  // 메시지 관리
  // ==========================================================================

  /// 메시지 조회
  ///
  /// [roomId]: 채팅방 ID
  /// [limit]: 조회할 메시지 개수 (기본 50개)
  /// [offset]: 페이지네이션 오프셋 (기본 0)
  Future<List<ChatMessage>> getMessages(
    int roomId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      print('📨 CHAT_SERVICE: 메시지 조회 - roomId: $roomId, limit: $limit');

      final messages = await _supabaseService.client
          .from('p2p_chat_messages')
          .select()
          .eq('room_id', roomId)
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

      // 2. 채팅방 last_message 업데이트
      await _supabaseService.client.from('p2p_chat_rooms').update({
        'last_message': message,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', roomId);

      // 3. 상대방 unread_count 증가
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
  Future<void> _incrementUnreadCount(int roomId, int myUserId) async {
    try {
      // 상대방 참여자 조회
      final participants = await _supabaseService.client
          .from('p2p_chat_participants')
          .select('id, user_id, unread_count')
          .eq('room_id', roomId)
          .neq('user_id', myUserId);

      for (var participant in participants as List) {
        final currentCount = participant['unread_count'] as int? ?? 0;
        await _supabaseService.client
            .from('p2p_chat_participants')
            .update({'unread_count': currentCount + 1})
            .eq('id', participant['id']);
      }

      print('✅ CHAT_SERVICE: 상대방 unread_count 증가 완료');
    } catch (e) {
      print('❌ CHAT_SERVICE: unread_count 증가 실패 - $e');
    }
  }

  /// 읽음 처리
  ///
  /// [roomId]: 채팅방 ID
  Future<void> markAsRead(int roomId) async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;

      if (currentUser == null) {
        print('❌ CHAT_SERVICE: 로그인된 사용자 없음');
        return;
      }

      print('✅ CHAT_SERVICE: 읽음 처리 시작 - roomId: $roomId');

      // 내 참여자 정보 업데이트
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
  RealtimeChannel subscribeToMessages(
    int roomId,
    void Function(ChatMessage message) onMessage,
  ) {
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
