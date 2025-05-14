import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:lottie/lottie.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({Key? key, this.transaction}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  late TransactionType _type;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _isRecurring = false;
  String? _recurrenceRule;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _formAnimation;
  int _selectedDayOfMonth = 1;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    if (widget.transaction != null) {
      // Edit mode
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _type = widget.transaction!.type;
      _categoryId = widget.transaction!.categoryId;
      _date = widget.transaction!.date;
      _isRecurring = widget.transaction!.isRecurring;
      _recurrenceRule = widget.transaction!.recurrenceRule;

      if (_recurrenceRule != null) {
        _selectedDayOfMonth = int.tryParse(_recurrenceRule!) ?? 1;
      }
    } else {
      // Add mode
      _type = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    try {
      final amount = double.parse(value);
      if (amount <= 0) {
        return 'Amount must be greater than zero';
      }
    } catch (e) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? _validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final amount = double.parse(_amountController.text);
      final transaction = Transaction(
        id: widget.transaction?.id ?? const Uuid().v4(),
        title: _titleController.text,
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        date: _date,
        isRecurring: _isRecurring,
        recurrenceRule: _isRecurring ? _selectedDayOfMonth.toString() : null,
      );

      try {
        if (widget.transaction == null) {
          // Add new transaction
          await Provider.of<TransactionProvider>(context, listen: false)
              .addTransaction(transaction);
        } else {
          // Update existing transaction
          await Provider.of<TransactionProvider>(context, listen: false)
              .updateTransaction(transaction);
        }

        // Reverse animation before popping
        await _animationController.reverse();
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.transaction == null
                    ? 'Transaction added successfully'
                    : 'Transaction updated successfully',
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildCategorySelector() {
    final categories = [
      Category(id: '1', name: 'Food & Dining', icon: Icons.restaurant, color: Colors.orange),
      Category(id: '2', name: 'Transportation', icon: Icons.directions_car, color: Colors.blue),
      Category(id: '3', name: 'Housing', icon: Icons.home, color: Colors.brown),
      Category(id: '4', name: 'Entertainment', icon: Icons.movie, color: Colors.purple),
      Category(id: '5', name: 'Shopping', icon: Icons.shopping_bag, color: Colors.pink),
      Category(id: '6', name: 'Utilities', icon: Icons.power, color: Colors.red),
      Category(id: '7', name: 'Healthcare', icon: Icons.medical_services, color: Colors.green),
      Category(id: '8', name: 'Travel', icon: Icons.flight, color: Colors.teal),
      Category(id: '9', name: 'Education', icon: Icons.school, color: Colors.indigo),
      Category(id: '10', name: 'Groceries', icon: Icons.shopping_cart, color: Colors.lightGreen),
      Category(id: '11', name: 'Subscriptions', icon: Icons.subscriptions, color: Colors.deepPurple),
      Category(id: '12', name: 'Personal Care', icon: Icons.spa, color: Colors.cyan),
      Category(id: '13', name: 'Gifts & Donations', icon: Icons.card_giftcard, color: Colors.amber),
      Category(id: '14', name: 'Other', icon: Icons.more_horiz, color: Colors.grey),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category.id == _categoryId;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _categoryId = category.id;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color.withOpacity(0.2)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? category.color
                              : Colors.grey.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category.icon,
                            color: isSelected
                                ? category.color
                                : category.color.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? category.color
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_categoryId == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please select a category',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isRecurring ? 170 : 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recurring Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                Text(
                  'Repeat on day of month:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 28,
                    itemBuilder: (context, index) {
                      final day = index + 1;
                      final isSelected = day == _selectedDayOfMonth;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDayOfMonth = day;
                          });
                        },
                        child: Container(
                          width: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Transaction will repeat monthly on day $_selectedDayOfMonth',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextFormField(
          controller: _amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            border: InputBorder.none,
            prefixText: '₹ ',
            prefixStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: _validateAmount,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.transaction == null
                        ? 'Adding Transaction...'
                        : 'Updating Transaction...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )
          : FadeTransition(
              opacity: _formAnimation,
              child: ScaleTransition(
                scale: _formAnimation,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Type selector
                                  Container(
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Theme.of(context).colorScheme.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _type = TransactionType.expense;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              decoration: BoxDecoration(
                                                color: _type == TransactionType.expense
                                                    ? Theme.of(context).colorScheme.error.withOpacity(0.2)
                                                    : null,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  bottomLeft: Radius.circular(12),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_upward,
                                                    color: _type == TransactionType.expense
                                                        ? Theme.of(context).colorScheme.error
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Expense',
                                                    style: TextStyle(
                                                      color: _type == TransactionType.expense
                                                          ? Theme.of(context).colorScheme.error
                                                          : Colors.grey,
                                                      fontWeight: _type == TransactionType.expense
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _type = TransactionType.income;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 200),
                                              decoration: BoxDecoration(
                                                color: _type == TransactionType.income
                                                    ? Colors.green.withOpacity(0.2)
                                                    : null,
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(12),
                                                  bottomRight: Radius.circular(12),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_downward,
                                                    color: _type == TransactionType.income
                                                        ? Colors.green
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Income',
                                                    style: TextStyle(
                                                      color: _type == TransactionType.income
                                                          ? Colors.green
                                                          : Colors.grey,
                                                      fontWeight: _type == TransactionType.income
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Title
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      child: TextFormField(
                                        controller: _titleController,
                                        decoration: const InputDecoration(
                                          labelText: 'Title',
                                          border: InputBorder.none,
                                        ),
                                        validator: _validateTitle,
                                      ),
                                    ),
                                  ),

                                  // Amount
                                  _buildAmountField(),

                                  // Date picker
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: ListTile(
                                      title: const Text('Date'),
                                      subtitle: Text(
                                          DateFormat.yMMMd().format(_date)),
                                      trailing:
                                          const Icon(Icons.calendar_today),
                                      onTap: () async {
                                        final pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: _date,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );
                                        if (pickedDate != null) {
                                          setState(() {
                                            _date = pickedDate;
                                          });
                                        }
                                      },
                                    ),
                                  ),

                                  // Category selector
                                  _buildCategorySelector(),

                                  // Recurring section
                                  _buildRecurringSection(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveTransaction,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.transaction == null
                                  ? 'Add Transaction'
                                  : 'Update Transaction',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
