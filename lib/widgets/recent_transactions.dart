import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../models/transaction.dart';

class RecentTransactions extends StatelessWidget {
  final int limit;

  const RecentTransactions({Key? key, this.limit = 5}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final transactions = transactionProvider.transactions;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'No transactions for this month',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ),
      );
    }

    // Get the limited number of transactions
    final limitedTransactions = transactions.take(limit).toList();

    return Column(
      children: [
        for (final transaction in limitedTransactions)
          TransactionListItem(
            transaction: transaction,
            onTap: () {
              // Navigation to transaction details can be handled by parent
              Navigator.pushNamed(
                context,
                '/transaction_details',
                arguments: transaction,
              ).catchError((e) {
                // If route doesn't exist, show a simple dialog with details
                _showTransactionDetails(context, transaction);
                return null;
              });
            },
          ),
      ],
    );
  }

  // Fallback if transaction details route isn't defined
  void _showTransactionDetails(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(transaction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              'Amount',
              '₹ ${transaction.amount.toStringAsFixed(2)}',
              Icons.attach_money,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Type',
              transaction.type == TransactionType.expense
                  ? 'Expense'
                  : 'Income',
              transaction.type == TransactionType.expense
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              'Date',
              transaction.date.toString().substring(0, 10),
              Icons.calendar_today,
            ),
            if (transaction.isRecurring) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                context,
                'Recurring',
                'Yes',
                Icons.repeat,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
