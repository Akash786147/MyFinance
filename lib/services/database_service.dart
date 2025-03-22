import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/transaction.dart';
import '../models/category.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'myfinance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        color INTEGER,
        icon INTEGER,
        fontFamily TEXT,
        fontPackage TEXT
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        title TEXT,
        amount REAL,
        type INTEGER,
        categoryId TEXT,
        date INTEGER,
        isRecurring INTEGER,
        recurrenceRule TEXT,
        FOREIGN KEY (categoryId) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    List<Category> defaultCategories = [
      Category(
        name: 'Food',
        color: Colors.red,
        icon: Icons.restaurant,
      ),
      Category(
        name: 'Transportation',
        color: Colors.blue,
        icon: Icons.directions_car,
      ),
      Category(
        name: 'Housing',
        color: Colors.green,
        icon: Icons.home,
      ),
      Category(
        name: 'Entertainment',
        color: Colors.purple,
        icon: Icons.movie,
      ),
      Category(
        name: 'Salary',
        color: Colors.teal,
        icon: Icons.attach_money,
      ),
      Category(
        name: 'Study',
        color: Colors.amber,
        icon: Icons.school,
      ),
      Category(
        name: 'Other',
        color: Colors.grey,
        icon: Icons.more_horiz,
      ),
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // CRUD operations for Categories
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  Future<Category> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Category.fromMap(maps.first);
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCategory(Category category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD operations for Transactions
  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionsByMonth(DateTime date) async {
    final db = await database;
    final startDate = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;
    final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<Transaction> getTransactionById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    return Transaction.fromMap(maps.first);
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getCategoryTotals(
      DateTime date, TransactionType type) async {
    final db = await database;
    final startDate = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;
    final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch;

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT categoryId, SUM(amount) as total
      FROM transactions
      WHERE date BETWEEN ? AND ? AND type = ?
      GROUP BY categoryId
    ''', [startDate, endDate, type.index]);

    Map<String, double> totals = {};
    for (var result in results) {
      totals[result['categoryId']] = result['total'];
    }

    return totals;
  }

  Future<double> getTotalForPeriod(DateTime date, TransactionType type) async {
    final db = await database;
    final startDate = DateTime(date.year, date.month, 1).millisecondsSinceEpoch;
    final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE date BETWEEN ? AND ? AND type = ?
    ''', [startDate, endDate, type.index]);

    return result.first['total'] == null
        ? 0.0
        : result.first['total'] as double;
  }

  Future<List<Transaction>> getRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'isRecurring = 1',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }
}
