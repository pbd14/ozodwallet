import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm;

  PushNotificationService(this._fcm);

  Future init() async {
    if (Platform.isIOS) {
      _fcm.requestPermission();
    }
    if (Platform.isAndroid) {
      _fcm.requestPermission();
    }

    // NotificationSettings settings = await _fcm.requestPermission(
    //   alert: true,
    //   announcement: false,
    //   badge: true,
    //   carPlay: false,
    //   criticalAlert: false,
    //   provisional: false,
    //   sound: true,
    // );

    String? token = await _fcm.getToken();
    if (FirebaseAuth.instance.currentUser != null) {
      // if (kIsWeb) {
      //   FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(FirebaseAuth.instance.currentUser?.uid)
      //       .update({
      //     'fcm_token_web': token,
      //   });
      // }
      if (Platform.isAndroid) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'fcm_token_android': token,
          'fcm_token_ios': "",
          'fcm_token_web': "",

        });
      }
      if (Platform.isIOS) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({
          'fcm_token_android': "",
          'fcm_token_ios': token,
          'fcm_token_web': "",
        });
      }
    }
  }
}
