class RecurringPaymentModel {
  final String id;
  final String name;
  final double amount;
  final String type; // 'expense' | 'income'
  final String category;
  final String frequency; // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String nextDate; // yyyy-MM-dd
  final bool isActive;
  final String createdAt;

  const RecurringPaymentModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.nextDate,
    required this.isActive,
    required this.createdAt,
  });

  factory RecurringPaymentModel.fromMap(
      String id, Map<String, dynamic> map) {
    return RecurringPaymentModel(
      id: id,
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      category: map['category'] as String? ?? 'Diğer',
      frequency: map['frequency'] as String? ?? 'monthly',
      nextDate: map['nextDate'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'type': type,
    'category': category,
    'frequency': frequency,
    'nextDate': nextDate,
    'isActive': isActive,
    'createdAt': createdAt,
  };

  RecurringPaymentModel copyWith({
    String? name,
    double? amount,
    String? type,
    String? category,
    String? frequency,
    String? nextDate,
    bool? isActive,
  }) {
    return RecurringPaymentModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDate: nextDate ?? this.nextDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Günlük';
      case 'weekly':
        return 'Haftalık';
      case 'monthly':
        return 'Aylık';
      case 'yearly':
        return 'Yıllık';
      default:
        return 'Aylık';
    }
  }

  int daysUntilNext() {
    if (nextDate.isEmpty) return 0;
    try {
      final target = DateTime.parse(nextDate);
      final diff = target.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }
}
