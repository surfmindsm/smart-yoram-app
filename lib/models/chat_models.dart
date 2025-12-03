import 'package:intl/intl.dart';

/// 채팅방 모델
class ChatRoom {
  final int id;
  final int? postId;
  final String? postTable;
  final String? postTitle;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;

  // 조인 데이터 (프론트엔드에서 추가)
  final String? otherUserName; // 상대방 이름
  final String? otherUserPhotoUrl; // 상대방 프로필 사진
  final int? otherUserId; // 상대방 ID
  final int unreadCount; // 안 읽은 메시지 개수
  final int? authorId; // 게시글 작성자 ID (판매자/구인자)

  ChatRoom({
    required this.id,
    this.postId,
    this.postTable,
    this.postTitle,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessage,
    this.otherUserName,
    this.otherUserPhotoUrl,
    this.otherUserId,
    this.unreadCount = 0,
    this.authorId,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as int,
      postId: json['post_id'] as int?,
      postTable: json['post_table'] as String?,
      postTitle: json['post_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessage: json['last_message'] as String?,
      otherUserName: json['other_user_name'] as String?,
      otherUserPhotoUrl: json['other_user_photo_url'] as String?,
      otherUserId: json['other_user_id'] as int?,
      unreadCount: json['unread_count'] as int? ?? 0,
      authorId: json['author_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'post_table': postTable,
      'post_title': postTitle,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message': lastMessage,
    };
  }

  /// 시간 포맷팅 (상대 시간)
  String get formattedTime {
    if (lastMessageAt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(lastMessageAt!);
    }
  }

  /// 채팅방 제목 (게시글 제목 또는 상대방 이름)
  String get displayTitle {
    if (postTitle != null && postTitle!.isNotEmpty) {
      return postTitle!;
    }
    if (otherUserName != null && otherUserName!.isNotEmpty) {
      return otherUserName!;
    }
    return '채팅방';
  }
}

/// 채팅 메시지 모델
class ChatMessage {
  final int id;
  final int roomId;
  final int senderId;
  final String senderName;
  final String message;
  final String messageType; // text, image, system
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.messageType = 'text',
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String? ?? '알 수 없음',
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'message_type': messageType,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// 시간 포맷팅 (시:분)
  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt);
  }

  /// 날짜 포맷팅 (yyyy년 MM월 dd일)
  String get formattedDate {
    final now = DateTime.now();
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);

    if (messageDate == today) {
      return '오늘';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else if (createdAt.year == now.year) {
      return DateFormat('MM월 dd일').format(createdAt);
    } else {
      return DateFormat('yyyy년 MM월 dd일').format(createdAt);
    }
  }
}

/// 채팅 참여자 모델
class ChatParticipant {
  final int id;
  final int roomId;
  final int userId;
  final String? userName;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final int unreadCount;

  ChatParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    this.userName,
    required this.joinedAt,
    required this.lastReadAt,
    this.unreadCount = 0,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as int,
      roomId: json['room_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'user_name': userName,
      'joined_at': joinedAt.toIso8601String(),
      'last_read_at': lastReadAt.toIso8601String(),
      'unread_count': unreadCount,
    };
  }
}
