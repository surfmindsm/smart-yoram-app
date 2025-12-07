import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/report_service.dart';
import 'package:smart_yoram_app/services/badge_service.dart';
import 'package:smart_yoram_app/models/report_model.dart';
import 'package:smart_yoram_app/widgets/chat/message_bubble.dart';
import 'package:smart_yoram_app/widgets/profile_info_dialog.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';
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
  final ReportService _reportService = ReportService();
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

    // 채팅방 나갈 때 배지 업데이트
    BadgeService.instance.updateBadge().catchError((e) {
      print('❌ CHAT_ROOM_SCREEN: 배지 업데이트 실패 - $e');
    });

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

      // 배지 업데이트 (메시지 읽음)
      BadgeService.instance.updateBadge().catchError((e) {
        print('❌ CHAT_ROOM_SCREEN: 배지 업데이트 실패 - $e');
      });

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

          // 배지 업데이트 (새 메시지 읽음)
          BadgeService.instance.updateBadge().catchError((e) {
            print('❌ CHAT_ROOM_SCREEN: 배지 업데이트 실패 - $e');
          });
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
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: NewAppColor.neutral100,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showProfileDialog,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상대방 이름
              Text(
                widget.chatRoom.otherUserName ?? '알 수 없음',
                style: FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              // 교회/지역 정보
              if (widget.chatRoom.otherUserChurch != null ||
                  widget.chatRoom.otherUserLocation != null)
                Text(
                  [
                    widget.chatRoom.otherUserChurch,
                    widget.chatRoom.otherUserLocation,
                  ].where((e) => e != null && e.isNotEmpty).join(' · '),
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
        actions: [
          // 더보기 버튼
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showChatMenu,
            padding: EdgeInsets.zero,
          ),
        ],
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
                // 상품 정보 섹션 (있는 경우만)
                if (widget.chatRoom.postTitle != null ||
                    widget.chatRoom.postImageUrl != null)
                  _buildProductInfoSection(),

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
                              otherUserPhotoUrl:
                                  widget.chatRoom.otherUserPhotoUrl,
                              showProfile: showProfile,
                              onProfileTap: isMe ? null : _showProfileDialog,
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

  /// 상품 정보 섹션
  Widget _buildProductInfoSection() {
    return GestureDetector(
      onTap: _navigateToProductDetail,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: NewAppColor.neutral100,
          border: Border(
            bottom: BorderSide(
              color: NewAppColor.neutral200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            if (widget.chatRoom.postImageUrl != null)
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: NewAppColor.neutral200,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: Image.network(
                    widget.chatRoom.postImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image,
                        color: NewAppColor.neutral400,
                        size: 20.sp,
                      );
                    },
                  ),
                ),
              ),
            if (widget.chatRoom.postImageUrl != null) SizedBox(width: 12.w),

            // 상품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 거래 상태
                  if (widget.chatRoom.postStatus != null)
                    GestureDetector(
                      onTap: () {
                        // 판매자만 상태 변경 가능
                        if (_currentUserId == widget.chatRoom.authorId) {
                          // 상태 변경 바텀시트 표시 (상품 상세 이동 방지)
                          _showStatusChangeBottomSheet();
                        } else {
                          // 판매자가 아닌 경우 안내 메시지
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('판매자만 거래 상태를 변경할 수 있습니다'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 4.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getStatusText(widget.chatRoom.postStatus!),
                              style: FigmaTextStyles().caption2.copyWith(
                                    color: NewAppColor.neutral700,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            // 판매자인 경우만 드롭다운 아이콘 표시
                            if (_currentUserId == widget.chatRoom.authorId)
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: 16.sp,
                                color: NewAppColor.neutral700,
                              ),
                          ],
                        ),
                      ),
                    ),

                  // 상품명
                  Text(
                    widget.chatRoom.postTitle ?? '',
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral900,
                          fontSize: 13.sp,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 가격
                  if (widget.chatRoom.postPrice != null)
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        '${_formatPrice(widget.chatRoom.postPrice!)}원',
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 거래 상태 텍스트
  String _getStatusText(String status) {
    switch (status) {
      case 'active':
      case 'available':
        return '판매중';
      case 'reserved':
        return '예약중';
      case 'sold':
      case 'completed':
        return '판매완료';
      default:
        return '판매중'; // 기본값
    }
  }

  /// 가격 포맷팅 (천 단위 쉼표)
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// 상품 상세페이지로 이동
  void _navigateToProductDetail() {
    if (widget.chatRoom.postId == null || widget.chatRoom.postTable == null) {
      return;
    }

    // CommunityDetailScreen으로 직접 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityDetailScreen(
          postId: widget.chatRoom.postId!,
          tableName: widget.chatRoom.postTable!,
          categoryTitle: _getCategoryTitle(widget.chatRoom.postTable!),
        ),
      ),
    );
  }

  /// postTable에서 카테고리 제목 변환
  String _getCategoryTitle(String postTable) {
    switch (postTable) {
      case 'community_sharing':
        return '무료나눔/물품판매';
      case 'community_requests':
        return '물품 요청';
      case 'job_posts':
        return '사역자 모집';
      case 'community_music_teams':
        return '행사팀 모집';
      case 'music_team_seekers':
        return '행사팀 지원';
      case 'church_news':
        return '교회 소식';
      default:
        return '게시글';
    }
  }

  /// 상태 변경 바텀시트 표시
  void _showStatusChangeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.neutral300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 20.h),

                // 제목
                Text(
                  '거래 상태 변경',
                  style: FigmaTextStyles().subtitle1.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                ),

                SizedBox(height: 20.h),

                // 상태 목록
                _buildStatusOption('판매중', 'active'),
                _buildStatusOption('예약중', 'reserved'),
                _buildStatusOption('판매완료', 'completed'),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 상태 옵션 버튼
  Widget _buildStatusOption(String label, String status) {
    final isSelected = widget.chatRoom.postStatus == status;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _updateProductStatus(status);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        color: isSelected ? NewAppColor.primary100 : Colors.white,
        child: Row(
          children: [
            Text(
              label,
              style: FigmaTextStyles().body1.copyWith(
                    fontSize: 16.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? NewAppColor.primary600
                        : NewAppColor.neutral900,
                  ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check,
                color: NewAppColor.primary600,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }

  /// 상품 상태 업데이트
  Future<void> _updateProductStatus(String newStatus) async {
    if (widget.chatRoom.postId == null || widget.chatRoom.postTable == null) {
      return;
    }

    try {
      // Supabase 업데이트
      await Supabase.instance.client
          .from(widget.chatRoom.postTable!)
          .update({'status': newStatus}).eq('id', widget.chatRoom.postId!);

      // 성공 메시지
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('거래 상태가 ${_getStatusText(newStatus)}(으)로 변경되었습니다'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // 화면 새로고침
      setState(() {
        // chatRoom 객체 업데이트는 필요 없음 (다음 번 진입 시 자동으로 반영됨)
      });
    } catch (e) {
      print('❌ CHAT_ROOM_SCREEN: 상태 업데이트 실패 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('상태 변경에 실패했습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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
        color: NewAppColor.neutral100,
        border: Border(
          top: BorderSide(
            color: NewAppColor.transparent,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        child: Row(
          children: [
            // 입력 필드
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '메시지 보내기',
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
                      ? NewAppColor.transparent
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
                            color: NewAppColor.neutral500,
                          ),
                        ),
                      )
                    : Icon(
                        _hasText ? LucideIcons.send : LucideIcons.send,
                        color: _hasText
                            ? NewAppColor.white
                            : NewAppColor.neutral300,
                        size: 20.sp,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상대방 프로필 다이얼로그 표시
  void _showProfileDialog() {
    ProfileInfoDialog.show(
      context,
      name: widget.chatRoom.otherUserName ?? '알 수 없음',
      churchName: widget.chatRoom.otherUserChurch,
      location: widget.chatRoom.otherUserLocation,
      churchAddress: widget.chatRoom.otherUserChurchAddress,
      profileImageUrl: widget.chatRoom.otherUserPhotoUrl,
    );
  }

  /// 채팅 메뉴 표시
  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  margin: EdgeInsets.only(top: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: NewAppColor.neutral300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),

                SizedBox(height: 20.h),

                // 제목
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '채팅방 신고',
                      style: FigmaTextStyles().subtitle1.copyWith(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: NewAppColor.neutral900,
                          ),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // 신고하기
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: NewAppColor.danger100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.report_outlined,
                              color: NewAppColor.danger600,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            '신고하기',
                            style: FigmaTextStyles().body1.copyWith(
                                  fontSize: 15.sp,
                                  color: NewAppColor.danger600,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 8.h),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 신고하기 다이얼로그 표시
  void _showReportDialog() {
    ReportReason? selectedReason;
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 핸들
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 12.h),
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: NewAppColor.neutral300,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // 제목
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          '채팅방 신고',
                          style: FigmaTextStyles().subtitle1.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                                color: NewAppColor.neutral900,
                              ),
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Text(
                          '신고 사유를 선택해주세요',
                          style: FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral600,
                                fontSize: 14.sp,
                              ),
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 신고 사유 선택
                      ...ReportReason.values.map((reason) {
                        final isSelected = selectedReason == reason;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 16.h,
                            ),
                            color: isSelected
                                ? NewAppColor.primary100
                                : Colors.white,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? NewAppColor.primary600
                                      : NewAppColor.neutral400,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  reason.label,
                                  style: FigmaTextStyles().body1.copyWith(
                                        fontSize: 15.sp,
                                        color: isSelected
                                            ? NewAppColor.primary600
                                            : NewAppColor.neutral900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      SizedBox(height: 16.h),

                      // 상세 내용 입력
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '상세 내용 (선택)',
                              style: FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.neutral700,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: descriptionController,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                hintText: '신고 사유를 자세히 작성해주세요',
                                hintStyle: FigmaTextStyles().body2.copyWith(
                                      color: NewAppColor.neutral400,
                                    ),
                                filled: true,
                                fillColor: NewAppColor.neutral100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.all(12.w),
                              ),
                              style: FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // 버튼
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  side: BorderSide(
                                    color: NewAppColor.neutral300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: Text(
                                  '취소',
                                  style: FigmaTextStyles().button1.copyWith(
                                        color: NewAppColor.neutral700,
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: selectedReason == null
                                    ? null
                                    : () {
                                        Navigator.pop(context);
                                        _submitReport(
                                          selectedReason!,
                                          descriptionController.text.trim(),
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: NewAppColor.danger600,
                                  disabledBackgroundColor:
                                      NewAppColor.neutral300,
                                  padding: EdgeInsets.symmetric(vertical: 14.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  '신고하기',
                                  style: FigmaTextStyles().button1.copyWith(
                                        color: selectedReason == null
                                            ? NewAppColor.neutral500
                                            : Colors.white,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 신고 제출
  Future<void> _submitReport(ReportReason reason, String description) async {
    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _reportService.createReport(
        reportedType: ReportType.chat,
        reportedId: widget.chatRoom.id,
        reportedTable: 'chat_rooms',
        reason: reason,
        description: description.isEmpty ? null : description,
      );

      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 결과 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: response.success
                ? NewAppColor.success600
                : NewAppColor.danger600,
          ),
        );
      }
    } catch (e) {
      // 로딩 닫기
      if (mounted) Navigator.pop(context);

      // 에러 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('신고 접수 중 오류가 발생했습니다: $e'),
            backgroundColor: NewAppColor.danger600,
          ),
        );
      }
    }
  }
}
