import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/screens/chat/chat_room_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 채팅 목록 화면
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  @override
  void dispose() {
    _chatService.unsubscribeAll();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    setState(() => _isLoading = true);

    try {
      final chatRooms = await _chatService.getChatRooms();

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ CHAT_LIST_SCREEN: 채팅방 목록 조회 실패 - $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '채팅',
          style: FigmaTextStyles().header1.copyWith(
                color: NewAppColor.neutral900,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
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
          : _chatRooms.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: NewAppColor.neutral200,
                      indent: 72.w,
                    ),
                    itemBuilder: (context, index) {
                      final chatRoom = _chatRooms[index];
                      return _buildChatListTile(chatRoom);
                    },
                  ),
                ),
    );
  }

  /// 빈 상태 (채팅방 없음)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80.sp,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 24.h),
          Text(
            '아직 채팅이 없습니다',
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral600,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            '커뮤니티 게시글에서 문의하기를 눌러\n채팅을 시작해보세요',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral500,
                  fontSize: 14.sp,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 채팅방 목록 타일
  Widget _buildChatListTile(ChatRoom chatRoom) {
    return InkWell(
      onTap: () async {
        // 채팅방으로 이동
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
          ),
        );

        // 돌아왔을 때 목록 새로고침
        _loadChatRooms();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 이미지
            Stack(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: NewAppColor.neutral200,
                    shape: BoxShape.circle,
                  ),
                  child: chatRoom.otherUserPhotoUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: chatRoom.otherUserPhotoUrl!,
                            width: 56.w,
                            height: 56.w,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              Icons.person,
                              color: NewAppColor.neutral500,
                              size: 28.sp,
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: NewAppColor.neutral500,
                              size: 28.sp,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: NewAppColor.neutral500,
                          size: 28.sp,
                        ),
                ),
                // 안 읽은 메시지 배지
                if (chatRoom.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: NewAppColor.danger600,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.w,
                      ),
                      child: Center(
                        child: Text(
                          chatRoom.unreadCount > 99
                              ? '99+'
                              : chatRoom.unreadCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            SizedBox(width: 12.w),

            // 채팅방 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상대방 이름 + 시간
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.otherUserName ?? '알 수 없음',
                          style: FigmaTextStyles().body1.copyWith(
                                color: NewAppColor.neutral900,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        chatRoom.formattedTime,
                        style: FigmaTextStyles().caption2.copyWith(
                              color: NewAppColor.neutral500,
                              fontSize: 12.sp,
                            ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // 게시글 제목 (작은 글씨)
                  if (chatRoom.postTitle != null &&
                      chatRoom.postTitle!.isNotEmpty) ...[
                    Text(
                      chatRoom.postTitle!,
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral600,
                            fontSize: 12.sp,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                  ],

                  // 마지막 메시지
                  Text(
                    chatRoom.lastMessage ?? '새 채팅방',
                    style: FigmaTextStyles().body2.copyWith(
                          color: chatRoom.unreadCount > 0
                              ? NewAppColor.neutral900
                              : NewAppColor.neutral600,
                          fontSize: 14.sp,
                          fontWeight: chatRoom.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
