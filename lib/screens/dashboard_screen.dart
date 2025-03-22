import 'package:flutter/material.dart';
import 'package:myfinance/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
// import '../models/transaction.dart';
import '../widgets/summary_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/expense_chart.dart';
import '../widgets/category_legend.dart';
import '../widgets/recent_transactions.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        // Get the current selected month
        final selectedMonth = transactionProvider.selectedMonth;
        final transactions = transactionProvider.transactions;
        final categories = categoryProvider.categories;

        // Use the provider's calculated values
        final totalIncome = transactionProvider.totalIncome;
        final totalExpense = transactionProvider.totalExpense;
        final categoryTotals = transactionProvider.categoryTotals;

        // Calculate balance
        final balance = totalIncome - totalExpense;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Financial Dashboard'),
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'MyFinance',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                ListTile(
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()));
                  },
                ),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await transactionProvider.selectMonth(selectedMonth);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  Center(
                    child: MonthSelector(
                      selectedMonth: selectedMonth,
                      onMonthChanged: (date) {
                        transactionProvider.selectMonth(date);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Income',
                          amount: totalIncome,
                          icon: Icons.arrow_upward,
                          isIncome: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryCard(
                          title: 'Expenses',
                          amount: totalExpense,
                          icon: Icons.arrow_downward,
                          isIncome: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SummaryCard(
                    title: 'Balance',
                    amount: balance,
                    icon: Icons.account_balance_wallet,
                    isIncome: balance >= 0,
                  ),
                  const SizedBox(height: 24),

                  // Expense Chart Section
                  if (totalExpense > 0) ...[
                    Text(
                      'Expense Breakdown',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: ExpenseChart(
                        categoryTotals: categoryTotals,
                        totalExpense: totalExpense,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CategoryLegend(
                      categories: categories,
                      categoryTotals: categoryTotals,
                      totalExpense: totalExpense,
                    ),
                  ] else ...[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expense data for this month',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Recent Transactions Section
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Let's use the simplest approach:
                          // Just tell the user to tap on the Transactions tab
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Tap on Transactions tab to view all transactions'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const RecentTransactions(limit: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
