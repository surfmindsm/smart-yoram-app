class AttendanceSummary {
  final AttendanceSummaryData summary;
  final List<AttendanceData> attendanceData;

  AttendanceSummary({
    required this.summary,
    required this.attendanceData,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      summary: AttendanceSummaryData.fromJson(json['summary']),
      attendanceData: (json['attendance_data'] as List)
          .map((data) => AttendanceData.fromJson(data))
          .toList(),
    );
  }
}

class AttendanceSummaryData {
  final int totalMembers;
  final double averageAttendance;
  final double averageAttendanceRate;
  final DatePeriod period;

  AttendanceSummaryData({
    required this.totalMembers,
    required this.averageAttendance,
    required this.averageAttendanceRate,
    required this.period,
  });

  factory AttendanceSummaryData.fromJson(Map<String, dynamic> json) {
    return AttendanceSummaryData(
      totalMembers: json['total_members'],
      averageAttendance: json['average_attendance'].toDouble(),
      averageAttendanceRate: json['average_attendance_rate'].toDouble(),
      period: DatePeriod.fromJson(json['period']),
    );
  }
}

class AttendanceData {
  final DateTime date;
  final int presentCount;
  final int totalMembers;
  final double attendanceRate;

  AttendanceData({
    required this.date,
    required this.presentCount,
    required this.totalMembers,
    required this.attendanceRate,
  });

  factory AttendanceData.fromJson(Map<String, dynamic> json) {
    return AttendanceData(
      date: DateTime.parse(json['date']),
      presentCount: json['present_count'],
      totalMembers: json['total_members'],
      attendanceRate: json['attendance_rate'].toDouble(),
    );
  }
}

class MemberAttendanceStats {
  final int memberId;
  final String memberName;
  final int totalAttendances;
  final int presentCount;
  final double attendanceRate;
  final String? profilePhotoUrl;

  MemberAttendanceStats({
    required this.memberId,
    required this.memberName,
    required this.totalAttendances,
    required this.presentCount,
    required this.attendanceRate,
    this.profilePhotoUrl,
  });

  factory MemberAttendanceStats.fromJson(Map<String, dynamic> json) {
    return MemberAttendanceStats(
      memberId: json['member_id'],
      memberName: json['member_name'],
      totalAttendances: json['total_attendances'],
      presentCount: json['present_count'],
      attendanceRate: json['attendance_rate'].toDouble(),
      profilePhotoUrl: json['profile_photo_url'],
    );
  }

  int get absentCount => totalAttendances - presentCount;
}

class MemberDemographics {
  final List<GenderDistribution> genderDistribution;
  final List<AgeDistribution> ageDistribution;
  final List<PositionDistribution> positionDistribution;
  final List<DistrictDistribution> districtDistribution;

  MemberDemographics({
    required this.genderDistribution,
    required this.ageDistribution,
    required this.positionDistribution,
    required this.districtDistribution,
  });

  factory MemberDemographics.fromJson(Map<String, dynamic> json) {
    return MemberDemographics(
      genderDistribution: (json['gender_distribution'] as List)
          .map((data) => GenderDistribution.fromJson(data))
          .toList(),
      ageDistribution: (json['age_distribution'] as List)
          .map((data) => AgeDistribution.fromJson(data))
          .toList(),
      positionDistribution: (json['position_distribution'] as List)
          .map((data) => PositionDistribution.fromJson(data))
          .toList(),
      districtDistribution: (json['district_distribution'] as List)
          .map((data) => DistrictDistribution.fromJson(data))
          .toList(),
    );
  }

  int get totalMembers => genderDistribution.fold(0, (sum, item) => sum + item.count);
}

class GenderDistribution {
  final String gender;
  final int count;

  GenderDistribution({required this.gender, required this.count});

  factory GenderDistribution.fromJson(Map<String, dynamic> json) {
    return GenderDistribution(
      gender: json['gender'],
      count: json['count'],
    );
  }
}

class AgeDistribution {
  final String ageGroup;
  final int count;

