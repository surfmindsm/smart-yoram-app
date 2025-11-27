import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

/// 커스텀 날짜 선택 다이얼로그
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  List<DateTime?> selectedDates = [initialDate];

  return showDialog<DateTime>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;

      return Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          width: screenWidth - 32.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.single,
                      selectedDayHighlightColor: const Color(0xFF2196F3),
                      weekdayLabelTextStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      controlsTextStyle: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      dayTextStyle: const TextStyle(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      disabledDayTextStyle: const TextStyle(
                        color: Color(0xFFDDDDDD),
                        fontSize: 14,
                      ),
                      selectedDayTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      todayTextStyle: const TextStyle(
                        color: Color(0xFF64B5F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      dayBorderRadius: BorderRadius.circular(50.r),
                      yearTextStyle: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                      ),
                      selectedYearTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      monthTextStyle: const TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                      ),
                      selectedMonthTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      controlsHeight: 50.h,
                      lastDate: lastDate,
                      firstDate: firstDate,
                      // 구분선 제거
                      hideMonthPickerDividers: true,
                      hideYearPickerDividers: true,
                      // false로 설정하면 월/년도가 왼쪽, 화살표가 오른쪽에 배치
                      centerAlignModePicker: false,
                    ),
                    value: selectedDates,
                    onValueChanged: (dates) {
                      setState(() {
                        selectedDates = dates;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        if (selectedDates.isNotEmpty && selectedDates[0] != null) {
                          Navigator.pop(dialogContext, selectedDates[0]);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
