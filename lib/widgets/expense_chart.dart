import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/category_provider.dart';
import 'package:provider/provider.dart';

class ExpenseChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalExpense;

  const ExpenseChart({
    super.key,
    required this.categoryTotals,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final theme = Theme.of(context);

    if (categoryTotals.isEmpty || totalExpense == 0) {
      return Center(
        child: Text(
          'No expenses to display',
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    final sections = _getSections(categoryTotals, categoryProvider, theme);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
          enabled: true,
        ),
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        centerSpaceColor: theme.colorScheme.surface,
      ),
    );
  }

  List<PieChartSectionData> _getSections(
    Map<String, double> categoryTotals,
    CategoryProvider categoryProvider,
    ThemeData theme,
  ) {
    final List<PieChartSectionData> sections = [];

    // Create pie chart sections
    categoryTotals.forEach((categoryId, amount) {
      final category = categoryProvider.getCategoryById(categoryId);
      final percentage = (amount / totalExpense) * 100;

      sections.add(
        PieChartSectionData(
          color: category?.color ?? theme.colorScheme.primary,
          value: amount,
          title: percentage >= 10 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: percentage < 10
              ? _Badge(
                  category?.icon ?? Icons.circle,
                  category?.color ?? theme.colorScheme.primary,
                )
              : null,
          badgePositionPercentageOffset: 1.2,
        ),
      );
    });

    return sections;
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Badge(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 3,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 14,
        ),
      ),
    );
  }
}
