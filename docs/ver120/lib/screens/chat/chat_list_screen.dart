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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 고정된 AppBar
                Container(
                  color: NewAppColor.transparent,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Container(
                          height: 56.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            children: [
                              Text(
                                '채팅',
                                style: FigmaTextStyles().header1.copyWith(
                                      color: NewAppColor.neutral900,
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 스크롤 가능한 영역
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadChatRooms,
                    child: SlidableAutoCloseBehavior(
                      child: CustomScrollView(
                        slivers: [
                          // 필터 칩 (항상 표시)
                          SliverToBoxAdapter(
                            child: _buildFilterChips(),
                          ),
                          // 채팅방이 아예 없을 때
                          if (_chatRooms.isEmpty)
                            SliverFillRemaining(
                              child: _buildEmptyState(),
                            )
                          // 채팅방은 있지만 필터 결과가 없을 때
                          else if (_filteredChatRooms.isEmpty)
                            SliverFillRemaining(
                              child: _buildFilteredEmptyState(),
                            )
                          // 채팅방 리스트
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

  /// 필터 칩
  Widget _buildFilterChips() {
    final filters = ['전체', '판매', '구매', '안 읽은 채팅방'];

    return Container(
      color: NewAppColor.transparent,
      child: Column(
        children: [
          Container(
            height: 56.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (context, index) => SizedBox(width: 8.w),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedFilter == filter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                      // 캐시된 currentUserId 사용 (불필요한 API 호출 제거)
                      if (_currentUserId != null) {
                        _applyFilter(_currentUserId!);
                      }
                    });
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NewAppColor.primary600
                          : NewAppColor.neutral200,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? NewAppColor.primary600
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: FigmaTextStyles().body2.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : NewAppColor.neutral700,
                              fontSize: 14.sp,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            Icons.search_off,
            size: 80.sp,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 24.h),
          Text(
            message,
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral600,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            '다른 필터를 선택해보세요',
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
      ),
    );
  }
}
