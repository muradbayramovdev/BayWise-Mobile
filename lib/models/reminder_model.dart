class ReminderModel {
  final String id;
  final String title;
  final String dueDate; // yyyy-MM-dd
  final String createdAt;

  const ReminderModel({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
  });

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      title: map['title'] as String? ?? '',
      dueDate: map['dueDate'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'dueDate': dueDate,
      'createdAt': createdAt,
    };
  }
}
