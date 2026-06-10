import 'package:flutter/material.dart';
import 'package:tech_borrow/app.dart';
import 'package:tech_borrow/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Notifications
  await NotificationService.initialize();
  
  runApp(const TechborrowApp());
}
