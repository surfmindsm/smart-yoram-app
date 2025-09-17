import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style.dart';
import '../resource/text_style.dart';
import '../components/index.dart';

class DateTimePickerPage extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;

  const DateTimePickerPage({
    super.key,
    this.initialDate,
    this.initialTime,
  });

  @override
  State<DateTimePickerPage> createState() => _DateTimePickerPageState();
}

class _DateTimePickerPageState extends State<DateTimePickerPage> {
  late DateTime selectedDate;
  late DateTime currentMonth;
  String? selectedTime;

  // 시간대 목록 (30분 단위)
  final List<String> timeSlots = [
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
    '18:30',
    '19:00',
    '19:30',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate =
        widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    currentMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          '날짜/시간 선택',
          style: AppTextStyle(
            color: AppColor.secondary07,
          ).h2(),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: EdgeInsets.all(12.w),
            child: Icon(
              LucideIcons.arrowLeft,
              color: AppColor.secondary05,
              size: 20.w,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 월 달력 뷰
                  _buildMonthCalendar(),

                  SizedBox(height: 16.h),

                  // 시간 선택 섹션
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '시간 선택',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColor.secondary07,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '방문 희망 시간을 선택해주세요',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColor.secondary04,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 시간대 그리드
                  _buildTimeGrid(),

                  SizedBox(height: 16.h),

                  // 주의사항
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 16.w,
                          color: const Color(0xFFFF8A00),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '안내된 심방 시간은 확정된 일정이 아니며, 교회 사정에 따라 조정될 수 있습니다.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: const Color(0xFFE65100),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),

          // 하단 고정 버튼
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  onPressed: selectedTime != null ? _handleConfirm : null,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.lg,
                  child: const Text('선택하기'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          // 월 헤더 (이전/다음 버튼 포함)
          _buildMonthHeader(),
          SizedBox(height: 20.h),

          // 요일 헤더
          _buildWeekdayHeader(),
          SizedBox(height: 12.h),

          // 달력 그리드
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              currentMonth =
                  DateTime(currentMonth.year, currentMonth.month - 1, 1);
            });
          },
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColor.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              LucideIcons.chevronLeft,
              color: AppColor.secondary05,
              size: 20.w,
            ),
          ),
        ),
        Text(
          '${currentMonth.year}년 ${currentMonth.month}월',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.secondary07,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              currentMonth =
                  DateTime(currentMonth.year, currentMonth.month + 1, 1);
            });
          },
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColor.transparent,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              LucideIcons.chevronRight,
              color: AppColor.secondary05,
              size: 20.w,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Row(
      children: weekdays.map((weekday) {
        return Expanded(
          child: Center(
            child: Text(
              weekday,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColor.secondary04,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    // 전월 마지막 날들
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1, 0);
    List<Widget> calendarDays = [];

    // 이전 달 날짜들 (회색으로 표시)
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      final day = prevMonth.day - i;
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: false,
        date: DateTime(prevMonth.year, prevMonth.month, day),
      ));
    }

    // 현재 달 날짜들
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: true,
        date: date,
      ));
    }

    // 다음 달 날짜들로 6주 채우기
    final remainingCells = 42 - calendarDays.length;
    for (int day = 1; day <= remainingCells; day++) {
      final nextMonth =
          DateTime(currentMonth.year, currentMonth.month + 1, day);
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: false,
        date: nextMonth,
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: calendarDays,
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isCurrentMonth,
    required DateTime date,
  }) {
    final now = DateTime.now();
    final isSelected = date.day == selectedDate.day &&
        date.month == selectedDate.month &&
        date.year == selectedDate.year;
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;

    return GestureDetector(
      onTap: (isPast || !isCurrentMonth)
          ? null
          : () {
              setState(() {
                selectedDate = date;
              });
            },
      child: Container(
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primary600 : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              color: !isCurrentMonth
                  ? AppColor.secondary03
                  : isPast
                      ? AppColor.secondary03
                      : isSelected
                          ? Colors.white
                          : isToday
                              ? AppColor.primary600
                              : AppColor.secondary07,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 2.2,
        ),
        itemCount: timeSlots.length,
        itemBuilder: (context, index) {
          final time = timeSlots[index];
          final isSelected = selectedTime == time;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTime = time;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? AppColor.primary600 : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color:
                      isSelected ? AppColor.primary600 : AppColor.secondary02,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppColor.secondary07,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleConfirm() {
    if (selectedTime != null) {
      Navigator.of(context).pop({
        'date': selectedDate,
        'time': selectedTime!,
      });
    }
  }
}