  AgeDistribution({required this.ageGroup, required this.count});

  factory AgeDistribution.fromJson(Map<String, dynamic> json) {
    return AgeDistribution(
      ageGroup: json['age_group'],
      count: json['count'],
    );
  }
}

class PositionDistribution {
  final String position;
  final int count;

  PositionDistribution({required this.position, required this.count});

  factory PositionDistribution.fromJson(Map<String, dynamic> json) {
    return PositionDistribution(
      position: json['position'],
      count: json['count'],
    );
  }
}

class DistrictDistribution {
  final String district;
  final int count;

  DistrictDistribution({required this.district, required this.count});

  factory DistrictDistribution.fromJson(Map<String, dynamic> json) {
    return DistrictDistribution(
      district: json['district'],
      count: json['count'],
    );
  }
}

class MemberGrowthStats {
  final DatePeriod period;
  final List<GrowthData> growthData;
  final GrowthSummary summary;

  MemberGrowthStats({
    required this.period,
    required this.growthData,
    required this.summary,
  });

  factory MemberGrowthStats.fromJson(Map<String, dynamic> json) {
    return MemberGrowthStats(
      period: DatePeriod.fromJson(json['period']),
      growthData: (json['growth_data'] as List)
          .map((data) => GrowthData.fromJson(data))
          .toList(),
      summary: GrowthSummary.fromJson(json['summary']),
    );
  }
}

class GrowthData {
  final String month;
  final int newMembers;
  final int transfersOut;
  final int netGrowth;
  final int totalMembers;

  GrowthData({
    required this.month,
    required this.newMembers,
    required this.transfersOut,
    required this.netGrowth,
    required this.totalMembers,
  });

  factory GrowthData.fromJson(Map<String, dynamic> json) {
    return GrowthData(
      month: json['month'],
      newMembers: json['new_members'],
      transfersOut: json['transfers_out'],
      netGrowth: json['net_growth'],
      totalMembers: json['total_members'],
    );
  }
}

class GrowthSummary {
  final int totalNewMembers;
  final int totalTransfersOut;
  final int netGrowth;
  final int currentTotalMembers;

  GrowthSummary({
    required this.totalNewMembers,
    required this.totalTransfersOut,
    required this.netGrowth,
    required this.currentTotalMembers,
  });

  factory GrowthSummary.fromJson(Map<String, dynamic> json) {
    return GrowthSummary(
      totalNewMembers: json['total_new_members'],
      totalTransfersOut: json['total_transfers_out'],
      netGrowth: json['net_growth'],
      currentTotalMembers: json['current_total_members'],
    );
  }
}

class DatePeriod {
  final DateTime startDate;
  final DateTime endDate;
  final int? months;

  DatePeriod({
    required this.startDate,
    required this.endDate,
    this.months,
  });

  factory DatePeriod.fromJson(Map<String, dynamic> json) {
    return DatePeriod(
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      months: json['months'],
    );
  }
}

class DashboardStats {
  final int totalMembers;
  final int activeMembers;
  final double thisWeekAttendanceRate;
  final int thisWeekAttendance;
  final int newMembersThisMonth;
  final int upcomingBirthdays;
  final int pendingTasks;
  final AttendanceData? latestAttendance;

  DashboardStats({
    required this.totalMembers,
    required this.activeMembers,
    required this.thisWeekAttendanceRate,
    required this.thisWeekAttendance,
    required this.newMembersThisMonth,
    required this.upcomingBirthdays,
    required this.pendingTasks,
    this.latestAttendance,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalMembers: json['total_members'],
      activeMembers: json['active_members'],
      thisWeekAttendanceRate: json['this_week_attendance_rate'].toDouble(),
      thisWeekAttendance: json['this_week_attendance'],
      newMembersThisMonth: json['new_members_this_month'],
      upcomingBirthdays: json['upcoming_birthdays'],
      pendingTasks: json['pending_tasks'],
      latestAttendance: json['latest_attendance'] != null 
          ? AttendanceData.fromJson(json['latest_attendance'])
          : null,
    );
  }
}
