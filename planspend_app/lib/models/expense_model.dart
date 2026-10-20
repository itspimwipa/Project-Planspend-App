class ExpenseModel {
  final int? id;
  final int dailyBudgetId;
  final String title;
  final double amount;

  ExpenseModel({
    this.id,
    required this.dailyBudgetId,
    required this.title,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'daily_budget_id': dailyBudgetId,
      'title': title,
      'amount': amount,
    };
  }
}