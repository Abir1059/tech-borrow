import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 1. Request Permission (Android 13+)
    _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    // 2. Initialize Local Notifications & Timezones
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);
  }

  static Future<void> scheduleDeadlineReminder(String itemTitle, DateTime deadline) async {
    final scheduleDate = deadline.subtract(const Duration(days: 2));
    
    if (scheduleDate.isAfter(DateTime.now())) {
      await _localNotifications.zonedSchedule(
        itemTitle.hashCode, 
        'Return Reminder',
        'Your borrow period for "$itemTitle" ends in 2 days!',
        tz.TZDateTime.from(scheduleDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadline_reminders',
            'Deadline Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint("Reminder scheduled for: $scheduleDate");
    }
  }

  static Future<void> showBorrowRequestNotification(String itemTitle, String senderEmail) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'borrow_requests_channel',
      'Borrow Requests',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      'New Borrow Request',
      '$senderEmail wants to borrow your "$itemTitle"',
      details,
    );
  }
}
