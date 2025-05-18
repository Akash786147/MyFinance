import 'package:flutter/material.dart';
import 'package:myfinance/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/budget_provider.dart';
import 'budget_settings_screen.dart';
import '../widgets/summary_card.dart';
import '../widgets/month_selector.dart';
import '../widgets/expense_chart.dart';
import '../widgets/category_legend.dart';
import '../widgets/recent_transactions.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _budgetCheckTimer;

  @override
  void initState() {
    super.initState();
    // Set the BudgetProvider in TransactionProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      transactionProvider.setBudgetProvider(budgetProvider);
    });
    // Check budget every minute
    _budgetCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkBudget();
    });
    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBudget();
    });
  }

  @override
  void dispose() {
    _budgetCheckTimer?.cancel();
    super.dispose();
  }

  void _checkBudget() {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    
    if (budgetProvider.currentBudget != null) {
      budgetProvider.checkBudgetThreshold(transactionProvider.totalExpense);
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, BudgetProvider>(
      builder: (context, transactionProvider, budgetProvider, child) {
        // Get the current selected month
        final selectedMonth = transactionProvider.selectedMonth;
        final transactions = transactionProvider.transactions;
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        final categories = categoryProvider.categories;

        // Use the provider's calculated values
        final totalIncome = transactionProvider.totalIncome;
        final totalExpense = transactionProvider.totalExpense;
        final categoryTotals = transactionProvider.categoryTotals;

        // Calculate balance
        final balance = totalIncome - totalExpense;

        final totalExpenses = totalExpense;
        final budget = budgetProvider.currentBudget;
        final progress = budget != null ? totalExpenses / budget.monthlyBudget : 0.0;

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
                      'KharchaCheck',
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Monthly Budget',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BudgetSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (budget != null) ...[
                            LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? Colors.red : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_formatCurrency(totalExpenses)} / ${_formatCurrency(budget.monthlyBudget)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (progress >= budget.thresholdPercentage / 100)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'You have reached ${(budget.thresholdPercentage).toStringAsFixed(0)}% of your budget!',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ] else
                            const Text(
                              'Set your monthly budget in settings',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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
