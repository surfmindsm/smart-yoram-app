import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../models/offering.dart';
import '../services/offering_service.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';

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

  // 필터 상태
  int? selectedYear;
  int? selectedMonth;
  List<int> availableYears = [];
  double totalAmount = 0.0;

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
      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        final currentUser = userResponse.data!;

        // 사용자의 교인 정보 조회
        final membersResponse = await _memberService.getMembers(limit: 1000);
        if (membersResponse.success && membersResponse.data != null) {
          final members = membersResponse.data!;
          final currentMember = members.firstWhere(
            (member) => member.email == currentUser.email,
            orElse: () => throw Exception('교인 정보를 찾을 수 없습니다'),
          );

          setState(() {
            memberId = currentMember.id;
          });
        }
      }
    } catch (e) {
      print('❌ 교인 정보 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교인 정보를 불러올 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
          selectedYear = years.first; // 가장 최근 연도로 초기화
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
        month: selectedMonth,
      );

      // 총액 계산
      double total = offeringList.fold(0.0, (sum, offering) => sum + offering.amount);

      setState(() {
        offerings = offeringList;
        totalAmount = total;
        isLoading = false;
      });
    } catch (e) {
      print('❌ 헌금 내역 로드 실패: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          offerings = [];
          totalAmount = 0.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('헌금 내역을 불러올 수 없습니다'),
            backgroundColor: Colors.red,
          ),
        );
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
      if (count > 0 && count % 3 == 0) {
        result = ',$result';
      }
      result = intPart[i] + result;
      count++;
    }

    return '$result원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        children: [
          // 상단 안전 영역
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

          // 헤더
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8.w),
                Text(
                  '내 헌금 내역',
                  style: FigmaTextStyles().headline3.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 필터 영역
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기간 선택',
                  style: FigmaTextStyles().title4.copyWith(
                        color: NewAppColor.neutral800,
                      ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    // 연도 선택
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: NewAppColor.neutral100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: DropdownButton<int?>(
                          value: selectedYear,
                          isExpanded: true,
                          underline: SizedBox(),
                          hint: Text(
                            '연도 선택',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral500,
                                ),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                '전체',
                                style: FigmaTextStyles().body2.copyWith(
                                      color: NewAppColor.neutral900,
                                    ),
                              ),
                            ),
                            ...availableYears.map((year) {
                              return DropdownMenuItem<int?>(
                                value: year,
                                child: Text(
                                  '$year년',
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: NewAppColor.neutral900,
                                      ),
                                ),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value;
                              selectedMonth = null; // 연도 변경 시 월 초기화
                            });
                            _loadOfferings();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // 월 선택
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: selectedYear == null
                              ? NewAppColor.neutral200
                              : NewAppColor.neutral100,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: DropdownButton<int?>(
                          value: selectedMonth,
                          isExpanded: true,
                          underline: SizedBox(),
                          hint: Text(
                            '월 선택',
                            style: FigmaTextStyles().body2.copyWith(
                                  color: selectedYear == null
                                      ? NewAppColor.neutral400
                                      : NewAppColor.neutral500,
                                ),
                          ),
                          items: selectedYear == null
                              ? []
                              : [
                                  DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      '전체',
                                      style: FigmaTextStyles().body2.copyWith(
                                            color: NewAppColor.neutral900,
                                          ),
                                    ),
                                  ),
                                  ...List.generate(12, (index) => index + 1).map((month) {
                                    return DropdownMenuItem<int?>(
                                      value: month,
                                      child: Text(
                                        '$month월',
                                        style: FigmaTextStyles().body2.copyWith(
                                              color: NewAppColor.neutral900,
                                            ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                          onChanged: selectedYear == null
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedMonth = value;
                                  });
                                  _loadOfferings();
                                },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 합계 영역
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  NewAppColor.primary600,
                  NewAppColor.primary600.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 헌금액',
                  style: FigmaTextStyles().title3.copyWith(
                        color: Colors.white,
                      ),
                ),
                Text(
                  _formatAmount(totalAmount),
                  style: FigmaTextStyles().headline2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // 헌금 내역 목록
          Expanded(
            child: _buildOfferingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferingList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NewAppColor.primary500),
            ),
            SizedBox(height: 16.h),
            Text(
              '헌금 내역을 불러오는 중...',
              style: FigmaTextStyles().body1.copyWith(
                    color: NewAppColor.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    if (offerings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64.sp,
              color: NewAppColor.neutral400,
            ),
            SizedBox(height: 16.h),
            Text(
              '헌금 내역이 없습니다',
              style: FigmaTextStyles().title3.copyWith(
                    color: NewAppColor.neutral600,
                  ),
            ),
            SizedBox(height: 8.h),
            Text(
              '다른 기간을 선택해보세요',
              style: FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral600,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: offerings.length,
      itemBuilder: (context, index) {
        final offering = offerings[index];
        return _buildOfferingCard(offering);
      },
    );
  }

  Widget _buildOfferingCard(Offering offering) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          // 왼쪽: 날짜와 항목
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offering.formattedDate,
                  style: FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral600,
                      ),
                ),
                SizedBox(height: 4.h),
                Text(
                  offering.fundType,
                  style: FigmaTextStyles().title4.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                ),
                if (offering.note != null && offering.note!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    offering.note!,
                    style: FigmaTextStyles().caption1.copyWith(
                          color: NewAppColor.neutral500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 오른쪽: 금액
          Text(
            offering.formattedAmount,
            style: FigmaTextStyles().title3.copyWith(
                  color: NewAppColor.primary600,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
