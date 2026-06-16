import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart' hide IconButton;
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../models/offering.dart';
import '../services/offering_service.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 내 헌금 내역 — 1.2.0 C 방향
class OfferingHistoryScreen extends StatefulWidget {
  const OfferingHistoryScreen({super.key});

  @override
  State<OfferingHistoryScreen> createState() => _OfferingHistoryScreenState();
}

class _OfferingHistoryScreenState extends State<OfferingHistoryScreen> {
  final _offeringService = OfferingService();
  final _authService = AuthService();
  final _memberService = MemberService();

  List<Offering> offerings = [];
  bool isLoading = true;
  int? memberId;

  int? selectedYear;
  List<int> availableYears = [];
  double totalAmount = 0.0;
  Map<String, double> categoryTotals = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadMemberId();
    if (memberId != null) {
      await _loadAvailableYears();
      await _loadOfferings();
    }
  }

  Future<void> _loadMemberId() async {
    try {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        final currentUser = userResponse.data!;
        final membersResponse = await _memberService.getMembers(limit: 1000);
        if (membersResponse.success && membersResponse.data != null) {
          final members = membersResponse.data!;
          final currentMember = members.firstWhere(
            (member) => member.email == currentUser.email,
            orElse: () => throw Exception('교인 정보를 찾을 수 없습니다'),
          );
          setState(() => memberId = currentMember.id);
        }
      }
    } catch (e) {
      print('❌ 교인 정보 로드 실패: $e');
      if (mounted) {
        AppToast.error(context, '교인 정보를 불러올 수 없습니다');
      }
    }
  }

  Future<void> _loadAvailableYears() async {
    if (memberId == null) return;
    try {
      final years = await _offeringService.getAvailableYears(memberId!);
      setState(() {
        availableYears = years;
        if (years.isNotEmpty && selectedYear == null) {
          selectedYear = years.first;
        }
      });
    } catch (e) {
      print('❌ 연도 목록 로드 실패: $e');
    }
  }

  Future<void> _loadOfferings() async {
    if (memberId == null) return;
    setState(() => isLoading = true);
    try {
      final offeringList = await _offeringService.getOfferings(
        memberId: memberId!,
        year: selectedYear,
      );
      final double total =
          offeringList.fold(0.0, (sum, o) => sum + o.amount);
      final Map<String, double> byCategory = {};
      for (final o in offeringList) {
        byCategory[o.fundType] = (byCategory[o.fundType] ?? 0) + o.amount;
      }
      // 최신순 정렬
      offeringList.sort((a, b) => b.offeredOn.compareTo(a.offeredOn));
      setState(() {
        offerings = offeringList;
        totalAmount = total;
        categoryTotals = byCategory;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 헌금 내역 로드 실패: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          offerings = [];
          totalAmount = 0.0;
          categoryTotals = {};
        });
        AppToast.error(context, '헌금 내역을 불러올 수 없습니다');
      }
    }
  }

  String _formatAmount(double amount) {
    final formatter = amount.toStringAsFixed(0);
    final parts = formatter.split('.');
    final intPart = parts[0];
    String result = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = ',$result';
      result = intPart[i] + result;
      count++;
    }
    return '$result원';
  }

  // 카테고리별 톤 — 시안: 십일조=sky / 감사=warning / 선교=success
  ({Color bg, Color fg, IconData icon}) _toneForFund(String type) {
    if (type.contains('감사')) {
      return (
        bg: NewAppColor.warningBg,
        fg: NewAppColor.warning700,
        icon: LucideIcons.gift,
      );
    }
    if (type.contains('선교') || type.contains('구제')) {
      return (
        bg: NewAppColor.successBg,
        fg: NewAppColor.success700,
        icon: LucideIcons.globe,
      );
    }
    if (type.contains('십일조')) {
      return (
        bg: NewAppColor.skyTint,
        fg: NewAppColor.skyDeep,
        icon: LucideIcons.handHeart,
      );
    }
    if (type.contains('주일')) {
      return (
        bg: NewAppColor.skyTint,
        fg: NewAppColor.skyDeep,
        icon: LucideIcons.church,
      );
    }
    return (
      bg: NewAppColor.borderSoft,
      fg: NewAppColor.textSecondary,
      icon: LucideIcons.piggyBank,
    );
  }

  String _weekday(DateTime date) {
    const map = ['월', '화', '수', '목', '금', '토', '일'];
    return '${map[date.weekday - 1]}요일';
  }

  String _shortDate(DateTime date) {
    final isSunday = date.weekday == DateTime.sunday;
    final label = isSunday ? '주일' : _weekday(date);
    return '${date.month}월 ${date.day}일 · $label';
  }

  // 월별 그룹핑
  Map<int, List<Offering>> _groupByMonth() {
    final Map<int, List<Offering>> grouped = {};
    for (final o in offerings) {
      grouped.putIfAbsent(o.offeredOn.month, () => []).add(o);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: NewAppColor.canvasAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내 헌금 내역',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 18.sp,
              ),
        ),
        actions: [
          material.IconButton(
            icon: Icon(LucideIcons.download,
                color: NewAppColor.textSecondary, size: 22.sp),
            onPressed: () =>
                AppToast.show(context, '기부금영수증 발급 기능은 곧 추가됩니다'),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : RefreshIndicator(
              onRefresh: _loadOfferings,
              color: NewAppColor.skyPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 14.h),
                      child: _buildSummaryCard(),
                    ),
                    if (offerings.isEmpty)
                      _buildEmptyState()
                    else
                      ..._buildMonthGroups(),
                    SizedBox(height: 12.h),
                    _buildHintFooter(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NewAppColor.skyPrimary,
            NewAppColor.skyDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: NewAppColor.skyPrimary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${selectedYear ?? DateTime.now().year}년 누적 헌금',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              _buildYearSelector(),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            _formatAmount(totalAmount),
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
              letterSpacing: -0.5,
            ),
          ),
          if (categoryTotals.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Container(height: 1, color: Colors.white.withOpacity(0.18)),
            SizedBox(height: 14.h),
            Row(
              children: categoryTotals.entries.take(3).map((entry) {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _formatAmount(entry.value)
                            .replaceAll('원', ''),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return GestureDetector(
      onTap: availableYears.isEmpty
          ? null
          : () => _showYearSheet(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${selectedYear ?? DateTime.now().year}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(width: 3.w),
            Icon(LucideIcons.chevronDown, size: 14.sp, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showYearSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: NewAppColor.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                SizedBox(height: 14.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '연도 선택',
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Container(height: 1, color: NewAppColor.borderHair),
                ...availableYears.map((year) {
                  final isSelected = year == selectedYear;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => selectedYear = year);
                        Navigator.pop(sheetContext);
                        _loadOfferings();
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 22.w, vertical: 14.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$year년',
                                style: TextStyle(
                                  color: isSelected
                                      ? NewAppColor.skyPrimary
                                      : NewAppColor.textStrong,
                                  fontSize: 14.5.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(LucideIcons.check,
                                  color: NewAppColor.skyPrimary, size: 20.sp),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMonthGroups() {
    final grouped = _groupByMonth();
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    return months.map((month) {
      final list = grouped[month]!;
      final monthTotal = list.fold(0.0, (sum, o) => sum + o.amount);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
            child: Row(
              children: [
                Text(
                  '$month월',
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const Spacer(),
                Text(
                  _formatAmount(monthTotal),
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          Container(color: Colors.white, child: _buildMonthList(list)),
        ],
      );
    }).toList();
  }

  Widget _buildMonthList(List<Offering> list) {
    return Column(
      children: List.generate(list.length, (i) {
        final offering = list[i];
        final isLast = i == list.length - 1;
        return Column(
          children: [
            _buildOfferingRow(offering),
            if (!isLast)
              Container(
                height: 1,
                color: NewAppColor.borderHair,
                margin: EdgeInsets.only(left: 64.w),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildOfferingRow(Offering offering) {
    final tone = _toneForFund(offering.fundType);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: tone.bg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Icon(tone.icon, size: 18.sp, color: tone.fg),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offering.fundType,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _shortDate(offering.offeredOn),
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            _formatAmount(offering.amount),
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 60.h),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.wallet,
              size: 56.sp, color: NewAppColor.iconFaint),
          SizedBox(height: 14.h),
          Text(
            '헌금 내역이 없습니다',
            style: TextStyle(
              color: NewAppColor.textSecondary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '다른 연도를 선택해보세요',
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHintFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info,
              size: 14.sp, color: NewAppColor.textTertiary),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              '헌금 내역은 교회 재정부 입력 기준이며, 연말정산용 기부금영수증은 우측 상단에서 발급할 수 있어요.',
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
