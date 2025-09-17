import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import '../resource/color_style.dart';

enum CalendarView {
  month,
  week,
  day,
}

enum CalendarSelectionMode {
  single,
  multiple,
  range,
}

class AppCalendar extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? selectedDate;
  final List<DateTime>? selectedDates;
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTime?>? onDateChanged;
  final ValueChanged<List<DateTime>>? onDatesChanged;
  final ValueChanged<DateTimeRange?>? onRangeChanged;
  final CalendarSelectionMode selectionMode;
  final CalendarView view;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool showHeader;
  final bool showWeekdays;
  final List<DateTime>? disabledDates;
  final Map<DateTime, List<CalendarEvent>>? events;

  const AppCalendar({
    Key? key,
    this.initialDate,
    this.selectedDate,
    this.selectedDates,
    this.selectedRange,
    this.onDateChanged,
    this.onDatesChanged,
    this.onRangeChanged,
    this.selectionMode = CalendarSelectionMode.single,
    this.view = CalendarView.month,
    this.minDate,
    this.maxDate,
    this.showHeader = true,
    this.showWeekdays = true,
    this.disabledDates,
    this.events,
  }) : super(key: key);

  @override
  State<AppCalendar> createState() => _AppCalendarState();
}

class _AppCalendarState extends State<AppCalendar> {
  late DateTime _currentDate;
  late DateTime _displayDate;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate ?? DateTime.now();
    _displayDate = DateTime(_currentDate.year, _currentDate.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(color: AppColor.border1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHeader) _buildHeader(),
          if (widget.showWeekdays) _buildWeekdays(),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColor.border1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _goToPreviousMonth,
            icon: const Icon(Icons.keyboard_arrow_left),
            iconSize: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getHeaderText(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.secondary06,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _goToNextMonth,
            icon: const Icon(Icons.keyboard_arrow_right),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdays() {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays.map((weekday) {
          return Expanded(
            child: Text(
              weekday,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.secondary04,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_displayDate.year, _displayDate.month, 1);
    final lastDayOfMonth = DateTime(_displayDate.year, _displayDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0
    
    final daysInMonth = lastDayOfMonth.day;
    final totalCells = ((daysInMonth + firstDayWeekday - 1) / 7).ceil() * 7;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayIndex = index - firstDayWeekday + 1;
        
        if (dayIndex < 1 || dayIndex > daysInMonth) {
          return const SizedBox(); // Empty cell
        }
        
        final date = DateTime(_displayDate.year, _displayDate.month, dayIndex);
        return _buildDayCell(date);
      },
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isDisabled = _isDateDisabled(date);
    final isToday = _isToday(date);
    final events = widget.events?[date] ?? [];
    
    return GestureDetector(
      onTap: isDisabled ? null : () => _onDateTap(date),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
            ? AppColor.primary600
            : isInRange
              ? AppColor.primary100
              : isToday
                ? AppColor.primary100.withOpacity(0.3)
                : Colors.transparent,
          border: isToday && !isSelected
            ? Border.all(color: AppColor.primary600, width: 1)
            : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isDisabled
                  ? AppColor.secondary02
                  : isSelected
                    ? AppColor.white
                    : isToday
                      ? AppColor.primary600
                      : AppColor.secondary06,
              ),
            ),
            if (events.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: event.color ?? AppColor.primary600,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isDateSelected(DateTime date) {
    switch (widget.selectionMode) {
      case CalendarSelectionMode.single:
        return widget.selectedDate != null && _isSameDay(date, widget.selectedDate!);
      case CalendarSelectionMode.multiple:
        return widget.selectedDates?.any((d) => _isSameDay(date, d)) ?? false;
      case CalendarSelectionMode.range:
        final range = widget.selectedRange;
        if (range == null) return false;
        return _isSameDay(date, range.start) || _isSameDay(date, range.end);
    }
  }

  bool _isDateInRange(DateTime date) {
    if (widget.selectionMode != CalendarSelectionMode.range) return false;
    final range = widget.selectedRange;
    if (range == null) return false;
    
    return date.isAfter(range.start) && date.isBefore(range.end);
  }

  bool _isDateDisabled(DateTime date) {
    if (widget.minDate != null && date.isBefore(widget.minDate!)) return true;
    if (widget.maxDate != null && date.isAfter(widget.maxDate!)) return true;
    if (widget.disabledDates?.any((d) => _isSameDay(date, d)) == true) return true;
    return false;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _onDateTap(DateTime date) {
    switch (widget.selectionMode) {
      case CalendarSelectionMode.single:
        widget.onDateChanged?.call(date);
        break;
      case CalendarSelectionMode.multiple:
        final currentDates = List<DateTime>.from(widget.selectedDates ?? []);
        final existingIndex = currentDates.indexWhere((d) => _isSameDay(d, date));
        
        if (existingIndex >= 0) {
          currentDates.removeAt(existingIndex);
        } else {
          currentDates.add(date);
        }
        
        widget.onDatesChanged?.call(currentDates);
        break;
      case CalendarSelectionMode.range:
        final range = widget.selectedRange;
        DateTimeRange? newRange;
        
        if (range == null) {
          newRange = DateTimeRange(start: date, end: date);
        } else if (_isSameDay(date, range.start) && _isSameDay(date, range.end)) {
          newRange = null;
        } else if (date.isBefore(range.start)) {
          newRange = DateTimeRange(start: date, end: range.end);
        } else {
          newRange = DateTimeRange(start: range.start, end: date);
        }
        
        widget.onRangeChanged?.call(newRange);
        break;
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month - 1, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayDate = DateTime(_displayDate.year, _displayDate.month + 1, 1);
    });
  }

  String _getHeaderText() {
    const months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'
    ];
    return '${_displayDate.year}년 ${months[_displayDate.month - 1]}';
  }


}

class CalendarEvent {
  final String title;
  final String? description;
  final Color? color;
  final DateTime dateTime;

  const CalendarEvent({
    required this.title,
    this.description,
    this.color,
    required this.dateTime,
  });
}

class AppDatePicker {
  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minDate,
    DateTime? maxDate,
    String title = '날짜 선택',
  }) async {
    DateTime? selectedDate;
    
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: AppCalendar(
            selectedDate: initialDate,
            onDateChanged: (date) => selectedDate = date,
            selectionMode: CalendarSelectionMode.single,
            minDate: minDate,
            maxDate: maxDate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedDate),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    
    return result;
  }

  static Future<DateTimeRange?> showRange(
    BuildContext context, {
    DateTimeRange? initialRange,
    DateTime? minDate,
    DateTime? maxDate,
    String title = '기간 선택',
  }) async {
    DateTimeRange? selectedRange = initialRange;
    
    final result = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 300,
          child: AppCalendar(
            selectedRange: initialRange,
            onRangeChanged: (range) => selectedRange = range,
            selectionMode: CalendarSelectionMode.range,
            minDate: minDate,
            maxDate: maxDate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedRange),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    
    return result;
  }
}
