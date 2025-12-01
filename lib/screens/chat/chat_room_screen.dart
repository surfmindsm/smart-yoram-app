import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/widgets/chat/message_bubble.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 채팅방 화면
class ChatRoomScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatRoomScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _currentUserId;
  RealtimeChannel? _subscription;
  bool _hasText = false; // 텍스트 입력 여부

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.unsubscribeFromMessages(widget.chatRoom.id);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 현재 사용자 ID 조회
      final userResponse = await _authService.getCurrentUser();
      _currentUserId = userResponse.data?.id;

      // 메시지 조회
      final messages = await _chatService.getMessages(widget.chatRoom.id);

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // 읽음 처리
      await _chatService.markAsRead(widget.chatRoom.id);

      // 실시간 구독 시작
      _subscribeToMessages();

      // 스크롤을 맨 아래로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('❌ CHAT_ROOM_SCREEN: 데이터 로드 실패 - $e');
      setState(() => _isLoading = false);
    }
  }

  /// 실시간 메시지 구독
  void _subscribeToMessages() {
    _subscription = _chatService.subscribeToMessages(
      widget.chatRoom.id,
      (newMessage) {
        // 내가 보낸 메시지가 아니면 추가 (중복 방지)
        if (newMessage.senderId != _currentUserId) {
          setState(() {
            _messages.add(newMessage);
          });

          // 스크롤을 맨 아래로 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });

          // 읽음 처리
          _chatService.markAsRead(widget.chatRoom.id);
        }
      },
      onMessageUpdate: (updatedMessage) {
        // 메시지 업데이트 (읽음 상태 변경)
        setState(() {
          final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
      },
    );
  }

  /// 메시지 전송
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      // 낙관적 업데이트 (Optimistic Update)
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch, // 임시 ID
        roomId: widget.chatRoom.id,
        senderId: _currentUserId!,
        senderName: '나',
        message: messageText,
        messageType: 'text',
        createdAt: DateTime.now(),
        isRead: false,
      );

      setState(() {
        _messages.add(tempMessage);
        _messageController.clear();
        _hasText = false;
      });

      // 스크롤을 맨 아래로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // 실제 메시지 전송
      final response = await _chatService.sendMessage(
        roomId: widget.chatRoom.id,
        message: messageText,
      );

      if (response.success && response.data != null) {
        // 임시 메시지를 실제 메시지로 교체
        setState(() {
          final index = _messages.indexWhere((m) => m.id == tempMessage.id);
          if (index != -1) {
            _messages[index] = response.data!;
          }
        });
      } else {
        // 전송 실패 시 임시 메시지 제거
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      print('❌ CHAT_ROOM_SCREEN: 메시지 전송 실패 - $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // 상대방 프로필 이미지
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: NewAppColor.neutral200,
                shape: BoxShape.circle,
              ),
              child: widget.chatRoom.otherUserPhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        widget.chatRoom.otherUserPhotoUrl!,
                        width: 36.w,
                        height: 36.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: NewAppColor.neutral500,
                            size: 18.sp,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: NewAppColor.neutral500,
                      size: 18.sp,
                    ),
            ),
            SizedBox(width: 12.w),
            // 상대방 이름 + 게시글 제목
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.otherUserName ?? '알 수 없음',
                    style: FigmaTextStyles().body1.copyWith(
                          color: NewAppColor.neutral900,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (widget.chatRoom.postTitle != null)
                    Text(
                      widget.chatRoom.postTitle!,
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral600,
                            fontSize: 12.sp,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.neutral200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 메시지 목록
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == _currentUserId;

                            // 이전 메시지와 같은 사람인지 확인 (프로필 표시 여부)
                            bool showProfile = true;
                            if (index > 0) {
                              final prevMessage = _messages[index - 1];
                              if (prevMessage.senderId == message.senderId) {
                                // 같은 사람의 연속 메시지
                                final timeDiff = message.createdAt
                                    .difference(prevMessage.createdAt)
                                    .inMinutes;
                                if (timeDiff < 1) {
                                  showProfile = false; // 1분 이내면 프로필 숨김
                                }
                              }
                            }

                            return MessageBubble(
                              message: message,
                              isMe: isMe,
                              otherUserPhotoUrl: widget.chatRoom.otherUserPhotoUrl,
                              showProfile: showProfile,
                            );
                          },
                        ),
                ),

                // 입력창
                _buildMessageInput(),
              ],
            ),
    );
  }

  /// 빈 상태 (메시지 없음)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64.sp,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 16.h),
          Text(
            '첫 메시지를 보내보세요',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral500,
                ),
          ),
        ],
      ),
    );
  }

  /// 메시지 입력창
  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        child: Row(
          children: [
            // 이미지 첨부 버튼 (선택 사항)
            // IconButton(
            //   icon: Icon(Icons.add_photo_alternate, color: NewAppColor.neutral600),
            //   onPressed: () {
            //     // TODO: 이미지 첨부 기능
            //   },
            // ),
            // SizedBox(width: 8.w),

            // 입력 필드
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요',
                    hintStyle: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral400,
                          fontSize: 15.sp,
                        ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral900,
                        fontSize: 15.sp,
                      ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onChanged: (text) {
                    setState(() {
                      _hasText = text.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // 전송 버튼
            GestureDetector(
              onTap: (!_hasText || _isSending) ? null : _sendMessage,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: (!_hasText || _isSending)
                      ? NewAppColor.neutral300
                      : NewAppColor.primary600,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? Center(
                        child: SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
