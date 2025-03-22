import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/transaction.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final StreamController<Notification> _notificationStreamController =
      StreamController<Notification>.broadcast();

  Stream<Notification> get notificationStream =>
      _notificationStreamController.stream;
  Timer? _checkNotificationsTimer;
  List<Notification> _pendingNotifications = [];

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Start checking for notifications
    _checkNotificationsTimer = Timer.periodic(
      const Duration(hours: 1), // Check every hour
      (_) => _checkForDueNotifications(),
    );

    // Check for notifications immediately on startup
    await _checkForDueNotifications();
  }

  Future<void> _checkForDueNotifications() async {
    try {
      // Get recurring transactions
      final recurringTransactions =
          await _databaseService.getRecurringTransactions();

      // Get today's date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      _pendingNotifications = [];

      // Check each recurring transaction
      for (var transaction in recurringTransactions) {
        if (transaction.recurrenceRule != null) {
          // Parse the recurrence rule (day of month)
          final dayOfMonth = int.tryParse(transaction.recurrenceRule!) ?? 1;

          // Calculate next occurrence date
          final nextOccurrence = DateTime(now.year, now.month, dayOfMonth);
          final oneDayBefore = nextOccurrence.subtract(const Duration(days: 1));

          // If today is the day before the payment, show a notification
          if (today.isAtSameMomentAs(DateTime(
              oneDayBefore.year, oneDayBefore.month, oneDayBefore.day))) {
            _pendingNotifications.add(
              Notification(
                id: transaction.id.hashCode,
                title: 'Payment Reminder',
                body:
                    '${transaction.title} payment of ₹ ${transaction.amount.toStringAsFixed(2)} is due tomorrow',
                date: DateTime.now(),
                transactionId: transaction.id,
              ),
            );
          }

          // If today is the payment day, show a notification
          if (today.isAtSameMomentAs(DateTime(
              nextOccurrence.year, nextOccurrence.month, nextOccurrence.day))) {
            _pendingNotifications.add(
              Notification(
                id: transaction.id.hashCode + 1,
                title: 'Payment Due Today',
                body:
                    '${transaction.title} payment of ₹ ${transaction.amount.toStringAsFixed(2)} is due today',
                date: DateTime.now(),
                transactionId: transaction.id,
              ),
            );
          }
        }
      }

      // Send notifications to the stream
      for (var notification in _pendingNotifications) {
        // Check if notification has already been shown today
        if (!await _hasNotificationBeenShownToday(notification.id)) {
          _notificationStreamController.add(notification);
          await _markNotificationAsShown(notification.id);
        }
      }
    } catch (e) {
      print('Error checking for notifications: $e');
    }
  }

  Future<bool> _hasNotificationBeenShownToday(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString('notification_${id}_last_shown');

    if (lastShownStr == null) {
      return false;
    }

    final lastShown = DateTime.parse(lastShownStr);
    final now = DateTime.now();

    return lastShown.year == now.year &&
        lastShown.month == now.month &&
        lastShown.day == now.day;
  }

  Future<void> _markNotificationAsShown(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'notification_${id}_last_shown', DateTime.now().toIso8601String());
  }

  Future<void> scheduleNotification(Transaction transaction) async {
    if (!transaction.isRecurring || transaction.recurrenceRule == null) {
      return;
    }

    // The actual scheduling is handled by the periodic check
    // This method can be used to immediately check if a notification should be shown
    // after a transaction is added or updated
    _checkForDueNotifications();
  }

  Future<void> cancelNotification(Transaction transaction) async {
    // No need to cancel external notifications anymore
    // We'll just stop including this transaction in future checks
  }

  List<Notification> getPendingNotifications() {
    return _pendingNotifications;
  }

  void dispose() {
    _checkNotificationsTimer?.cancel();
    _notificationStreamController.close();
  }
}

class Notification {
  final int id;
  final String title;
  final String body;
  final DateTime date;
  final String transactionId;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    required this.transactionId,
  });
}

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  NotificationOverlayState createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  final List<Notification> _notifications = [];
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Listen for notifications
    NotificationService().notificationStream.listen(_showNotification);
  }

  void _showNotification(Notification notification) {
    setState(() {
      _notifications.add(notification);
    });

    _animationController.forward();

    // Hide notification after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _notifications.removeWhere((n) => n.id == notification.id);
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_notifications.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _offsetAnimation,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.secondary,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _notifications.first.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              _animationController.reverse().then((_) {
                                if (mounted) {
                                  setState(() {
                                    _notifications.removeAt(0);
                                  });
                                }
                              });
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _notifications.first.body,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('MMM d, y - h:mm a')
                            .format(_notifications.first.date),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
