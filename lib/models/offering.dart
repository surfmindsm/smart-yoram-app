class Offering {
  final int id;
  final int churchId;
  final int memberId;
  final DateTime offeredOn;
  final String fundType;
  final double amount;
  final String? note;
  final int inputUserId;
  final int? accountingTransactionId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Offering({
    required this.id,
    required this.churchId,
    required this.memberId,
    required this.offeredOn,
    required this.fundType,
    required this.amount,
    this.note,
    required this.inputUserId,
    this.accountingTransactionId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Offering.fromJson(Map<String, dynamic> json) {
    return Offering(
      id: json['id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      memberId: json['member_id'] ?? 0,
      offeredOn: json['offered_on'] != null
          ? DateTime.parse(json['offered_on'])
          : DateTime.now(),
      fundType: json['fund_type'] ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] ?? 0.0),
      note: json['note'],
      inputUserId: json['input_user_id'] ?? 0,
      accountingTransactionId: json['accounting_transaction_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'church_id': churchId,
      'member_id': memberId,
      'offered_on': offeredOn.toIso8601String(),
      'fund_type': fundType,
      'amount': amount,
      'note': note,
      'input_user_id': inputUserId,
      'accounting_transaction_id': accountingTransactionId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Offering copyWith({
    int? id,
    int? churchId,
    int? memberId,
    DateTime? offeredOn,
    String? fundType,
    double? amount,
    String? note,
    int? inputUserId,
    int? accountingTransactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Offering(
      id: id ?? this.id,
      churchId: churchId ?? this.churchId,
      memberId: memberId ?? this.memberId,
      offeredOn: offeredOn ?? this.offeredOn,
      fundType: fundType ?? this.fundType,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      inputUserId: inputUserId ?? this.inputUserId,
      accountingTransactionId: accountingTransactionId ?? this.accountingTransactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // UI에서 사용할 편의 메서드들
  String get formattedDate {
    return '${offeredOn.year}.${offeredOn.month.toString().padLeft(2, '0')}.${offeredOn.day.toString().padLeft(2, '0')}';
  }

  String get formattedAmount {
    // 금액을 천 단위 쉼표로 포맷팅
    final formatter = amount.toStringAsFixed(0);
    final parts = formatter.split('.');
    final intPart = parts[0];

    // 천 단위로 쉼표 추가
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

  int get year => offeredOn.year;
  int get month => offeredOn.month;
}
