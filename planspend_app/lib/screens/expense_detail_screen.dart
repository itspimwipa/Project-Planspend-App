import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/daily_budget_model.dart';
import '../models/expense_model.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final DailyBudgetModel budget;
  const ExpenseDetailScreen({super.key, required this.budget});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  List<ExpenseModel> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    if (widget.budget.id != null) {
      final data = await DBHelper.instance.getExpensesByBudgetId(widget.budget.id!);
      setState(() {
        _expenses = data;
      });
    }
  }

  void _addExpense() async {
    final title = _titleController.text.trim();
    final amountText = _amountController.text.trim();

    if (title.isEmpty || amountText.isEmpty) return;

    final amount = double.tryParse(amountText) ?? 0.0;
    if (widget.budget.id != null) {
      final newExpense = ExpenseModel(
        dailyBudgetId: widget.budget.id!,
        title: title,
        amount: amount,
      );
      await DBHelper.instance.addExpense(newExpense);
      _titleController.clear();
      _amountController.clear();
      _loadExpenses();
    }
  }

  void _deleteExpense(int expenseId) async {
    await DBHelper.instance.deleteExpense(expenseId);
    _loadExpenses();
  }

  // ยอดรวมใช้จ่ายทั้งหมด
  double get _totalExpense {
    return _expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // ยอดเงินคงเหลือ
  double get _remainingBudget {
    return widget.budget.maxBudget - _totalExpense;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ค่าใช้จ่ายวันที่ ${widget.budget.date}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // แถบสรุปงบประมาณ
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'งบสูงสุด: ฿${widget.budget.maxBudget.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'ใช้ไปแล้ว: ฿${_totalExpense.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _totalExpense > widget.budget.maxBudget 
                            ? Colors.red 
                            : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      'คงเหลือ: ฿${_remainingBudget.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _remainingBudget < 0 
                            ? Colors.red 
                            : Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'ชื่อรายการสินค้า'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ราคา'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepPurple, size: 36),
                  onPressed: _addExpense,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _expenses.length,
                itemBuilder: (context, index) {
                  final item = _expenses[index];
                  return ListTile(
                    title: Text(item.title),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '฿${item.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            if (item.id != null) {
                              _deleteExpense(item.id!);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('ยืนยัน / กลับหน้าตาราง'),
            ),
          ],
        ),
      ),
    );
  }
}