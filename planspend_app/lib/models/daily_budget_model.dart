class DailyBudgetModel {
  final int? id;
  final int userId;
  final String date; // รูปแบบ 'YYYY-MM-DD'
  final double maxBudget;

  DailyBudgetModel({
    this.id,
    required this.userId,
    required this.date,
    required this.maxBudget,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date,
      'max_budget': maxBudget,
    };
  }

  factory DailyBudgetModel.fromMap(Map<String, dynamic> map) {
    return DailyBudgetModel(
      id: map['id'],
      userId: map['user_id'],
      date: map['date'],
      maxBudget: map['max_budget']?.toDouble() ?? 0.0,
    );
  }
}