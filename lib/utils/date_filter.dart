class DateFilter {
  final String key;
  final String label;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortOrder;

  const DateFilter({
    required this.key,
    required this.label,
    this.startDate,
    this.endDate,
    this.sortOrder = 'desc',
  });

  static DateTime get today => DateTime.now();
  static DateTime get startOfToday => DateTime(today.year, today.month, today.day);
  static DateTime get startOfWeek => startOfToday.subtract(Duration(days: 7));
  static DateTime get startOfMonth => DateTime(today.year, today.month, 1);
  static DateTime get startOfThisMonth => DateTime(today.year, today.month, 1);

  // 날짜 필터 옵션들
  static List<DateFilter> getFilterOptions() {
    return [
      const DateFilter(
        key: 'latest',
        label: '최신순',
        sortOrder: 'desc',
      ),
      const DateFilter(
        key: 'oldest',
        label: '오래된순',
        sortOrder: 'asc',
      ),
      DateFilter(
        key: 'week',
        label: '최근 7일',
        startDate: startOfWeek,
        endDate: today,
        sortOrder: 'desc',
      ),
      DateFilter(
        key: 'month',
        label: '최근 30일',
        startDate: startOfToday.subtract(const Duration(days: 30)),
        endDate: today,
        sortOrder: 'desc',
      ),
      DateFilter(
        key: 'this_month',
        label: '이번 달',
        startDate: startOfThisMonth,
        endDate: today,
        sortOrder: 'desc',
      ),
      const DateFilter(
        key: 'custom',
        label: '📅 날짜 선택',
        sortOrder: 'desc',
      ),
    ];
  }

  // 필터에 따른 날짜 범위 계산
  static Map<String, DateTime?> getDateRange(String filterKey, {DateTime? customStart, DateTime? customEnd}) {
    final filters = getFilterOptions();
    final filter = filters.firstWhere((f) => f.key == filterKey, orElse: () => filters.first);
    
    if (filterKey == 'custom' && customStart != null && customEnd != null) {
      return {
        'startDate': customStart,
        'endDate': customEnd,
      };
    }
    
    return {
      'startDate': filter.startDate,
      'endDate': filter.endDate,
    };
  }

  // 필터에 따른 정렬 순서
  static String getSortOrder(String filterKey) {
    final filters = getFilterOptions();
    final filter = filters.firstWhere((f) => f.key == filterKey, orElse: () => filters.first);
    return filter.sortOrder;
  }
}
