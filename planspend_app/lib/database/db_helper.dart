import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/daily_budget_model.dart';
import '../models/expense_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  static final List<UserModel> _webUsers = [];
  static final List<DailyBudgetModel> _webDailyBudgets = [];
  static final List<ExpenseModel> _webExpenses = [];
  static int _webUserIdCounter = 1;
  static int _webBudgetIdCounter = 1;
  static int _webExpenseIdCounter = 1;

  DBHelper._init();

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB('planspend.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP TABLE IF EXISTS daily_budgets');
          await db.execute('DROP TABLE IF EXISTS expenses');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        profile_image_path TEXT,
        monthly_income REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        max_budget REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        daily_budget_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (daily_budget_id) REFERENCES daily_budgets (id)
      )
    ''');
  }

  // ดึงรายการผู้ใช้ทั้งหมดที่มีในฐานข้อมูล
  Future<List<UserModel>> getAllUsers() async {
    if (kIsWeb) {
      return List.from(_webUsers);
    }
    final db = await database;
    final result = await db!.query('users');
    return result.map((json) => UserModel.fromMap(json)).toList();
  }

  // ลบผู้ใช้
  Future<int> deleteUser(int id) async {
    if (kIsWeb) {
      _webUsers.removeWhere((u) => u.id == id);
      return 1;
    }
    final db = await database;
    return await db!.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<UserModel> loginOrRegisterUser(String name) async {
    if (kIsWeb) {
      try {
        final existing = _webUsers.firstWhere((u) => u.name == name);
        return existing;
      } catch (_) {
        final newUser = UserModel(
          id: _webUserIdCounter++,
          name: name,
          monthlyIncome: 0.0,
        );
        _webUsers.add(newUser);
        return newUser;
      }
    }

    final db = await database;
    final result = await db!.query(
      'users',
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    } else {
      final newUser = UserModel(name: name, monthlyIncome: 0.0);
      final id = await db.insert('users', newUser.toMap());
      return UserModel(id: id, name: name, monthlyIncome: 0.0);
    }
  }

  Future<int> updateUser(UserModel user) async {
    if (kIsWeb) {
      final index = _webUsers.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _webUsers[index] = user;
        return 1;
      }
      return 0;
    }

    final db = await database;
    return await db!.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<DailyBudgetModel?> getDailyBudget(int userId, String date) async {
    if (kIsWeb) {
      try {
        return _webDailyBudgets.firstWhere(
          (b) => b.userId == userId && b.date == date,
        );
      } catch (_) {
        return null;
      }
    }

    final db = await database;
    final result = await db!.query(
      'daily_budgets',
      where: 'user_id = ? AND date = ?',
      whereArgs: [userId, date],
    );

    if (result.isNotEmpty) {
      return DailyBudgetModel.fromMap(result.first);
    }
    return null;
  }

  Future<int> saveDailyBudget(DailyBudgetModel budget) async {
    if (kIsWeb) {
      final existingIndex = _webDailyBudgets.indexWhere(
        (b) => b.userId == budget.userId && b.date == budget.date,
      );
      if (existingIndex != -1) {
        final old = _webDailyBudgets[existingIndex];
        _webDailyBudgets[existingIndex] = DailyBudgetModel(
          id: old.id,
          userId: budget.userId,
          date: budget.date,
          maxBudget: budget.maxBudget,
        );
        return old.id!;
      } else {
        final newId = _webBudgetIdCounter++;
        final newBudget = DailyBudgetModel(
          id: newId,
          userId: budget.userId,
          date: budget.date,
          maxBudget: budget.maxBudget,
        );
        _webDailyBudgets.add(newBudget);
        return newId;
      }
    }

    final db = await database;
    final existing = await getDailyBudget(budget.userId, budget.date);
    if (existing != null) {
      return await db!.update(
        'daily_budgets',
        {'max_budget': budget.maxBudget},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      return await db!.insert('daily_budgets', budget.toMap());
    }
  }

  Future<int> addExpense(ExpenseModel expense) async {
    if (kIsWeb) {
      final newId = _webExpenseIdCounter++;
      final newExp = ExpenseModel(
        id: newId,
        dailyBudgetId: expense.dailyBudgetId,
        title: expense.title,
        amount: expense.amount,
      );
      _webExpenses.add(newExp);
      return newId;
    }

    final db = await database;
    return await db!.insert('expenses', expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      _webExpenses.removeWhere((e) => e.id == id);
      return 1;
    }

    final db = await database;
    return await db!.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ExpenseModel>> getExpensesByBudgetId(int dailyBudgetId) async {
    if (kIsWeb) {
      return _webExpenses.where((e) => e.dailyBudgetId == dailyBudgetId).toList();
    }

    final db = await database;
    final result = await db!.query(
      'expenses',
      where: 'daily_budget_id = ?',
      whereArgs: [dailyBudgetId],
    );
    return result.map((json) => ExpenseModel(
      id: json['id'] as int?,
      dailyBudgetId: json['daily_budget_id'] as int,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
    )).toList();
  }
}