import 'package:uuid/uuid.dart';

enum TransactionType {
  income,
  expense,
}

class Transaction {
  final String id;
  String title;
  double amount;
  TransactionType type;
  String categoryId;
  DateTime date;
  bool isRecurring;
  String? recurrenceRule; // For recurring transactions

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.isRecurring = false,
    this.recurrenceRule,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.index,
      'categoryId': categoryId,
      'date': date.millisecondsSinceEpoch,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceRule': recurrenceRule,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: TransactionType.values[map['type']],
      categoryId: map['categoryId'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isRecurring: map['isRecurring'] == 1,
      recurrenceRule: map['recurrenceRule'],
    );
  }

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    bool? isRecurring,
    String? recurrenceRule,
  }) {
    return Transaction(
      id: this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
} 