import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style.dart';
import '../components/index.dart';

class DateTimePickerBottomSheet extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialTime;
  final Function(DateTime date, String time)? onConfirm;

  const DateTimePickerBottomSheet({
    super.key,
    this.initialDate,
    this.initialTime,
    this.onConfirm,
  });

  @override
  State<DateTimePickerBottomSheet> createState() => _DateTimePickerBottomSheetState();
}

class _DateTimePickerBottomSheetState extends State<DateTimePickerBottomSheet> {
  late DateTime selectedDate;
  String? selectedTime;
  
  // 시간대 목록 (30분 단위)
  final List<String> timeSlots = [
    '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30',
    '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30',
  ];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate ?? DateTime.now().add(const Duration(days: 1));
    selectedTime = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
            decoration: BoxDecoration(
              color: AppColor.secondary03,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Text(
                  '날짜/시간 선택',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: 24.w,
                    color: AppColor.secondary04,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 선택 섹션
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      '날짜 선택',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColor.secondary07,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // 주간 달력 뷰
                  _buildWeekCalendar(),

                  SizedBox(height: 32.h),

                  // 시간 선택 섹션
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
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
                  ),
                  SizedBox(height: 16.h),

                  // 시간대 그리드
                  _buildTimeGrid(),

                  SizedBox(height: 16.h),

                  // 주의사항
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFFFFE0B2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.w,
                          color: const Color(0xFFFF8A00),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '노숙 대신 입금은 예약 변경/취소가 제한되니까\n방문 상황에 맞춰 대처 시간에 맞설와 수 있어 미리 협의하며 방\n문해 주세요.',
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

          // 하단 버튼
          Container(
            padding: EdgeInsets.all(20.w),
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
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = weekStart.add(Duration(days: index));
          final isSelected = date.day == selectedDate.day && 
                           date.month == selectedDate.month &&
                           date.year == selectedDate.year;
          final isPast = date.isBefore(now.subtract(const Duration(days: 1)));
          final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
          
          return GestureDetector(
            onTap: isPast ? null : () {
              setState(() {
                selectedDate = date;
              });
            },
            child: Container(
              width: 40.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: isSelected ? AppColor.primary600 : Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: isSelected ? null : Border.all(
                  color: AppColor.secondary02,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdays[index],
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isPast 
                          ? AppColor.secondary03
                          : isSelected 
                              ? Colors.white 
                              : AppColor.secondary05,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isPast 
                          ? AppColor.secondary03
                          : isSelected 
                              ? Colors.white 
                              : AppColor.secondary07,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
                  color: isSelected ? AppColor.primary600 : AppColor.secondary02,
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
      widget.onConfirm?.call(selectedDate, selectedTime!);
      Navigator.of(context).pop();
    }
  }
}