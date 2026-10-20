import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';
import '../models/daily_budget_model.dart';
import 'expense_detail_screen.dart';

class CalendarTab extends StatefulWidget {
  final UserModel user;
  const CalendarTab({super.key, required this.user});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  int _selectedYear = 2026;
  int _selectedMonth = 10; // 1 - 12 (เริ่มต้นที่ October 2026)

  Map<int, double> _dailyTotalSpent = {};
  Map<int, double> _dailyMaxBudget = {};

  final List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _loadMonthData();
  }

  int get _daysInCurrentMonth => DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  int get _firstWeekdayOffset {
    int w = DateTime(_selectedYear, _selectedMonth, 1).weekday;
    return w == 7 ? 0 : w;
  }

  int get _daysInPrevMonth => DateTime(_selectedYear, _selectedMonth, 0).day;

  void _loadMonthData() async {
    Map<int, double> spentMap = {};
    Map<int, double> budgetMap = {};

    int daysCount = _daysInCurrentMonth;
    String monthStr = _selectedMonth.toString().padLeft(2, '0');

    for (int day = 1; day <= daysCount; day++) {
      String dayStr = day.toString().padLeft(2, '0');
      String dateStr = "$_selectedYear-$monthStr-$dayStr";

      final budget = await DBHelper.instance.getDailyBudget(widget.user.id!, dateStr);
      if (budget != null) {
        budgetMap[day] = budget.maxBudget;
        final expenses = await DBHelper.instance.getExpensesByBudgetId(budget.id!);
        double total = expenses.fold(0.0, (sum, item) => sum + item.amount);
        spentMap[day] = total;
      }
    }

    setState(() {
      _dailyTotalSpent = spentMap;
      _dailyMaxBudget = budgetMap;
    });
  }

  void _prevMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
      _loadMonthData();
    });
  }

  void _nextMonth() {
    if (_selectedYear >= 2027 && _selectedMonth == 12) return;

    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
      _loadMonthData();
    });
  }

  void _onDayTap(int day) async {
    String monthStr = _selectedMonth.toString().padLeft(2, '0');
    String dayStr = day.toString().padLeft(2, '0');
    String dateStr = "$_selectedYear-$monthStr-$dayStr";

    final existingBudget = await DBHelper.instance.getDailyBudget(widget.user.id!, dateStr);

    if (existingBudget != null) {
      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExpenseDetailScreen(budget: existingBudget),
        ),
      );
      if (result == true) {
        _loadMonthData();
      }
    } else {
      final budgetController = TextEditingController();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ตั้งงบสูงสุดวันที่ $dateStr'),
          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'จำนวนเงินงบสูงสุด (บาท)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                double maxBudget = double.tryParse(budgetController.text.trim()) ?? 0.0;
                final budgetObj = DailyBudgetModel(
                  userId: widget.user.id!,
                  date: dateStr,
                  maxBudget: maxBudget,
                );
                await DBHelper.instance.saveDailyBudget(budgetObj);
                final savedBudget = await DBHelper.instance.getDailyBudget(widget.user.id!, dateStr);

                if (!context.mounted) return;
                Navigator.pop(context);

                if (savedBudget != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpenseDetailScreen(budget: savedBudget),
                    ),
                  );
                  if (result == true) {
                    _loadMonthData();
                  }
                }
              },
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int offset = _firstWeekdayOffset;
    int prevMonthDays = _daysInPrevMonth;
    int currentDays = _daysInCurrentMonth;
    int thaiYear = _selectedYear + 543;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('ตารางรายจ่ายประจำวัน'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // Header Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.black87),
                        onPressed: _prevMonth,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_monthNames[_selectedMonth - 1]} $_selectedYear (พ.ศ. $thaiYear)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.black87),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // แถบหัวข้อวัน Sun - Sat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekDays
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Grid ปฏิทิน
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: offset + currentDays,
                itemBuilder: (context, index) {
                  if (index < offset) {
                    int prevDay = prevMonthDays - offset + index + 1;
                    return Center(
                      child: Text(
                        '$prevDay',
                        style: const TextStyle(
                          color: Colors.black26,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  int day = index - offset + 1;
                  double spent = _dailyTotalSpent[day] ?? 0.0;
                  double maxBudget = _dailyMaxBudget[day] ?? 0.0;
                  bool hasBudget = _dailyMaxBudget.containsKey(day);

                  Color? circleBgColor;
                  Color textColor = Colors.black87;
                  bool isOver = false;
                  double overAmount = 0.0;

                  if (hasBudget) {
                    if (spent > maxBudget) {
                      circleBgColor = Colors.red.shade400; // เกินงบ = สีแดง
                      isOver = true;
                      overAmount = spent - maxBudget; // จำนวนเงินที่เกินงบ
                    } else {
                      circleBgColor = Colors.green.shade600; // ไม่เกินงบ = สีเขียว
                    }
                    textColor = Colors.white;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _onDayTap(day),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: circleBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: hasBudget ? FontWeight.bold : FontWeight.normal,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        if (hasBudget)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              isOver
                                  ? 'เกิน ฿${overAmount.toStringAsFixed(0)}' // แสดงจำนวนเงินที่ใช้เกิน
                                  : '฿${spent.toStringAsFixed(0)}',         // แสดงยอดที่ใช้ไปปกติ
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOver
                                    ? Colors.red.shade700
                                    : Colors.green.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}