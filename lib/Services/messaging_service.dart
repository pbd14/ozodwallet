// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:ozod/Models/PushNotificationMessage.dart';
// import 'package:ozod/constants.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:overlay_support/overlay_support.dart';

// class MessagingService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

//   String? _token;
//   String? get token => _token;

//   Future init() async {
//     if (!kIsWeb) {
//       final settings = await _requestPermission();

//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         await _getToken();
//         _registerForegroundMessageHandler();
//       }
//     }
//   }

//   Future _getToken() async {
//     _token = await _firebaseMessaging.getToken();

//     print("FCM: $_token");

//     _firebaseMessaging.onTokenRefresh.listen((token) {
//       _token = token;
//     });
//   }

//   Future<NotificationSettings> _requestPermission() async {
//     return await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//         announcement: false);
//   }

//   void _registerForegroundMessageHandler() {
//     FirebaseMessaging.onMessage.listen((remoteMessage) {
//       PushNotificationMessage notification = PushNotificationMessage(
//         title: remoteMessage.notification!.title!,
//         body: remoteMessage.notification!.body!,
//       );
//       showSimpleNotification(
//         Text(notification.body),
//         position: NotificationPosition.top,
//         background: primaryColor,
//       );
//     });
//   }
// }

// Future sendMessage(tokens, String title, String body) async {
//   var func = FirebaseFunctions.instance.httpsCallable("notifySubscribers");
//   var res = await func.call(<String, dynamic>{
//     "targetDevices": tokens,
//     "messageTitle": title,
//     "messageBody": body
//   });

//   print("message was ${res.data as bool ? "sent!" : "not sent!"}");
// }
