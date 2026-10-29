class AccountModel {
  final String id;
  final String name;
  final double balance;
  final String createdAt;

  const AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  factory AccountModel.fromMap(String id, Map<String, dynamic> map) {
    return AccountModel(
      id: id,
      name: map['name'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'balance': balance,
      'createdAt': createdAt,
    };
  }
}
