import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myfinance/models/transaction.dart';
import 'package:myfinance/models/category.dart';
import 'package:myfinance/providers/category_provider.dart';
import 'package:myfinance/widgets/transaction_list_item.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('TransactionListItem displays correct transaction information',
      (WidgetTester tester) async {
    // Create a mock transaction
    final transaction = Transaction(
      id: 'test-id',
      title: 'Groceries',
      amount: 50.0,
      type: TransactionType.expense,
      categoryId: 'food-category',
      date: DateTime(2023, 5, 15),
    );

    // Create a mock category
    final category = Category(
      id: 'food-category',
      name: 'Food',
      color: Colors.red,
      icon: Icons.restaurant,
    );

    // Create a mock CategoryProvider
    final mockCategoryProvider = MockCategoryProvider(category);

    // Build our widget
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<CategoryProvider>.value(
          value: mockCategoryProvider,
          child: Scaffold(
            body: TransactionListItem(
              transaction: transaction,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    // Verify that the transaction title is displayed
    expect(find.text('Groceries'), findsOneWidget);

    // Verify that the transaction amount is displayed with the correct format
    expect(find.text('-₹ 50.00'), findsOneWidget);

    // Verify that the category name is displayed
    expect(find.text('Food • May 15, 2023'), findsOneWidget);
  });
}

class MockCategoryProvider extends CategoryProvider {
  final Category _mockCategory;

  MockCategoryProvider(this._mockCategory);

  @override
  Category? getCategoryById(String id) {
    if (id == _mockCategory.id) {
      return _mockCategory;
    }
    return null;
  }
}
