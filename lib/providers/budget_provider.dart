import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/budget.dart';
import '../services/notification_service.dart';

class BudgetProvider with ChangeNotifier {
  Budget? _currentBudget;
  final _prefs = SharedPreferences.getInstance();
  final _notificationService = NotificationService();

  Budget? get currentBudget => _currentBudget;

  Future<void> setBudget(double monthlyBudget, double thresholdPercentage) async {
    final prefs = await _prefs;
    final now = DateTime.now();
    final budget = Budget(
      monthlyBudget: monthlyBudget,
      thresholdPercentage: thresholdPercentage,
      month: DateTime(now.year, now.month, 1),
    );

    await prefs.setString('budget', jsonEncode(budget.toJson()));
    _currentBudget = budget;
    notifyListeners();
  }

  Future<void> loadBudget() async {
    final prefs = await _prefs;
    final budgetJson = prefs.getString('budget');
    if (budgetJson != null) {
      final budget = Budget.fromJson(jsonDecode(budgetJson));
      final now = DateTime.now();
      // Check if budget is for current month
      if (budget.month.year == now.year && budget.month.month == now.month) {
        _currentBudget = budget;
        notifyListeners();
      }
    }
  }

  Future<void> checkBudgetThreshold(double currentSpending) async {
    if (_currentBudget == null) return;

    // Check if we've exceeded the threshold
    if (currentSpending >= _currentBudget!.thresholdAmount) {
      // Check if we've already shown a notification for this threshold
      final prefs = await _prefs;
      final lastNotificationKey = 'budget_notification_${_currentBudget!.month.millisecondsSinceEpoch}';
      final lastNotification = prefs.getInt(lastNotificationKey);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only show notification if we haven't shown one in the last hour
      if (lastNotification == null || (now - lastNotification) > 3600000) {
        await _notificationService.showBudgetAlert(
          currentSpending,
          _currentBudget!.monthlyBudget,
        );
        // Save the notification timestamp
        await prefs.setInt(lastNotificationKey, now);
      }
    }
  }
} 