class TransactionModel {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String description;
  final String date; // yyyy-MM-dd
  final String month; // yyyy-MM
  final String? accountId;
  final String createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.month,
    this.accountId,
    required this.createdAt,
  });

  String get title => description;
  String get note => description;

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    final desc = (map['description'] ?? map['title'] ?? map['note'] ?? '').toString();
    return TransactionModel(
      id: id,
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Other',
      description: desc,
      date: map['date'] as String? ?? '',
      month: map['month'] as String? ?? '',
      accountId: map['accountId'] as String?,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'month': month,
      if (accountId != null) 'accountId': accountId,
      'createdAt': createdAt,
    };
  }
}
