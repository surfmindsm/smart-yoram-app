import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart' hide IconButton;
import '../widget/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

class PrayerRequest {
  final String id;
  final String title;
  final String content;
  final String category; // 'personal', 'family', 'church', 'mission'
  final DateTime createdAt;
  final bool isPrivate;
  final String status; // 'active', 'answered', 'closed'

  PrayerRequest({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isPrivate = false,
    this.status = 'active',
  });
}

class VisitationRequest {
  final String id;
  final String requestType; // 'visitation', 'counseling', 'prayer'
  final String reason;
  final String preferredDate;
  final String preferredTime;
  final String contactInfo;
  final DateTime createdAt;
  final String status; // 'pending', 'scheduled', 'completed'

  VisitationRequest({
    required this.id,
    required this.requestType,
    required this.reason,
    required this.preferredDate,
    required this.preferredTime,
    required this.contactInfo,
    required this.createdAt,
    this.status = 'pending',
  });
}

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;

  List<PrayerRequest> myPrayerRequests = [];
  List<PrayerRequest> sharedPrayerRequests = [];
  List<VisitationRequest> myVisitationRequests = [];
  bool isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // 임시 데이터 생성
      _generateSampleData();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  void _generateSampleData() {
    final now = DateTime.now();
    
    myPrayerRequests = [
      PrayerRequest(
        id: '1',
        title: '건강 회복',
        content: '어머니의 건강 회복을 위해 기도 부탁드립니다.',
        category: 'family',
        createdAt: now.subtract(const Duration(days: 5)),
        isPrivate: false,
      ),
      PrayerRequest(
        id: '2',
        title: '취업 준비',
        content: '좋은 직장을 구할 수 있도록 기도해주세요.',
        category: 'personal',
        createdAt: now.subtract(const Duration(days: 10)),
        isPrivate: true,
      ),
      PrayerRequest(
        id: '3',
        title: '가족 화목',
        content: '가족 간의 갈등이 해결되고 화목할 수 있도록',
        category: 'family',
        createdAt: now.subtract(const Duration(days: 15)),
        isPrivate: false,
        status: 'answered',
      ),
    ];

    sharedPrayerRequests = [
      PrayerRequest(
        id: '4',
        title: '교회 부흥',
        content: '우리 교회가 더욱 부흥하고 많은 영혼들이 구원받도록',
        category: 'church',
        createdAt: now.subtract(const Duration(days: 3)),
        isPrivate: false,
      ),
      PrayerRequest(
        id: '5',
        title: '선교 사역',
        content: '해외 선교사님들의 사역을 위해 기도해주세요',
        category: 'mission',
        createdAt: now.subtract(const Duration(days: 7)),
        isPrivate: false,
      ),
    ];

    myVisitationRequests = [
      VisitationRequest(
        id: '1',
        requestType: 'visitation',
        reason: '새신자 심방',
        preferredDate: '2024년 2월 15일',
        preferredTime: '오후 2시',
        contactInfo: '010-1234-5678',
        createdAt: now.subtract(const Duration(days: 2)),
        status: 'scheduled',
      ),
      VisitationRequest(
        id: '2',
        requestType: 'counseling',
        reason: '신앙 상담',
        preferredDate: '2024년 2월 20일',
        preferredTime: '오후 7시',
        contactInfo: '010-1234-5678',
        createdAt: now.subtract(const Duration(days: 5)),
        status: 'pending',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '중보 기도',
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.plus,
                color: NewAppColor.textStrong, size: 22.sp),
            onPressed: () {
              _showAddDialog();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: Container(
            width: double.infinity,
            height: 52.h,
            color: Colors.white,
            child: Row(
              children: [
                // 내 기도 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                      setState(() {
                        _currentTabIndex = 0;
                      });
                    },
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            width: _currentTabIndex == 0 ? 2.0 : 1,
                            color: _currentTabIndex == 0
                                ? NewAppColor.skyPrimary
                                : NewAppColor.borderHair,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '내 기도',
                          textAlign: TextAlign.center,
                          style: const FigmaTextStyles().title4.copyWith(
                            color: _currentTabIndex == 0
                                ? NewAppColor.skyPrimary
                                : NewAppColor.textMuted,
                            fontWeight: _currentTabIndex == 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 공동 기도 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                      setState(() {
                        _currentTabIndex = 1;
                      });
                    },
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            width: _currentTabIndex == 1 ? 2.0 : 1,
                            color: _currentTabIndex == 1
                                ? NewAppColor.skyPrimary
                                : NewAppColor.borderHair,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '공동 기도',
                          textAlign: TextAlign.center,
                          style: const FigmaTextStyles().title4.copyWith(
                            color: _currentTabIndex == 1
                                ? NewAppColor.skyPrimary
                                : NewAppColor.textMuted,
                            fontWeight: _currentTabIndex == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 심방 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(2);
                      setState(() {
                        _currentTabIndex = 2;
                      });
                    },
                    child: Container(
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            width: _currentTabIndex == 2 ? 2.0 : 1,
                            color: _currentTabIndex == 2
                                ? NewAppColor.skyPrimary
                                : NewAppColor.borderHair,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '심방',
                          textAlign: TextAlign.center,
                          style: const FigmaTextStyles().title4.copyWith(
                            color: _currentTabIndex == 2
                                ? NewAppColor.skyPrimary
                                : NewAppColor.textMuted,
                            fontWeight: _currentTabIndex == 2
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: NewAppColor.canvasAlt,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPrayerTab(),
          _buildSharedPrayerTab(),
          _buildVisitationTab(),
        ],
      ),
    );
  }

  Widget _buildMyPrayerTab() {
    if (isLoading) {
      return const LoadingWidget();
    }

    if (myPrayerRequests.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.church,
        title: '등록된 기도제목이 없습니다',
        subtitle: '처음 기도제목을 등록해보세요',
      );
    }

    return Container(
      color: NewAppColor.canvasAlt,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: myPrayerRequests.length,
          itemBuilder: (context, index) {
            final request = myPrayerRequests[index];
            return _buildPrayerCard(request, isMyRequest: true);
          },
        ),
      ),
    );
  }

  Widget _buildSharedPrayerTab() {
    if (isLoading) {
      return const LoadingWidget();
    }
    
    if (sharedPrayerRequests.isEmpty) {
      return const EmptyStateWidget(
        icon: LucideIcons.users,
        title: '공동 기도제목이 없습니다',
        subtitle: '공동체와 함께 기도해보세요',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: sharedPrayerRequests.length,
        itemBuilder: (context, index) {
          final request = sharedPrayerRequests[index];
          return _buildPrayerCard(request, isMyRequest: false);
        },
      ),
    );
  }

  Widget _buildVisitationTab() {
    if (isLoading) {
      return const LoadingWidget();
    }

    return Container(
      color: NewAppColor.canvasAlt,
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // 심방 신청 안내
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              margin: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.info,
                    color: NewAppColor.skyPrimary,
                    size: 24.r,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '심방 신청',
                    style: const FigmaTextStyles().title4.copyWith(
                      color: NewAppColor.skyPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '목사님이나 교역자의 심방이 필요하시면\n언제든 신청해주세요',
                    textAlign: TextAlign.center,
                    style: const FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          
            // 심방 신청 목록
            Expanded(
              child: myVisitationRequests.isEmpty
                  ? const EmptyStateWidget(
                      icon: LucideIcons.house,
                      title: '심방 신청 내역이 없습니다',
                      subtitle: '목사님께 심방을 신청해보세요',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: myVisitationRequests.length,
                      itemBuilder: (context, index) {
                        final request = myVisitationRequests[index];
                        return _buildVisitationCard(request);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerCard(PrayerRequest request, {required bool isMyRequest}) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getCategoryColor(request.category),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getCategoryText(request.category),
                  style: const FigmaTextStyles().caption1.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              if (request.isPrivate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.textTertiary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '비공개',
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              const Spacer(),
              if (request.status == 'answered')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.skyPrimary,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '응답됨',
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              if (isMyRequest)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editPrayerRequest(request);
                        break;
                      case 'delete':
                        _deletePrayerRequest(request);
                        break;
                      case 'answered':
                        _markAsAnswered(request);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 16),
                          SizedBox(width: 8),
                          Text('수정'),
                        ],
                      ),
                    ),
                    if (request.status != 'answered')
                      const PopupMenuItem(
                        value: 'answered',
                        child: Row(
                          children: [
                            Icon(LucideIcons.check, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('응답됨으로 표시'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(LucideIcons.trash2,
                              size: 16, color: NewAppColor.danger700),
                          const SizedBox(width: 8),
                          Text('삭제',
                              style: TextStyle(color: NewAppColor.danger700)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            request.title,
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.textStrong,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            request.content,
            style: const FigmaTextStyles().body2.copyWith(
              color: NewAppColor.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 14.r,
                color: NewAppColor.textMuted,
              ),
              SizedBox(width: 4.w),
              Text(
                _formatDate(request.createdAt),
                style: const FigmaTextStyles().caption1.copyWith(
                  color: NewAppColor.textMuted,
                ),
              ),
              const Spacer(),
              if (!isMyRequest)
                GestureDetector(
                  onTap: () => _prayForRequest(request),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.heart,
                          size: 14.r,
                          color: NewAppColor.skyPrimary,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '기도해요',
                          style: const FigmaTextStyles().caption1.copyWith(
                            color: NewAppColor.skyPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitationCard(VisitationRequest request) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getRequestTypeColor(request.requestType),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getRequestTypeText(request.requestType),
                  style: const FigmaTextStyles().caption1.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _getStatusText(request.status),
                  style: const FigmaTextStyles().caption1.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '신청 사유: ${request.reason}',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.textStrong,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '희망 날짜: ${request.preferredDate}',
            style: const FigmaTextStyles().body2.copyWith(
              color: NewAppColor.textSecondary,
            ),
          ),
          Text(
            '희망 시간: ${request.preferredTime}',
            style: const FigmaTextStyles().body2.copyWith(
              color: NewAppColor.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '신청일: ${_formatDate(request.createdAt)}',
            style: const FigmaTextStyles().caption1.copyWith(
              color: NewAppColor.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'personal':
        return NewAppColor.skyPrimary;
      case 'family':
        return NewAppColor.skyPrimary;
      case 'church':
        return NewAppColor.secondary600;
      case 'mission':
        return NewAppColor.warning600;
      default:
        return NewAppColor.textMuted;
    }
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'personal':
        return '개인';
      case 'family':
        return '가족';
      case 'church':
        return '교회';
      case 'mission':
        return '선교';
      default:
        return '기타';
    }
  }

  Color _getRequestTypeColor(String type) {
    switch (type) {
      case 'visitation':
        return NewAppColor.skyPrimary;
      case 'counseling':
        return NewAppColor.skyPrimary;
      case 'prayer':
        return NewAppColor.secondary600;
      default:
        return NewAppColor.textMuted;
    }
  }

  String _getRequestTypeText(String type) {
    switch (type) {
      case 'visitation':
        return '심방';
      case 'counseling':
        return '상담';
      case 'prayer':
        return '기도';
      default:
        return '기타';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return NewAppColor.warning600;
      case 'scheduled':
        return NewAppColor.skyPrimary;
      case 'completed':
        return NewAppColor.skyPrimary;
      default:
        return NewAppColor.textMuted;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'scheduled':
        return '예정됨';
      case 'completed':
        return '완료됨';
      default:
        return '알 수 없음';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  void _showAddDialog() {
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.heart,
          label: '기도제목 등록',
          onTap: _showAddPrayerDialog,
        ),
        AppMenuItem(
          icon: LucideIcons.house,
          label: '심방 신청',
          onTap: _showAddVisitationDialog,
        ),
      ],
    );
  }

  void _showAddPrayerDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedCategory = 'personal';
    bool isPrivate = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('기도제목 등록'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '분류',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'personal', child: Text('개인')),
                    DropdownMenuItem(value: 'family', child: Text('가족')),
                    DropdownMenuItem(value: 'church', child: Text('교회')),
                    DropdownMenuItem(value: 'mission', child: Text('선교')),
                  ],
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('비공개로 등록'),
                  subtitle: const Text('다른 교인들에게 공개하지 않습니다'),
                  value: isPrivate,
                  onChanged: (value) => setState(() => isPrivate = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    contentController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('기도제목이 등록되었습니다')),
                  );
                }
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVisitationDialog() {
    final reasonController = TextEditingController();
    String requestType = 'visitation';
    String preferredDate = '';
    String preferredTime = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('심방 신청'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: requestType,
                  decoration: const InputDecoration(
                    labelText: '신청 유형',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'visitation', child: Text('심방')),
                    DropdownMenuItem(value: 'counseling', child: Text('상담')),
                    DropdownMenuItem(value: 'prayer', child: Text('기도')),
                  ],
                  onChanged: (value) => setState(() => requestType = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: '신청 사유',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '희망 날짜',
                    hintText: '예: 2024년 2월 15일',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => preferredDate = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: '희망 시간',
                    hintText: '예: 오후 2시',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => preferredTime = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.isNotEmpty &&
                    preferredDate.isNotEmpty &&
                    preferredTime.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('심방 신청이 접수되었습니다')),
                  );
                }
              },
              child: const Text('신청'),
            ),
          ],
        ),
      ),
    );
  }

  void _editPrayerRequest(PrayerRequest request) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${request.title} 수정 기능은 준비 중입니다')),
    );
  }

  Future<void> _deletePrayerRequest(PrayerRequest request) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '기도제목을 삭제할까요?',
      description: '${request.title}을(를) 삭제합니다.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );
    if (ok == true && mounted) {
      setState(() {
        myPrayerRequests.removeWhere((r) => r.id == request.id);
      });
      AppToast.success(context, '기도제목이 삭제되었습니다');
    }
  }

  void _markAsAnswered(PrayerRequest request) {
    setState(() {
      final index = myPrayerRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        myPrayerRequests[index] = PrayerRequest(
          id: request.id,
          title: request.title,
          content: request.content,
          category: request.category,
          createdAt: request.createdAt,
          isPrivate: request.isPrivate,
          status: 'answered',
        );
      }
    });
    AppToast.success(context, '기도제목이 응답됨으로 표시되었습니다');
  }

  void _prayForRequest(PrayerRequest request) {
    AppToast.show(context, '${request.title}을 위해 기도합니다 🙏');
  }
}
