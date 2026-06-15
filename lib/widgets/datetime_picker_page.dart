import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

/// 날짜·시간 선택 화면 — 1.2.0 C 방향
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
  final List<String> timeSlots = const [
    '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30',
  ];

  static const _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

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
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(Icons.chevron_left,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '날짜·시간 선택',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 달력 카드
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMonthHeader(),
                        SizedBox(height: 14.h),
                        _buildWeekdayHeader(),
                        SizedBox(height: 4.h),
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // 시간 선택 카드
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('시간 선택'),
                        SizedBox(height: 4.h),
                        Text(
                          '방문 희망 시간을 선택해주세요',
                          style: TextStyle(
                            color: NewAppColor.textTertiary,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _buildTimeGrid(),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  // 주의사항
                  _buildHint(),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // 공용 카드 (white + borderHair + radius 14)
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: NewAppColor.textStrong,
        fontSize: 15.5.sp,
        fontWeight: FontWeight.w800,
        fontFamily: 'Pretendard',
      ),
    );
  }

  // 월 헤더 (좌측 < + 가운데 "YYYY년 M월" + 우측 >)
  Widget _buildMonthHeader() {
    return Row(
      children: [
        _buildArrowButton(
          icon: Icons.chevron_left,
          onTap: () => setState(() {
            currentMonth =
                DateTime(currentMonth.year, currentMonth.month - 1, 1);
          }),
        ),
        Expanded(
          child: Center(
            child: Text(
              '${currentMonth.year}년 ${currentMonth.month}월',
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ),
        _buildArrowButton(
          icon: Icons.chevron_right,
          onTap: () => setState(() {
            currentMonth =
                DateTime(currentMonth.year, currentMonth.month + 1, 1);
          }),
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: NewAppColor.borderSoft,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: NewAppColor.textSecondary, size: 20.sp),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: List.generate(_weekdayLabels.length, (i) {
        final label = _weekdayLabels[i];
        final color = i == 0
            ? NewAppColor.danger700
            : (i == 6 ? NewAppColor.skyDeep : NewAppColor.textTertiary);
        return Expanded(
          child: Container(
            height: 32.h,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final firstDayWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1, 0);
    final List<Widget> calendarDays = [];

    // 이전 달 회색 날짜
    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      final day = prevMonth.day - i;
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: false,
        date: DateTime(prevMonth.year, prevMonth.month, day),
        weekdayIndex: calendarDays.length % 7,
      ));
    }

    // 현재 달 날짜
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(currentMonth.year, currentMonth.month, day);
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: true,
        date: date,
        weekdayIndex: calendarDays.length % 7,
      ));
    }

    // 다음 달로 6주 채우기
    final remainingCells = 42 - calendarDays.length;
    for (int day = 1; day <= remainingCells; day++) {
      final nextMonth =
          DateTime(currentMonth.year, currentMonth.month + 1, day);
      calendarDays.add(_buildCalendarDay(
        day: day,
        isCurrentMonth: false,
        date: nextMonth,
        weekdayIndex: calendarDays.length % 7,
      ));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: calendarDays,
    );
  }

  Widget _buildCalendarDay({
    required int day,
    required bool isCurrentMonth,
    required DateTime date,
    required int weekdayIndex,
  }) {
    final now = DateTime.now();
    final isSelected = date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final disabled = isPast || !isCurrentMonth;

    Color textColor;
    if (!isCurrentMonth) {
      textColor = NewAppColor.borderStrong;
    } else if (isPast) {
      textColor = NewAppColor.textMuted;
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (weekdayIndex == 0) {
      textColor = NewAppColor.danger700;
    } else if (weekdayIndex == 6) {
      textColor = NewAppColor.skyDeep;
    } else {
      textColor = NewAppColor.textStrong;
    }

    return GestureDetector(
      onTap: disabled
          ? null
          : () => setState(() => selectedDate = date),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: (isToday && !isSelected)
              ? Border.all(color: NewAppColor.skyPrimary, width: 1.2)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            color: textColor,
            fontSize: 13.5.sp,
            fontWeight: (isSelected || isToday)
                ? FontWeight.w800
                : FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildTimeGrid() {
    return GridView.builder(
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
          onTap: () => setState(() => selectedTime = time),
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? NewAppColor.skyPrimary : Colors.white,
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(
                color: isSelected
                    ? NewAppColor.skyPrimary
                    : NewAppColor.borderHair,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : NewAppColor.textBody,
                fontSize: 13.5.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHint() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: NewAppColor.warningBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 15.sp, color: NewAppColor.warning700),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '안내된 심방 시간은 확정된 일정이 아니며, 교회 사정에 따라 조정될 수 있습니다.',
              style: TextStyle(
                color: NewAppColor.warning700,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final enabled = selectedTime != null;
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
      decoration: BoxDecoration(
        color: NewAppColor.canvasAlt,
        border: Border(
          top: BorderSide(color: NewAppColor.borderHair, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: enabled ? _handleConfirm : null,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                color: NewAppColor.skyPrimary,
                borderRadius: BorderRadius.circular(13.r),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: NewAppColor.skyPrimary.withOpacity(0.30),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                enabled ? '선택하기' : '시간을 선택해 주세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ),
        ),
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
