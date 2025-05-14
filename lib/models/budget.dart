import 'package:flutter/material.dart';

class Budget {
  final double monthlyBudget;
  final double thresholdPercentage; // Percentage of budget that triggers alert
  final DateTime month;

  Budget({
    required this.monthlyBudget,
    required this.thresholdPercentage,
    required this.month,
  });

  double get thresholdAmount => monthlyBudget * (thresholdPercentage / 100);

  Map<String, dynamic> toJson() {
    return {
      'monthlyBudget': monthlyBudget,
      'thresholdPercentage': thresholdPercentage,
      'month': month.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthlyBudget: json['monthlyBudget'].toDouble(),
      thresholdPercentage: json['thresholdPercentage'].toDouble(),
      month: DateTime.parse(json['month']),
    );
  }
} 