import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AndroidNotificationDetails androidPlatformChannelSpecifics =
      // ignore: prefer_const_constructors
      AndroidNotificationDetails(
    'Ozod_First', //Required for Android 8.0 or after
    'Ozod_First', //Required for Android 8.0 or after
    channelDescription:
        'Ozod First messaging channel', //Required for Android 8.0 or after
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );
  final DarwinNotificationDetails iOSPlatformChannelSpecifics =
      // ignore: prefer_const_constructors
      DarwinNotificationDetails(
    presentAlert:
        true, // Present an alert when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
    presentBadge:
        true, // Present the badge number when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
    presentSound:
        true, // Play a sound when the notification is displayed and the application is in the foreground (only from iOS 10 onwards)
    // badgeNumber: int?, // The application's icon badge number
  );

  Future<void> init() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('logonotif');

    final DarwinInitializationSettings initializationSettingsIOS =
        // ignore: prefer_const_constructors
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: null);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  void showLocalNotification(String title, String body) async {
    NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin
        .show(1, title, body, platformChannelSpecifics, payload: 'data');
  }

  Future selectNotification(String payload) async {
    //Handle notification tapped logic here
  }
}

void showNotification(String title, String body, Color color) {
    PushNotificationMessage notification = PushNotificationMessage(
      title: title,
      body: body,
    );
    showSimpleNotification(
      Text(notification.body),
      position: NotificationPosition.top,
      background: color,
    );
  }
