import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/models/transaction.dart';

void main() {
  group('Transaction', () {
    test('should create a transaction with correct properties', () {
      // Arrange
      final transaction = Transaction(
        title: 'Groceries',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'category1',
        date: DateTime(2023, 5, 15),
      );

      // Assert
      expect(transaction.title, 'Groceries');
      expect(transaction.amount, 50.0);
      expect(transaction.type, TransactionType.expense);
      expect(transaction.categoryId, 'category1');
      expect(transaction.date, DateTime(2023, 5, 15));
      expect(transaction.isRecurring, false);
      expect(transaction.recurrenceRule, null);
      expect(transaction.id, isNotNull);
    });

    test('should convert to and from map correctly', () {
      // Arrange
      final transaction = Transaction(
        id: 'test-id',
        title: 'Salary',
        amount: 2000.0,
        type: TransactionType.income,
        categoryId: 'category2',
        date: DateTime(2023, 5, 1),
        isRecurring: true,
        recurrenceRule: '1',
      );

      // Act
      final map = transaction.toMap();
      final fromMap = Transaction.fromMap(map);

      // Assert
      expect(fromMap.id, transaction.id);
      expect(fromMap.title, transaction.title);
      expect(fromMap.amount, transaction.amount);
      expect(fromMap.type, transaction.type);
      expect(fromMap.categoryId, transaction.categoryId);
      expect(fromMap.date.year, transaction.date.year);
      expect(fromMap.date.month, transaction.date.month);
      expect(fromMap.date.day, transaction.date.day);
      expect(fromMap.isRecurring, transaction.isRecurring);
      expect(fromMap.recurrenceRule, transaction.recurrenceRule);
    });

    test('copyWith should update only specified properties', () {
      // Arrange
      final transaction = Transaction(
        id: 'test-id',
        title: 'Groceries',
        amount: 50.0,
        type: TransactionType.expense,
        categoryId: 'category1',
        date: DateTime(2023, 5, 15),
      );

      // Act
      final updatedTransaction = transaction.copyWith(
        title: 'Food',
        amount: 75.0,
      );

      // Assert
      expect(updatedTransaction.id, transaction.id);
      expect(updatedTransaction.title, 'Food');
      expect(updatedTransaction.amount, 75.0);
      expect(updatedTransaction.type, transaction.type);
      expect(updatedTransaction.categoryId, transaction.categoryId);
      expect(updatedTransaction.date, transaction.date);
      expect(updatedTransaction.isRecurring, transaction.isRecurring);
    });
  });
}
