import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Export data to JSON file for backup
  Future<String> exportData() async {
    try {
      // Get all transactions and categories
      final transactions = await _databaseService.getTransactions();
      final categories = await _databaseService.getCategories();

      // Create data structure
      final data = {
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(data);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'myfinance_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(jsonData);

      return filePath;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  // Import data from JSON file
  Future<void> importData(String filePath) async {
    try {
      final file = File(filePath);
      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData);

      // Begin transaction
      final db = await _databaseService.database;
      await db.transaction((txn) async {
        // Clear existing data (optional - could merge instead)
        await txn.delete('transactions');
        await txn.delete('categories');

        // Import categories first (due to foreign key constraints)
        final categoriesList = data['categories'] as List;
        for (var categoryMap in categoriesList) {
          final category = Category.fromMap(categoryMap);
          await txn.insert('categories', category.toMap());
        }

        // Import transactions
        final transactionsList = data['transactions'] as List;
        for (var transactionMap in transactionsList) {
          final transaction = Transaction.fromMap(transactionMap);
          await txn.insert('transactions', transaction.toMap());
        }
      });
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  // List available backup files
  Future<List<FileSystemEntity>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<FileSystemEntity> files = await directory.list().toList();
      return files.where((file) {
        return file.path.contains('myfinance_backup_') &&
            file.path.endsWith('.json');
      }).toList();
    } catch (e) {
      throw Exception('Failed to list backup files: $e');
    }
  }
}
