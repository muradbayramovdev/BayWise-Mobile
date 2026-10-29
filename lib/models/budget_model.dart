class BudgetModel {
  final String id;
  final String month;
  final String category;
  final double limit;
  final String updatedAt;

  const BudgetModel({
    required this.id,
    required this.month,
    required this.category,
    required this.limit,
    required this.updatedAt,
  });

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      month: map['month'] as String? ?? '',
      category: map['category'] as String? ?? '',
      limit: (map['limit'] as num?)?.toDouble() ?? 0.0,
      updatedAt: map['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'category': category,
      'limit': limit,
      'updatedAt': updatedAt,
    };
  }
}
