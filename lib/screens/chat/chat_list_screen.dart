import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/chat_models.dart';
import 'package:smart_yoram_app/services/chat_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/screens/chat/chat_room_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:smart_yoram_app/components/app_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 채팅 목록 화면
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> _filteredChatRooms = [];
  bool _isLoading = true;
  RealtimeChannel? _participantsChannel;
  int? _currentUserId; // 현재 사용자 ID 캐싱

  // 필터 상태
  String _selectedFilter = '전체'; // 전체, 판매, 구매, 안 읽은 채팅방

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCurrentUser();
    _loadChatRooms();
    _subscribeToParticipantsUpdates();
  }

  /// 현재 사용자 ID 캐싱 (한 번만 조회)
  Future<void> _initCurrentUser() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      final currentUser = userResponse.data;
      if (mounted) {
        setState(() {
          _currentUserId = currentUser?.id;
        });
      }
    } catch (e) {
      print('❌ CHAT_LIST_SCREEN: 사용자 조회 실패 - $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _participantsChannel?.unsubscribe();
    _chatService.unsubscribeAll();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포어그라운드로 돌아올 때 채팅 목록 새로고침
    if (state == AppLifecycleState.resumed) {
      _loadChatRooms();
    }
  }

  Future<void> _loadChatRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final chatRooms = await _chatService.getChatRooms();

      if (!mounted) return;
      setState(() {
        _chatRooms = chatRooms;
        // 캐시된 currentUserId 사용
        if (_currentUserId != null) {
          _applyFilter(_currentUserId!);
        } else {
          _filteredChatRooms = _chatRooms;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('❌ CHAT_LIST_SCREEN: 채팅방 목록 조회 실패 - $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 필터 적용
  void _applyFilter(int currentUserId) {
    switch (_selectedFilter) {
      case '전체':
        _filteredChatRooms = _chatRooms;
        break;
      case '판매':
        // 내가 게시글 작성자인 채팅방
        _filteredChatRooms = _chatRooms.where((room) {
          return room.authorId == currentUserId;
        }).toList();
        break;
      case '구매':
        // 내가 게시글 작성자가 아닌 채팅방
        _filteredChatRooms = _chatRooms.where((room) {
          return room.authorId != null && room.authorId != currentUserId;
        }).toList();
        break;
      case '안 읽은 채팅방':
        // 안 읽은 메시지가 있는 채팅방
        _filteredChatRooms = _chatRooms.where((room) {
          return room.unreadCount > 0;
        }).toList();
        break;
      default:
        _filteredChatRooms = _chatRooms;
    }
  }

  /// Realtime 구독: 채팅 참여자 테이블 변화 감지
  void _subscribeToParticipantsUpdates() {
    try {
      print('🔔 CHAT_LIST_SCREEN: Realtime 구독 시작');

      _participantsChannel = Supabase.instance.client
          .channel('chat_list_participants')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'p2p_chat_participants',
            callback: (payload) {
              print(
                  '🔔 CHAT_LIST_SCREEN: 참여자 테이블 변경 감지 - ${payload.eventType}');
              // 변경사항이 있으면 채팅 목록 새로고침
              _loadChatRooms();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'p2p_chat_rooms',
            callback: (payload) {
              print(
                  '🔔 CHAT_LIST_SCREEN: 채팅방 테이블 변경 감지 - ${payload.eventType}');
              // 변경사항이 있으면 채팅 목록 새로고침
              _loadChatRooms();
            },
          )
          .subscribe();

      print('✅ CHAT_LIST_SCREEN: Realtime 구독 완료');
    } catch (e) {
      print('❌ CHAT_LIST_SCREEN: Realtime 구독 실패 - $e');
    }
  }

  @override
  // 1.2.0 C 방향: 흰 헤더(타이틀 + 스카이 필터 칩) + 흰 목록
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: NewAppColor.skyPrimary,
              ),
            )
          : Column(
              children: [
                // 흰 헤더 영역 (타이틀 + 필터 칩) — 주소록/교회소식과 100% 동일 패턴
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 6.h,
                    left: 18.w,
                    right: 18.w,
                    bottom: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom:
                          BorderSide(width: 1, color: NewAppColor.borderSoft),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        child: Text(
                          '채팅',
                          style: FigmaTextStyles().pageTitle.copyWith(
                                color: NewAppColor.textStrong,
                                fontSize: 21.sp,
                              ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildFilterChips(),
                    ],
                  ),
                ),
                // 채팅 목록
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadChatRooms,
                    color: NewAppColor.skyPrimary,
                    child: SlidableAutoCloseBehavior(
                      child: CustomScrollView(
                        slivers: [
                          if (_chatRooms.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          else if (_filteredChatRooms.isEmpty)
                            SliverFillRemaining(
                              child: _buildFilteredEmptyState(),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final chatRoom = _filteredChatRooms[index];
                                  return _buildChatListTile(chatRoom);
                                },
                                childCount: _filteredChatRooms.length,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 1.2.0 C 방향: 스카이 필터 칩 (활성=skyPrimary 채움, 비활성=라인)
  // 부모 컨테이너가 좌우 18.w 패딩을 처리하므로 여기서는 추가 좌우 패딩 없음
  Widget _buildFilterChips() {
    final filters = ['전체', '판매', '구매', '안 읽은 채팅방'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: List.generate(filters.length, (index) {
            final filter = filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(right: index < filters.length - 1 ? 8.w : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                    if (_currentUserId != null) {
                      _applyFilter(_currentUserId!);
                    }
                  });
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected ? NewAppColor.skyPrimary : Colors.white,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: NewAppColor.borderStrong, width: 1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filter,
                    // height: 1 로 line-height 영향 제거 (잘림 방지)
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : NewAppColor.textSecondary,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -0.2,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
            );
          }),
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
            LucideIcons.messageCircle,
            size: 56.sp,
            color: NewAppColor.iconFaint,
          ),
          SizedBox(height: 14.h),
          Text(
            '아직 채팅이 없습니다',
            style: FigmaTextStyles().subtitle2.copyWith(
                  color: NewAppColor.textSecondary,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            '커뮤니티 게시글에서 문의하기를 눌러\n채팅을 시작해보세요',
            style: FigmaTextStyles().caption1.copyWith(
                  color: NewAppColor.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 필터 결과 없음 상태
  Widget _buildFilteredEmptyState() {
    String message = '';
    switch (_selectedFilter) {
      case '판매':
        message = '판매 중인 채팅방이 없습니다';
        break;
      case '구매':
        message = '구매 문의 채팅방이 없습니다';
        break;
      case '안 읽은 채팅방':
        message = '읽지 않은 채팅방이 없습니다';
        break;
      default:
        message = '채팅방이 없습니다';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 56.sp,
            color: NewAppColor.iconFaint,
          ),
          SizedBox(height: 14.h),
          Text(
            message,
            style: FigmaTextStyles().subtitle2.copyWith(
                  color: NewAppColor.textSecondary,
                ),
          ),
          SizedBox(height: 6.h),
          Text(
            '다른 필터를 선택해보세요',
            style: FigmaTextStyles().caption1.copyWith(
                  color: NewAppColor.textMuted,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 채팅방 삭제
  Future<void> _deleteChatRoom(ChatRoom chatRoom) async {
    // 삭제 확인 다이얼로그
    final shouldDelete = await AppAlertDialog.show(
      context: context,
      title: '채팅방 삭제',
      description: '이 채팅방을 삭제하시겠습니까?\n모든 메시지가 삭제됩니다.',
      confirmText: '삭제',
      cancelText: '취소',
      destructive: true,
    );

    if (shouldDelete != true) return;

    // 삭제 실행
    try {
      final response = await _chatService.deleteChatRoom(chatRoom.id);

      if (!mounted) return;

      if (response.success) {
        // 성공 시 목록에서 제거
        setState(() {
          _chatRooms.removeWhere((room) => room.id == chatRoom.id);
        });

        // 성공 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '채팅방이 삭제되었습니다',
              style: FigmaTextStyles().body2.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
            ),
            backgroundColor: NewAppColor.success600,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // 실패 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? '채팅방 삭제에 실패했습니다',
              style: FigmaTextStyles().body2.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
            ),
            backgroundColor: NewAppColor.danger600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '채팅방 삭제 중 오류가 발생했습니다',
            style: FigmaTextStyles().body2.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
          ),
          backgroundColor: NewAppColor.danger600,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 채팅방 목록 타일
  Widget _buildChatListTile(ChatRoom chatRoom) {
    return Slidable(
      key: Key('chat_room_${chatRoom.id}'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              _deleteChatRoom(chatRoom);
            },
            backgroundColor: NewAppColor.danger600,
            borderRadius: BorderRadius.zero,
            child: Icon(
              LucideIcons.trash2,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatRoomScreen(chatRoom: chatRoom),
            ),
          );
          _loadChatRooms();
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(width: 1, color: NewAppColor.borderHair),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이니셜 아바타 — 54×54 skyTint + skyDeep
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: chatRoom.otherUserPhotoUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: chatRoom.otherUserPhotoUrl!,
                              width: 54.w,
                              height: 54.w,
                              fit: BoxFit.cover,
                              placeholder: (_, __) =>
                                  _avatarInitial(chatRoom.otherUserName),
                              errorWidget: (_, __, ___) =>
                                  _avatarInitial(chatRoom.otherUserName),
                            ),
                          )
                        : _avatarInitial(chatRoom.otherUserName),
                  ),
                  // 안 읽은 메시지 배지
                  if (chatRoom.unreadCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        decoration: BoxDecoration(
                          color: NewAppColor.danger700,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 20.w,
                          minHeight: 20.h,
                        ),
                        child: Center(
                          child: Text(
                            chatRoom.unreadCount > 99
                                ? '99+'
                                : chatRoom.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 13.w),
              // 채팅방 정보
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            chatRoom.otherUserName ?? '알 수 없음',
                            style: FigmaTextStyles().cardTitleSm.copyWith(
                                  color: NewAppColor.textStrong,
                                  fontSize: 15.5.sp,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // 안 읽은 채팅방은 시간도 skyDeep + 600 강조
                        Text(
                          chatRoom.formattedTime,
                          style: FigmaTextStyles().caption2.copyWith(
                                color: chatRoom.unreadCount > 0
                                    ? NewAppColor.skyDeep
                                    : NewAppColor.textTertiary,
                                fontSize: 11.5.sp,
                                fontWeight: chatRoom.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    // 게시글 태그 칩
                    if (chatRoom.postTitle != null &&
                        chatRoom.postTitle!.isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.borderSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.tag,
                              size: 11.sp,
                              color: NewAppColor.textMuted,
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: Text(
                                chatRoom.postTitle!,
                                style: FigmaTextStyles().badgeSm.copyWith(
                                      color: NewAppColor.textMuted,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 5.h),
                    // 마지막 메시지 — 안 읽은 경우 textBody/600 강조
                    Text(
                      chatRoom.lastMessage ?? '새 채팅방',
                      style: FigmaTextStyles().body3.copyWith(
                            color: chatRoom.unreadCount > 0
                                ? NewAppColor.textBody
                                : NewAppColor.textTertiary,
                            fontSize: 13.5.sp,
                            fontWeight: chatRoom.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1.2.0: 이름 첫 글자 이니셜 아바타 (skyDeep 글자)
  Widget _avatarInitial(String? name) {
    final initial = (name != null && name.isNotEmpty) ? name[0] : '?';
    return Text(
      initial,
      style: TextStyle(
        color: NewAppColor.skyDeep,
        fontSize: 19.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard',
      ),
    );
  }
}
