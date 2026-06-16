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

    // 채팅방 나갈 때 배지 업데이트 (약간의 지연 후)
    Future.delayed(const Duration(milliseconds: 300), () {
      BadgeService.instance.updateBadge().then((_) {
        print('✅ CHAT_ROOM_SCREEN: 배지 업데이트 완료 (dispose)');
      }).catchError((e) {
        print('❌ CHAT_ROOM_SCREEN: 배지 업데이트 실패 - $e');
      });
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

      // 데이터베이스 업데이트 완료 대기
      await Future.delayed(const Duration(milliseconds: 300));

      // 배지 업데이트 (메시지 읽음)
      await BadgeService.instance.updateBadge();
      print('✅ CHAT_ROOM_SCREEN: 배지 업데이트 완료 (진입 시)');

      // 실시간 구독 시작
      _subscribeToMessages();

      // 스크롤을 맨 아래로 이동 (첫 진입 시 애니메이션 없이 즉시)
      _scrollToBottom(animate: false);
    } catch (e) {
      print('❌ CHAT_ROOM_SCREEN: 데이터 로드 실패 - $e');
      setState(() => _isLoading = false);
    }
  }

  /// 최신 메시지로 스크롤 (확실하게 작동)
  void _scrollToBottom({bool animate = true}) {
    // 즉시 스크롤 (애니메이션 없이)
    if (!animate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // 즉시 점프
          _performScroll(animate: false);
        }
      });
      // 한 번 더 확실하게 (UI 렌더링 완료 후)
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _scrollController.hasClients) {
          _performScroll(animate: false);
        }
      });
      return;
    }

    // 애니메이션과 함께 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _performScroll(animate: true);
      }
    });
  }

  /// 실제 스크롤 수행
  void _performScroll({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    // reverse: true이므로 minScrollExtent가 최신 메시지 위치 (0.0)
    final targetPosition = _scrollController.position.minScrollExtent;

    if (animate) {
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(targetPosition);
    }
  }

  /// 실시간 메시지 구독
  void _subscribeToMessages() {
    _subscription = _chatService.subscribeToMessages(
      widget.chatRoom.id,
      (newMessage) async {
        // 내가 보낸 메시지가 아니면 추가 (중복 방지)
        if (newMessage.senderId != _currentUserId) {
          setState(() {
            _messages.add(newMessage);
          });

          // 스크롤을 맨 아래로 이동
          _scrollToBottom();

          // 읽음 처리
          await _chatService.markAsRead(widget.chatRoom.id);

          // 데이터베이스 업데이트 완료 대기
          await Future.delayed(const Duration(milliseconds: 300));

          // 배지 업데이트 (새 메시지 읽음)
          await BadgeService.instance.updateBadge();
          print('✅ CHAT_ROOM_SCREEN: 배지 업데이트 완료 (실시간 메시지)');
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
      _scrollToBottom();

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
      // 1.2.0 C 방향: 캔버스 배경(메시지 영역), 흰 탑바/상품 정보/입력바
      backgroundColor: NewAppColor.canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: _showProfileDialog,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.chatRoom.otherUserName ?? '알 수 없음',
                style: FigmaTextStyles().cardTitle.copyWith(
                      color: NewAppColor.textStrong,
                      fontSize: 16.sp,
                    ),
              ),
              if (widget.chatRoom.otherUserChurch != null ||
                  widget.chatRoom.otherUserLocation != null) ...[
                SizedBox(height: 1.h),
                Text(
                  [
                    widget.chatRoom.otherUserChurch,
                    widget.chatRoom.otherUserLocation,
                  ].where((e) => e != null && e.isNotEmpty).join(' · '),
                  style: FigmaTextStyles().caption3.copyWith(
                        color: NewAppColor.textTertiary,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.ellipsisVertical,
                color: NewAppColor.textSecondary, size: 21.sp),
            onPressed: _showChatMenu,
            padding: EdgeInsets.zero,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.borderSoft,
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
                          reverse: true, // 최신 메시지가 하단에 고정
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            // reverse: true이므로 인덱스를 역순으로 접근
                            final reversedIndex = _messages.length - 1 - index;
                            final message = _messages[reversedIndex];
                            final isMe = message.senderId == _currentUserId;

                            // 이전 메시지와 같은 사람인지 확인 (프로필 표시 여부)
                            bool showProfile = true;
                            if (reversedIndex > 0) {
                              final prevMessage = _messages[reversedIndex - 1];
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

  /// 1.2.0 C 방향: 상품 정보 행 (skyTint 이미지 타일 + 상태 + 제목 + 가격 + chevron)
  Widget _buildProductInfoSection() {
    final isSeller = _currentUserId == widget.chatRoom.authorId;
    return InkWell(
      onTap: _navigateToProductDetail,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상품 이미지 타일 — 48×48 라운드 10 skyTint
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: widget.chatRoom.postImageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.network(
                        widget.chatRoom.postImageUrl!,
                        width: 48.w,
                        height: 48.w,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          LucideIcons.image,
                          color: NewAppColor.skyDeep,
                          size: 22.sp,
                        ),
                      ),
                    )
                  : Icon(
                      LucideIcons.image,
                      color: NewAppColor.skyDeep,
                      size: 22.sp,
                    ),
            ),
            SizedBox(width: 12.w),

            // 상품 정보 (상태 + 제목)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.chatRoom.postStatus != null)
                    GestureDetector(
                      onTap: () {
                        if (isSeller) {
                          _showStatusChangeBottomSheet();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('판매자만 거래 상태를 변경할 수 있습니다'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getStatusText(widget.chatRoom.postStatus!),
                            style: FigmaTextStyles().caption2.copyWith(
                                  color: NewAppColor.skyDeep,
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (isSeller)
                            Icon(
                              LucideIcons.chevronDown,
                              size: 13.sp,
                              color: NewAppColor.skyDeep,
                            ),
                        ],
                      ),
                    ),
                  SizedBox(height: 1.h),
                  // 상품명
                  Text(
                    widget.chatRoom.postTitle ?? '',
                    style: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.textBody,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // 가격 또는 '나눔'
            Text(
              widget.chatRoom.postPrice != null &&
                      widget.chatRoom.postPrice! > 0
                  ? '${_formatPrice(widget.chatRoom.postPrice!)}원'
                  : '나눔',
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              LucideIcons.chevronRight,
              size: 17.sp,
              color: NewAppColor.iconFaint,
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

  /// 1.2.0 C 방향: 거래 상태 변경 바텀시트
  void _showStatusChangeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ChatBottomSheet(
          title: '거래 상태 변경',
          children: [
            _buildStatusOption('판매중', 'active'),
            _buildStatusOption('예약중', 'reserved'),
            _buildStatusOption('판매완료', 'completed'),
          ],
        );
      },
    );
  }

  /// 1.2.0 C 방향: 상태 옵션 행 (선택=skyTint+skyDeep+check)
  Widget _buildStatusOption(String label, String status) {
    final isSelected = widget.chatRoom.postStatus == status;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _updateProductStatus(status);
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isSelected ? NewAppColor.skyTint : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: FigmaTextStyles().body2.copyWith(
                          color: isSelected
                              ? NewAppColor.skyDeep
                              : NewAppColor.neutral700,
                          fontSize: 15.sp,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                ),
                if (isSelected)
                  Icon(LucideIcons.check,
                      color: NewAppColor.skyDeep, size: 19.sp),
              ],
            ),
          ),
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
            LucideIcons.messageCircle,
            size: 56.sp,
            color: NewAppColor.iconFaint,
          ),
          SizedBox(height: 14.h),
          Text(
            '첫 메시지를 보내보세요',
            style: FigmaTextStyles().body3.copyWith(
                  color: NewAppColor.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  /// 1.2.0 C 방향: 입력바 (borderSoft 라운드 999 + 스카이 send 버튼 + 섀도)
  Widget _buildMessageInput() {
    final canSend = _hasText && !_isSending;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 입력 필드 — borderSoft 라운드 999 채움
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: NewAppColor.borderSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '메시지 보내기',
                    hintStyle: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 13.5.sp,
                        ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    isDense: true,
                  ),
                  style: FigmaTextStyles().body3.copyWith(
                        color: NewAppColor.textStrong,
                        fontSize: 13.5.sp,
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
            SizedBox(width: 10.w),
            // 전송 버튼 — 42 원형 skyPrimary + 섀도
            GestureDetector(
              onTap: canSend ? _sendMessage : null,
              child: Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: canSend
                      ? NewAppColor.skyPrimary
                      : NewAppColor.iconFaint,
                  shape: BoxShape.circle,
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color: NewAppColor.skyPrimary.withOpacity(0.32),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: _isSending
                    ? SizedBox(
                        width: 19.w,
                        height: 19.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        LucideIcons.send,
                        color: Colors.white,
                        size: 19.sp,
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

  /// 1.2.0 C 방향: 채팅방 신고 메뉴 시트 (단일 위험 행)
  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ChatBottomSheet(
          title: '채팅방 신고',
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 4.w, vertical: 10.h),
                    child: Row(
                      children: [
                        // 라운드 10 danger 타일
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: NewAppColor.dangerBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.flag,
                            color: NewAppColor.danger700,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: Text(
                            '신고하기',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.danger700,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 1.2.0 C 방향: 신고 사유 선택 시트 (라디오 + 사유 리스트 + 상세 + 취소/신고 버튼)
  void _showReportDialog() {
    ReportReason? selectedReason;
    final TextEditingController descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canSubmit = selectedReason != null;
            return _ChatBottomSheet(
              title: '채팅방 신고',
              subtitle: '신고 사유를 선택해주세요',
              children: [
                // 신고 사유 라디오 리스트
                ...ReportReason.values.map((reason) {
                  final isSelected = selectedReason == reason;
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setSheetState(() {
                            selectedReason = reason;
                          });
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NewAppColor.skyTint
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? LucideIcons.circleDot
                                    : LucideIcons.circle,
                                color: isSelected
                                    ? NewAppColor.skyDeep
                                    : NewAppColor.iconFaint,
                                size: 20.sp,
                              ),
                              SizedBox(width: 11.w),
                              Text(
                                reason.label,
                                style: FigmaTextStyles().body2.copyWith(
                                      color: isSelected
                                          ? NewAppColor.skyDeep
                                          : NewAppColor.neutral700,
                                      fontSize: 15.sp,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 12.h),
                // 상세 내용
                Text(
                  '상세 내용 (선택)',
                  style: FigmaTextStyles().body3.copyWith(
                        color: NewAppColor.textSecondary,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: '신고 사유를 자세히 작성해주세요',
                    hintStyle: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 13.5.sp,
                        ),
                    filled: true,
                    fillColor: NewAppColor.borderSoft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.all(13.w),
                    counterText: '',
                  ),
                  style: FigmaTextStyles().body3.copyWith(
                        color: NewAppColor.textStrong,
                        fontSize: 13.5.sp,
                      ),
                ),
                SizedBox(height: 18.h),
                // 취소 / 신고하기 버튼
                Row(
                  children: [
                    // 취소 — 보조 버튼
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: NewAppColor.borderStrong, width: 1.5),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '취소',
                            style: FigmaTextStyles().button2.copyWith(
                                  color: NewAppColor.textSecondary,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 11.w),
                    // 신고하기 — 위험(주) 버튼 (danger + 섀도)
                    Expanded(
                      child: InkWell(
                        onTap: canSubmit
                            ? () {
                                Navigator.pop(context);
                                _submitReport(
                                  selectedReason!,
                                  descriptionController.text.trim(),
                                );
                              }
                            : null,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: canSubmit
                                ? NewAppColor.danger700
                                : NewAppColor.iconFaint,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: canSubmit
                                ? [
                                    BoxShadow(
                                      color: NewAppColor.danger700
                                          .withOpacity(0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '신고하기',
                            style: FigmaTextStyles().button2.copyWith(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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

/// 1.2.0 C 방향: 공용 바텀시트 컨테이너 (핸들바 + 제목/부제 + 자식)
/// 디자인 정책 §2.3 — 상단 라운드 24, 핸들바 40×4, sheet 섀도 rgba(2,8,23,0.18)
class _ChatBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _ChatBottomSheet({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E020817),
              blurRadius: 40,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 핸들바
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 14.h),
                    decoration: BoxDecoration(
                      color: NewAppColor.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                // 제목
                Padding(
                  padding: EdgeInsets.fromLTRB(6.w, 2.h, 6.w, subtitle != null ? 4.h : 12.h),
                  child: Text(
                    title,
                    style: FigmaTextStyles().cardTitle.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                // 부제
                if (subtitle != null) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 12.h),
                    child: Text(
                      subtitle!,
                      style: FigmaTextStyles().caption1.copyWith(
                            color: NewAppColor.textTertiary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
                // 자식
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
