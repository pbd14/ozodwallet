import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ozodwallet/Screens/MainScreen/main_screen.dart';
import 'package:ozodwallet/Screens/WelcomeScreen/welcome_screen.dart';
import 'package:ozodwallet/Services/auth/push_notification_service.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/Widgets/sww_screen.dart';

class AuthService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // handleAuth({PendingDynamicLinkData? linkData = null}) {
  //   return StreamBuilder(
  //       stream: FirebaseAuth.instance.authStateChanges(),
  //       builder: (BuildContext context, snapshot) {
  //         if (snapshot.hasData) {
  //           final pushNotificationService =
  //               PushNotificationService(_firebaseMessaging);
  //           pushNotificationService.init();
  //           return MainScreen(linkData: linkData);
  //         } else {
  //           return WelcomeScreen();
  //         }
  //       });
  // }

  signOut(BuildContext context) {
    dynamic res = FirebaseAuth.instance.signOut().catchError((error) {
      Navigator.push(
          context,
          SlideRightRoute(
              page: SomethingWentWrongScreen(
            error: "Failed to sign out: ${error.message}",
            key: null,
          )));
    });
    return res;
  }

  signIn(PhoneAuthCredential authCredential, BuildContext context) {
    try {
      Future<UserCredential> res =
          FirebaseAuth.instance.signInWithCredential(authCredential);
      //     .catchError((error) {
      //   // Navigator.push(
      //   //     context,
      //   //     SlideRightRoute(
      //   //         page: SomethingWentWrongScreen(
      //   //       error: "Something went wrong: ${error.message}",
      //   //     )));
      //   PushNotificationMessage notification = PushNotificationMessage(
      //     title: 'Fail',
      //     body: 'Wrong code',
      //   );
      //   showSimpleNotification(
      //     Text(notification.body),
      //     position: NotificationPosition.top,
      //     background: Colors.red,
      //   );
      //   // return Future.error(error);
      // });

      // DocumentSnapshot user = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(FirebaseAuth.instance.currentUser?.uid)
      //     .get();
      // if (!user.exists) {
      //   FirebaseFirestore.instance
      //       .collection('users')
      //       .doc(FirebaseAuth.instance.currentUser?.uid)
      //       .set({
      //     'id': FirebaseAuth.instance.currentUser?.uid,
      //     'status': 'default',
      //     'phone': FirebaseAuth.instance.currentUser?.phoneNumber,
      //   });
      // }
      final pushNotificationService =
          PushNotificationService(_firebaseMessaging);
      pushNotificationService.init();
      return res;
    } catch (e) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'status': 'not logged in',
      });
      return null;
    }
  }

  signInWithOTP(smsCode, verId, BuildContext context) {
    try {
      PhoneAuthCredential authCredential = PhoneAuthProvider.credential(
        verificationId: verId,
        smsCode: smsCode,
      );
      dynamic res = signIn(authCredential, context);
      return res;
    } catch (e) {
      return null;
    }
  }

  signUpWithEmail(email, password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email.';
      }
    } catch (e) {
      return 'Failed to sign up.';
    }
  }

  signInWithEmail(email, password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
    }
  }
}
