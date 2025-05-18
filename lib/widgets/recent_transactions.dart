import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class RecentTransactions extends StatelessWidget {
  final int limit;

  const RecentTransactions({Key? key, this.limit = 5}) : super(key: key);

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final transactions = Provider.of<TransactionProvider>(context).transactions;
    final categories = Provider.of<CategoryProvider>(context).categories;

    // Sort transactions by date (most recent first) and take the limit
    final recentTransactions = transactions
        .where((t) => t.date.month == DateTime.now().month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 64,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No transactions this month',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTransactions.length > limit ? limit : recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = recentTransactions[index];
        final category = categories.firstWhere(
          (c) => c.id == transaction.categoryId,
          orElse: () => Category(
            id: 'other',
            name: 'Other',
            icon: Icons.more_horiz,
            color: Colors.grey,
          ),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (transaction.type == TransactionType.income
                        ? Colors.green
                        : category.color)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                transaction.type == TransactionType.income
                    ? Icons.arrow_downward
                    : category.icon,
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : category.color,
              ),
            ),
            title: Text(
              transaction.title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              DateFormat.yMMMd().format(transaction.date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            trailing: Text(
              _formatCurrency(transaction.amount),
              style: TextStyle(
                color: transaction.type == TransactionType.income
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
