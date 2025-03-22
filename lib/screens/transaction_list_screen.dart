import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_list_item.dart';
import '../widgets/month_selector.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen initializes
    _refreshData();
  }

  void _refreshData() {
    final selectedMonth =
        Provider.of<TransactionProvider>(context, listen: false).selectedMonth;
    Provider.of<TransactionProvider>(context, listen: false)
        .selectMonth(selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        final transactions = transactionProvider.transactions;
        final selectedMonth = transactionProvider.selectedMonth;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transactions'),
            elevation: 0,
            actions: [
              Chip(
                label: _getFilterLabel(transactionProvider.currentFilter) ==
                        "Income"
                    ? const Icon(Icons.arrow_upward)
                    : _getFilterLabel(transactionProvider.currentFilter) ==
                            "Expenses"
                        ? const Icon(Icons.arrow_downward)
                        : _getFilterLabel(transactionProvider.currentFilter) ==
                                "Recurring"
                            ? const Icon(Icons.repeat, color: Colors.blue)
                            : const Icon(Icons.all_inclusive),
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterOptions(context),
                tooltip: 'Filter Transactions',
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: MonthSelector(
                  selectedMonth: selectedMonth,
                  onMonthChanged: (newMonth) {
                    transactionProvider.selectMonth(newMonth);
                  },
                ),
              ),
              const Divider(),
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions for this month',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to add a transaction',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.disabledColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 8.0),
                        itemCount: transactions.length,
                        itemBuilder: (ctx, index) {
                          final transaction = transactions[index];
                          return TransactionListItem(
                            transaction: transaction,
                            onTap: () => _editTransaction(context, transaction),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addTransaction(context),
            tooltip: 'Add Transaction',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    final currentFilter = transactionProvider.currentFilter;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Transactions'),
              selected: currentFilter == TransactionFilter.all,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                Navigator.pop(ctx);
                transactionProvider.setFilter(TransactionFilter.all);
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.green),
              title: const Text('Income Only'),
              selected: currentFilter == TransactionFilter.income,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                Navigator.pop(ctx);
                transactionProvider.setFilter(TransactionFilter.income);
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.red),
              title: const Text('Expenses Only'),
              selected: currentFilter == TransactionFilter.expense,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                Navigator.pop(ctx);
                transactionProvider.setFilter(TransactionFilter.expense);
              },
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(Icons.repeat, color: Colors.blue),
              title: const Text('Recurring Only'),
              selected: currentFilter == TransactionFilter.recurring,
              selectedTileColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () {
                Navigator.pop(ctx);
                transactionProvider.setFilter(TransactionFilter.recurring);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTransaction(BuildContext context) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const TransactionFormScreen(),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _editTransaction(
      BuildContext context, Transaction transaction) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Transaction'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) =>
                        TransactionFormScreen(transaction: transaction),
                  ),
                );
                if (result == true) {
                  _refreshData();
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete,
                  color: Theme.of(context).colorScheme.error),
              title: Text(
                'Delete Transaction',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _deleteTransaction(context, transaction.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(BuildContext context, String id) async {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: theme.colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false)
                  .deleteTransaction(id)
                  .then((_) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(TransactionFilter filter) {
    switch (filter) {
      case TransactionFilter.all:
        return 'All';
      case TransactionFilter.income:
        return 'Income';
      case TransactionFilter.expense:
        return 'Expenses';
      case TransactionFilter.recurring:
        return 'Recurring';
    }
  }
}
