class GoalModel {
  final String id;
  final String emoji;
  final String title;
  final double target;
  final double saved;
  final String targetDate;
  final String createdAt;

  const GoalModel({
    required this.id,
    required this.emoji,
    required this.title,
    required this.target,
    required this.saved,
    required this.targetDate,
    required this.createdAt,
  });

  factory GoalModel.fromMap(String id, Map<String, dynamic> map) {
    return GoalModel(
      id: id,
      emoji: map['emoji'] as String? ?? '🎯',
      title: map['title'] as String? ?? '',
      target: (map['target'] as num?)?.toDouble() ?? 0.0,
      saved: (map['saved'] as num?)?.toDouble() ?? 0.0,
      targetDate: map['targetDate'] as String? ?? '',
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'title': title,
      'target': target,
      'saved': saved,
      'targetDate': targetDate,
      'createdAt': createdAt,
    };
  }
}
