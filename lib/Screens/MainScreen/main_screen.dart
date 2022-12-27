import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:native_updater/native_updater.dart';
import 'package:ozod/Models/PushNotificationMessage.dart';
import 'package:ozod/Screens/BattleScreen/battle_screen.dart';
import 'package:ozod/Screens/HomeScreen/components/insturctions_screen.dart';
import 'package:ozod/Screens/HomeScreen/home_screen.dart';
import 'package:ozod/Screens/MainScreen/components/create_profile.dart';
import 'package:ozod/Screens/NetworkScreen/network_screen.dart';
import 'package:ozod/Screens/ProfileScreen/profile_screen.dart';
import 'package:ozod/Services/encryption_service.dart';
import 'package:ozod/Widgets/rounded_button.dart';
import 'package:ozod/Widgets/slide_right_route_animation.dart';
import 'package:ozod/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:overlay_support/overlay_support.dart';
// import 'package:package_info/package_info.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  int tabNum;
  PendingDynamicLinkData? linkData;
  MainScreen({
    Key? key,
    this.tabNum = 0,
    this.linkData,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? country;
  String? state;
  String? city;
  DocumentSnapshot? userProfile;

  DocumentSnapshot? userAuth;
  int? tabNum;
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      NetworkScreen(),
      BattleScreen(),
      ProfileScreen(),
    ];
  }

  void changeTabNumber(int number) {
    _controller.jumpToTab(number);
  }

  void checkUserValidity() async {
    userAuth = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (userAuth!.get('status') == 'blocked') {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              // title: Text(
              //     Languages.of(context).profileScreenSignOut),
              // content: Text(
              //     Languages.of(context)!.profileScreenWantToLeave),
              title: const Text(
                'Blocked',
                style: TextStyle(color: Colors.red),
              ),
              content: const Text('Your account was blocked.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Ok',
                    style: TextStyle(color: darkColor),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    if (FirebaseAuth.instance.currentUser!.email != null) {
      if (FirebaseAuth.instance.currentUser!.email!.isNotEmpty) {
        if (FirebaseAuth.instance.currentUser != null &&
            !FirebaseAuth.instance.currentUser!.emailVerified) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  // title: Text(
                  //     Languages.of(context).profileScreenSignOut),
                  // content: Text(
                  //     Languages.of(context)!.profileScreenWantToLeave),
                  title: const Text(
                    'Verify your email',
                    style: TextStyle(color: Colors.red),
                  ),
                  content: const Text(
                      'Please verify your email. Check if verfication email is in the spam box.'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        bool isError = false;
                        FirebaseAuth.instance.currentUser!
                            .sendEmailVerification()
                            .catchError((error) {
                          print('ERRERF');
                          print(error);
                          isError = true;
                          PushNotificationMessage notification =
                              PushNotificationMessage(
                            title: 'Fail',
                            body: 'Failed to send email',
                          );
                          showSimpleNotification(
                            Text(notification.body),
                            position: NotificationPosition.top,
                            background: Colors.red,
                          );
                        }).whenComplete(() {
                          if (!isError) {
                            PushNotificationMessage notification =
                                PushNotificationMessage(
                              title: 'Success',
                              body: 'Email was sent',
                            );
                            showSimpleNotification(
                              Text(notification.body),
                              position: NotificationPosition.top,
                              background: greenColor,
                            );
                          }
                        });
                      },
                      child: const Text(
                        'Resend email',
                        style: TextStyle(color: darkColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        FirebaseAuth.instance.currentUser?.reload();
                        if (FirebaseAuth.instance.currentUser != null &&
                            FirebaseAuth.instance.currentUser!.emailVerified) {
                          Navigator.of(context).pop(false);
                        }
                      },
                      child: const Text(
                        'Check if Verified',
                        style: TextStyle(color: darkColor),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      }
    }

    // BackgroundFetch.start().then((int status) {
    //   print('[BackgroundFetch] start success: $status');
    // }).catchError((e) {
    //   print('[BackgroundFetch] start FAILURE: $e');
    // });
  }

  Future<void> checkUserProfile() async {
    userAuth = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
    if (!userAuth!.exists) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'id': FirebaseAuth.instance.currentUser?.uid,
        'status': 'default',
        'phone': FirebaseAuth.instance.currentUser?.phoneNumber,
        'email': FirebaseAuth.instance.currentUser?.email,
        'fcm_token_android': "",
        'fcm_token_ios': "",
        'fcm_token_web': "",
        'profile': "",
      }).whenComplete(() {
        checkUserValidity();
      });
      // ignore: use_build_context_synchronously
      Navigator.push(
        context,
        SlideRightRoute(
          page: const CreateProfileScreen(),
        ),
      );
    } else {
      if (userAuth!.get('profile') == null ||
          userAuth!.get('profile').isEmpty) {
        Navigator.push(
          context,
          SlideRightRoute(
            page: const CreateProfileScreen(),
          ),
        );
      } else {
        userProfile = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userAuth!.get('profile'))
            .get();
        if (!userProfile!.exists) {
          Navigator.push(
            context,
            SlideRightRoute(
              page: const CreateProfileScreen(),
            ),
          );
        } else {
          if (userProfile!.get("isNew")) {
            // ignore: use_build_context_synchronously
            Navigator.push(
              context,
              SlideRightRoute(
                page: InstructionsScreen(
                  userProfileId: userAuth!.get('profile'),
                ),
              ),
            );
          }
          checkUserValidity();
        }
      }
    }
  }

  Future<void> checkVersion() async {
    DocumentSnapshot appVersionData =
        await FirebaseFirestore.instance.collection('appData').doc('app').get();
    String requiredVersion = '1.0.2';
    String appStoreLink = 'https://play.google.com/store/apps/details?id=com.ozod';
    if (Platform.isAndroid) {
      requiredVersion = appVersionData.get('google_play_version');
      appStoreLink = appVersionData.get('google_play_link');
    } else if (Platform.isIOS) {
      requiredVersion = appVersionData.get('appstore_version');
      appStoreLink = appVersionData.get('appstore_link');
    }
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // if (packageInfo.version != requiredVersion) {
      // NativeUpdater.displayUpdateAlert(
      //   context,
      //   forceUpdate: true,
      //   appStoreUrl: appStoreLink,
      // );
    // }
  }

  // Future<void> checkSocialMediaUse() async {
  //   userAuth = await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(FirebaseAuth.instance.currentUser!.uid)
  //       .get();
  //   userProfile = await FirebaseFirestore.instance
  //       .collection('profiles')
  //       .doc(userAuth!.get('profile'))
  //       .get();
  //   DocumentSnapshot appDataSocial = await FirebaseFirestore.instance
  //       .collection('appData')
  //       .doc('social')
  //       .get();
  //   try {
  //     DateTime startDate = DateTime.now().subtract(Duration(days: 7));
  //     // DateTime(
  //     //     DateTime.now().year, DateTime.now().month, DateTime.now().day);
  //     DateTime endDate = DateTime.now();
  //     Map<String, int>? socialAppsInfo = {};
  //     bool isPermitted = true;
  //     List<AppUsageInfo> appUsageInfo =
  //         await AppUsage.getAppUsage(startDate, endDate).catchError((error) {
  //       print("ERERERE " + error);
  //       isPermitted = false;
  //     });
  //     if (isPermitted) {
  //       int totalMinutes = 0;
  //       double totalScore = 0;
  //       appUsageInfo.sort(((a, b) => a.usage.compareTo(b.usage)));
  //       for (AppUsageInfo appInfo in appUsageInfo.reversed) {
  //         // print(appInfo.packageName + ": " + appInfo.usage.toString());
  //         if (appDataSocial.get('apps').keys.contains(appInfo.packageName)) {
  //           totalMinutes += appInfo.usage.inMinutes;
  //           socialAppsInfo[appInfo.packageName] = appInfo.usage.inMinutes;
  //         }
  //       }
  //       totalScore = ((10080 - totalMinutes) / 10080) * 100;
  //       FirebaseFirestore.instance
  //           .collection('profiles')
  //           .doc(userAuth!.get('profile'))
  //           .update({
  //         'socialMediaTracking': {
  //           'points': totalScore,
  //           'topApps': socialAppsInfo,
  //           'from': startDate,
  //           'to': endDate,
  //         },
  //       });
  //     }
  //   } catch (exception) {
  //     print("EXCEPTION");
  //     print(exception);
  //     // PushNotificationMessage notification = PushNotificationMessage(
  //     //   title: 'Failed',
  //     //   body: 'Failed to get data',
  //     // );
  //     // showSimpleNotification(
  //     //   Text(notification.body),
  //     //   position: NotificationPosition.top,
  //     //   background: Colors.red,
  //     // );
  //   }
  // }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      if (!kIsWeb)
        PersistentBottomNavBarItem(
          icon: const Icon(CupertinoIcons.map),
          title: ("Home"),
          activeColorPrimary: secondaryColor,
          activeColorSecondary: secondaryColor,
          inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
        ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.square_grid_3x2_fill),
        title: ("Network"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: secondaryColor,
        inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.gamecontroller_fill),
        title: ("Battle"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: secondaryColor,
        inactiveColorPrimary: Colors.red,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.person),
        title: ("Profile"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: secondaryColor,
        inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      ),
    ];
  }

  Future<void> handleLink(PendingDynamicLinkData data) async {
    final Uri uri = data.link;
    if (uri.origin + uri.path == 'https://ozod.page.link/join') {
      final queryParams = uri.queryParameters;
      if (queryParams.length > 0) {
        String encId = queryParams["encID"]!;
        // Navigator.push(
        //   context,
        //   SlideRightRoute(
        //     page: const CreateProfileScreen(),
        //   ),
        // );
        DocumentSnapshot network = await FirebaseFirestore.instance
            .collection('networks')
            .doc(EncryptionService().dec(encId))
            .get();

        changeTabNumber(1);

        if (mounted) {
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, StateSetter setState) {
                  return AlertDialog(
                    backgroundColor: darkPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: const Text(
                      'Join Network',
                      style: TextStyle(color: secondaryColor),
                    ),
                    content: SingleChildScrollView(
                      child: Container(
                        margin: EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue,
                                    Colors.green,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      network.get('name'),
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 23,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      network.get('mode').toUpperCase(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                            color: whiteColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      network.get('id'),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      network.get('members').length.toString(),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      'members',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                            color: whiteColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            RoundedButton(
                              pw: 100,
                              ph: 45,
                              text: 'Join',
                              press: () async {
                                bool limitsPermit = true;
                                String limitsError = '';
                                DocumentSnapshot potentialNetwork =
                                    await FirebaseFirestore.instance
                                        .collection('networks')
                                        .doc(network.id)
                                        .get();
                                DocumentSnapshot profile =
                                    await FirebaseFirestore.instance
                                        .collection('profiles')
                                        .doc(userProfile!.id)
                                        .get();
                                DocumentSnapshot limits =
                                    await FirebaseFirestore.instance
                                        .collection('appData')
                                        .doc("limits")
                                        .get();
                                if (potentialNetwork.exists) {
                                  if (limits.get('network_members') <=
                                      potentialNetwork.get('members').length) {
                                    limitsPermit = false;
                                    limitsError = 'Network is full';
                                  }
                                  if (limits.get('networks') <=
                                      profile.get('networks').length) {
                                    limitsPermit = false;
                                    limitsError =
                                        'You can have only in 5 networks';
                                  }
                                  if (limitsPermit) {
                                    if (!potentialNetwork
                                        .get('members')
                                        .contains(userProfile!.id)) {
                                      FirebaseFirestore.instance
                                          .collection('networks')
                                          .doc(network.id)
                                          .update({
                                        'members': FieldValue.arrayUnion(
                                            [userProfile!.id]),
                                      }).catchError((error) {
                                        PushNotificationMessage notification =
                                            PushNotificationMessage(
                                          title: 'Failed',
                                          body: 'Failed to join network',
                                        );
                                        showSimpleNotification(
                                          Text(notification.body),
                                          position: NotificationPosition.top,
                                          background: Colors.red,
                                        );
                                      });

                                      FirebaseFirestore.instance
                                          .collection('profiles')
                                          .doc(userProfile!.id)
                                          .update({
                                        'networks':
                                            FieldValue.arrayUnion([network.id])
                                      }).catchError((error) {
                                        FirebaseFirestore.instance
                                            .collection('networks')
                                            .doc(network.id)
                                            .update({
                                          'members': FieldValue.arrayRemove(
                                              [userProfile!.id]),
                                        });
                                        PushNotificationMessage notification =
                                            PushNotificationMessage(
                                          title: 'Failed',
                                          body: 'Failed to join network',
                                        );
                                        showSimpleNotification(
                                          Text(notification.body),
                                          position: NotificationPosition.top,
                                          background: Colors.red,
                                        );
                                      });

                                      for (String taskId
                                          in potentialNetwork.get('tasks')) {
                                        DocumentSnapshot member =
                                            await FirebaseFirestore.instance
                                                .collection('profiles')
                                                .doc(userProfile!.id)
                                                .get();
                                        Map activeTasks = member['activeTasks'];
                                        if (activeTasks[potentialNetwork.id] !=
                                            null) {
                                          activeTasks[potentialNetwork.id]
                                              .add(taskId);
                                        } else {
                                          activeTasks[potentialNetwork.id] = [
                                            taskId
                                          ];
                                        }
                                        FirebaseFirestore.instance
                                            .collection('profiles')
                                            .doc(member.id)
                                            .update({
                                          'activeTasks': activeTasks,
                                        }).catchError((error) {
                                          PushNotificationMessage notification =
                                              PushNotificationMessage(
                                            title: 'Failed to join',
                                            body: 'Please rejoin the group',
                                          );
                                          showSimpleNotification(
                                            Text(notification.body),
                                            position: NotificationPosition.top,
                                            background: Colors.red,
                                          );
                                        });
                                      }

                                      PushNotificationMessage notification =
                                          PushNotificationMessage(
                                        title: 'Joined',
                                        body: 'Joined network',
                                      );
                                      showSimpleNotification(
                                        Text(notification.body),
                                        position: NotificationPosition.top,
                                        background: greenColor,
                                      );
                                      Navigator.of(context).pop(false);
                                    } else {
                                      PushNotificationMessage notification =
                                          PushNotificationMessage(
                                        title: 'Already joined',
                                        body: "You already are a member",
                                      );
                                      showSimpleNotification(
                                        Text(notification.body),
                                        position: NotificationPosition.top,
                                        background: Colors.blue,
                                      );
                                    }
                                  } else {
                                    PushNotificationMessage notification =
                                        PushNotificationMessage(
                                      title: 'Failed',
                                      body: limitsError,
                                    );
                                    showSimpleNotification(
                                      Text(notification.body),
                                      position: NotificationPosition.top,
                                      background: Colors.red,
                                    );
                                  }
                                } else {
                                  PushNotificationMessage notification =
                                      PushNotificationMessage(
                                    title: 'Failed',
                                    body: "This network doesn't exists",
                                  );
                                  showSimpleNotification(
                                    Text(notification.body),
                                    position: NotificationPosition.top,
                                    background: Colors.red,
                                  );
                                }
                              },
                              color: secondaryColor,
                              textColor: darkPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }
      }
    }
  }

  Future<void> checkDynamicLinks() async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) handleLink(initialLink);
    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      handleLink(dynamicLinkData);
    }).onError((error) {
      // Handle errors
    });
  }

  @override
  void initState() {
    checkVersion();
    tabNum = widget.tabNum;
    checkUserProfile();
    // checkSocialMediaUse();
    checkDynamicLinks();
    if (widget.linkData != null) {
      handleLink(widget.linkData!);
    }
    if (widget.tabNum != 0) {
      _controller.jumpToTab(widget.tabNum);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: darkPrimaryColor, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset:
          true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows:
          true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(40.0),
        colorBehindNavBar: primaryColor,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties(
        // Navigation Bar's items animation properties.
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation(
        // Screen transition animation on change of selected tab.
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style13,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
    );
  }
}













// import 'dart:async';
// import 'dart:collection';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:overlay_support/overlay_support.dart';
// import 'package:ozod/Models/PushNotificationMessage.dart';
// import 'package:ozod/Screens/NetworkScreen/view_daily_task_screen.dart';
// import 'package:ozod/Screens/NetworkScreen/view_monthly_task_screen.dart';
// import 'package:ozod/Screens/ProfileScreen/view_profile_screen.dart';
// import 'package:ozod/Services/encryption_service.dart';
// import 'package:ozod/Widgets/loading_screen.dart';
// import 'package:ozod/Widgets/rounded_button.dart';
// import 'package:flutter/services.dart';
// import 'package:ozod/Widgets/slide_right_route_animation.dart';
// import 'package:ozod/Widgets/sww_screen.dart';
// import 'package:ozod/constants.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

// // ignore: must_be_immutable
// class NetworkInfoScreen extends StatefulWidget {
//   String error;
//   String networkId;
//   NetworkInfoScreen(
//       {Key? key, this.error = 'Something Went Wrong', required this.networkId})
//       : super(key: key);

//   @override
//   State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
// }

// class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
//   final _formKey = GlobalKey<FormState>();
//   bool loading = true;
//   bool isMember = true;
//   bool isDeleted = false;
//   DocumentSnapshot? userProfile;
//   DocumentSnapshot? userAuth;
//   DocumentSnapshot? network;
//   List<DocumentSnapshot> members = [];
//   List<DocumentSnapshot> tasks = [];
//   Map<String, double> bestMembers = {};
//   Map<String, double> wortsMembers = {};
//   double networkYearPoints = 0;
//   double avgDayPoints = 0;
//   ScrollController _scrollController = ScrollController();
//   // Tutorial
//   late TutorialCoachMark tutorialCoachMark;
//   GlobalKey keyButton1 = GlobalKey();
//   GlobalKey keyButton2 = GlobalKey();
//   GlobalKey keyButton3 = GlobalKey();


//   Future<void> _refresh() {
//     if (isDeleted) {
//       Navigator.of(context).pop();
//     }
//     setState(() {
//       loading = true;
//     });
//     isMember = true;
//     members.clear();
//     tasks.clear();
//     bestMembers.clear();
//     wortsMembers.clear();
//     networkYearPoints = 0;
//     avgDayPoints = 0;
//     prepare();
//     Completer<void> completer = Completer<void>();
//     completer.complete();
//     return completer.future;
//   }

// // Tutorial
// void createTutorial() {
//     tutorialCoachMark = TutorialCoachMark(
//       targets: _createTargets(),
//       colorShadow: secondaryColor,
//       textSkip: "SKIP",
//       paddingFocus: 10,
//       opacityShadow: 0.8,
//       onFinish: () async {
//         SharedPreferences sharedPreference = await SharedPreferences.getInstance();
//         sharedPreference.setBool("isNetworkInfoTutorial", true);
//       },
//       onClickTarget: (target) {
//         print('onClickTarget: $target');
//         if(target.keyTarget == keyButton2){
//           _scrollController.animateTo(
//                         MediaQuery.of(context).size.height * 0.5,
//                         duration: Duration(milliseconds: 500),
//                         curve: Curves.ease);
//         }
//         if(target.keyTarget == keyButton3){
//           _scrollController.animateTo(
//                         MediaQuery.of(context).size.height * 0.5,
//                         duration: Duration(milliseconds: 500),
//                         curve: Curves.ease);
//         }
//       },
//       onClickTargetWithTapPosition: (target, tapDetails) {
//         print("target: $target");
//         print(
//             "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
//       },
//       onClickOverlay: (target) {
//         print('onClickOverlay: $target');
//       },
//       onSkip: () {
//         print("skip");
//       },
//     );
//   }

//   List<TargetFocus> _createTargets() {
//     List<TargetFocus> targets = [];

//     targets.add(
//       TargetFocus(
//         identify: "Target 0",
//         keyTarget: keyButton1,
//         shape: ShapeLightFocus.RRect,
//     radius: 5,
//         contents: [
//           TargetContent(
//             align: ContentAlign.top,
//             builder: (context, controller) {
//               return Container(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: <Widget>[
//                     Text(
//                       "Tasks",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: darkPrimaryColor,
//                           fontSize: 30.0),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20.0),
//                       child: Text(
//                         "You can create tasks for your network, that everyone should complete. For example, you can create a task to earn 300 points everyday",
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 3,
//                         style: TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.w500,fontSize: 15.0),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//     targets.add(
//       TargetFocus(
//         identify: "Target 1",
//         keyTarget: keyButton2,
//         shape: ShapeLightFocus.RRect,
//     radius: 5,
//         contents: [
//           TargetContent(
//             align: ContentAlign.bottom,
//             builder: (context, controller) {
//               return Container(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: <Widget>[
//                     Text(
//                       "Best Members",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: darkPrimaryColor,
//                           fontSize: 30.0),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 50.0),
//                       child: Text(
//                         "Here you will find the best and the worst members",
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 3,
//                         style: TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.w500,fontSize: 15.0),),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//     targets.add(
//       TargetFocus(
//         identify: "Target 3",
//         keyTarget: keyButton3,
//         shape: ShapeLightFocus.RRect,
//     radius: 5,
//         contents: [
//           TargetContent(
//             align: ContentAlign.top,
//             builder: (context, controller) {
//               return Container(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: <Widget>[
//                     Text(
//                       "Info",
//                       style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: darkPrimaryColor,
//                           fontSize: 30.0),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 20.0),
//                       child: Text(
//                         "Here you will find stats of your network, members, and invitations",
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 3,
//                         style: TextStyle(color: darkPrimaryColor, fontWeight: FontWeight.w500,fontSize: 15.0),),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
    
//     return targets;
//   }



//   Future<void> prepare() async {
//     network = await FirebaseFirestore.instance
//         .collection('networks')
//         .doc(widget.networkId)
//         .get();
//     userAuth = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(FirebaseAuth.instance.currentUser!.uid)
//         .get();
//     userProfile = await FirebaseFirestore.instance
//         .collection('profiles')
//         .doc(userAuth!.get('profile'))
//         .get();
//     for (String memberId in network!.get('members')) {
//       members.add(await FirebaseFirestore.instance
//           .collection('profiles')
//           .doc(memberId)
//           .get());
//     }
//     if (!network!.get('members').contains(userProfile!.id)) {
//       if (mounted) {
//         setState(() {
//           isMember = false;
//         });
//       } else {
//         isMember = false;
//       }
//     }
//     for (String taskId in network!.get('tasks')) {
//       tasks.add(await FirebaseFirestore.instance
//           .collection('tasks')
//           .doc(taskId)
//           .get());
//     }
//     getBestMembers();

//     if (this.mounted) {
//       setState(() {
//         loading = false;
//       });
//     } else {
//       loading = false;
//     }
//   }

//   void getBestMembers() {
//     Map results = {};
//     for (DocumentSnapshot member in members) {
//       bool yearExists = true;
//       try {
//         member.get(DateTime.now().year.toString());
//       } catch (e) {
//         yearExists = false;
//       }
//       if (yearExists) {
//         Map yearData = member.get(DateTime.now().year.toString());
//         double yearPoints = 0;
//         yearData.forEach((key, value) {
//           Map monthData = value;
//           monthData.forEach((key, value) {
//             if (mounted) {
//               setState(() {
//                 networkYearPoints += value['score'];
//                 yearPoints += value['score'];
//               });
//             } else {
//               networkYearPoints += value['score'];
//               yearPoints += value['score'];
//             }
//           });
//         });
//         results[member.id] = yearPoints;
//       }

//       if (mounted) {
//         setState(() {
//           avgDayPoints = networkYearPoints /
//               DateTime.now()
//                   .difference(DateTime.fromMillisecondsSinceEpoch(
//                       network!.get('dateCreated').millisecondsSinceEpoch))
//                   .inDays;
//           bestMembers = new SplayTreeMap.from(
//               results, (k2, k1) => results[k1].compareTo(results[k2]));
//           wortsMembers = new SplayTreeMap.from(
//               results, (k1, k2) => results[k1].compareTo(results[k2]));
//         });
//       } else {
//         avgDayPoints = networkYearPoints /
//             DateTime.now()
//                 .difference(DateTime.fromMillisecondsSinceEpoch(
//                     network!.get('dateCreated').millisecondsSinceEpoch))
//                 .inDays;
//         bestMembers = new SplayTreeMap.from(
//             results, (k2, k1) => results[k1].compareTo(results[k2]));
//         wortsMembers = new SplayTreeMap.from(
//             results, (k1, k2) => results[k1].compareTo(results[k2]));
//       }

//       FirebaseFirestore.instance.collection('networks').doc(network!.id).update(
//         {
//           DateTime.now().year.toString(): {
//             'avgDayPoints': avgDayPoints,
//             'totalPoints': networkYearPoints,
//           },
//         },
//       );
//     }
//   }

//   Map getMembersResults({String mode = 'daily'}) {
//     Map results = {};
//     if (mode == 'daily') {
//       for (DocumentSnapshot member in members) {
//         bool yearFieldExists = true;
//         try {
//           member.get(DateTime.now().year.toString());
//         } catch (e) {
//           yearFieldExists = false;
//         }
//         if (yearFieldExists) {
//           if (member.get(DateTime.now().year.toString())[
//                   DateTime.now().month.toString()] !=
//               null) {
//             if (member.get(DateTime.now().year.toString())[DateTime.now()
//                     .month
//                     .toString()][DateTime.now().day.toString()] !=
//                 null) {
//               if (mounted) {
//                 setState(() {
//                   results[member.id] = {
//                     'score': member.get(DateTime.now().year.toString())[
//                             DateTime.now().month.toString()]
//                         [DateTime.now().day.toString()]['score'],
//                     'isCompleted': false,
//                   };
//                 });
//               } else {
//                 results[member.id] = {
//                   'score': member.get(DateTime.now().year.toString())[
//                           DateTime.now().month.toString()]
//                       [DateTime.now().day.toString()]['score'],
//                   'isCompleted': false,
//                 };
//               }
//             } else {
//               results[member.id] = {
//                 'score': 0.0,
//                 'isCompleted': false,
//               };
//             }
//           } else {
//             results[member.id] = {
//               'score': 0.0,
//               'isCompleted': false,
//             };
//           }
//         } else {
//           results[member.id] = {
//             'score': 0.0,
//             'isCompleted': false,
//           };
//         }
//       }
//     } else if (mode == 'monthly') {
//       for (DocumentSnapshot member in members) {
//         bool yearFieldExists = true;
//         try {
//           member.get(DateTime.now().year.toString());
//         } catch (e) {
//           yearFieldExists = false;
//         }
//         if (yearFieldExists) {
//           if (member.get(DateTime.now().year.toString())[
//                   DateTime.now().month.toString()] !=
//               null) {
//             double totalMonthlyScore = 0;
//             member
//                 .get(DateTime.now().year.toString())[
//                     DateTime.now().month.toString()]
//                 .forEach((key, value) {
//               totalMonthlyScore += member.get(DateTime.now().year.toString())[
//                   DateTime.now().month.toString()][key]['score'];
//             });
//             if (mounted) {
//               setState(() {
//                 results[member.id] = {
//                   'score': totalMonthlyScore,
//                   'isCompleted': false,
//                 };
//               });
//             } else {
//               results[member.id] = {
//                 'score': totalMonthlyScore,
//                 'isCompleted': false,
//               };
//             }
//           } else {
//             results[member.id] = {
//               'score': 0.0,
//               'isCompleted': false,
//             };
//           }
//         } else {
//           results[member.id] = {
//             'score': 0.0,
//             'isCompleted': false,
//           };
//         }
//       }
//     }
//     return results;
//   }

//   Map getTasksResults({String mode = 'daily', required taskId}) {
//     Map results = {};
//     bool yearFieldExists = true;
//     if (mode == 'daily') {
//       DocumentSnapshot task = tasks.where((element) {
//         return element.id == taskId;
//       }).toList()[0];
//       try {
//         task.get(DateTime.now().year.toString());
//       } catch (e) {
//         yearFieldExists = false;
//       }
//       if (yearFieldExists) {
//         if (task.get(DateTime.now().year.toString())[
//                 DateTime.now().month.toString()] !=
//             null) {
//           if (task.get(DateTime.now().year.toString())[DateTime.now()
//                   .month
//                   .toString()][DateTime.now().day.toString()] !=
//               null) {
//             Map temporaryMap = task.get(DateTime.now().year.toString())[
//                 DateTime.now().month.toString()][DateTime.now().day.toString()];
//             results = {};
//             temporaryMap.forEach((key, value) {
//               if (mounted) {
//                 setState(() {
//                   results[key] = value;
//                 });
//               } else {
//                 results[key] = value;
//               }
//             });
//           } else {
//             results = {};
//           }
//         } else {
//           results = {};
//         }
//       } else {
//         results = {};
//       }
//     } else if (mode == 'monthly') {
//       bool yearFieldExists = true;
//       DocumentSnapshot task = tasks.where((element) {
//         return element.id == taskId;
//       }).toList()[0];
//       try {
//         task.get(DateTime.now().year.toString());
//       } catch (e) {
//         yearFieldExists = false;
//       }
//       if (yearFieldExists) {
//         if (task.get(DateTime.now().year.toString())[
//                 DateTime.now().month.toString()] !=
//             null) {
//           Map temporaryMap = task.get(
//               DateTime.now().year.toString())[DateTime.now().month.toString()];
//           temporaryMap.forEach((key, value) {
//             if (mounted) {
//               setState(() {
//                 results[key] = value;
//               });
//             } else {
//               results[key] = value;
//             }
//           });
//         } else {
//           results = {};
//         }
//       } else {
//         results = {};
//       }
//     }
//     if (mode == 'daily') {
//       return new SplayTreeMap.from(results,
//           (k2, k1) => results[k1]['score'].compareTo(results[k2]['score']));
//     } else {
//       return new SplayTreeMap.from(results,
//           (k2, k1) => results[k1]['score'].compareTo(results[k2]['score']));
//     }
//   }

//   @override
//   void initState() {
//     prepare();
//     () async {
//       SharedPreferences sharedPreference = await SharedPreferences.getInstance();
//       bool? isTutorial = await sharedPreference.getBool("isNetworkInfoTutorial");

//       if (isTutorial == null) {
//         createTutorial();
//         tutorialCoachMark..show(context: context);
//       } else if (!isTutorial) {
//         createTutorial();
//         tutorialCoachMark..show(context: context);
//       }
//     }();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return loading
//         ? const LoadingScreen()
//         : !isMember
//             ? SomethingWentWrongScreen(
//                 error: "You are not a member",
//               )
//             : Scaffold(
//                 backgroundColor: primaryColor,
//                 appBar: AppBar(
//                   elevation: 0,
//                   automaticallyImplyLeading: true,
//                   toolbarHeight: 30,
//                   backgroundColor: primaryColor,
//                   centerTitle: true,
//                   actions: [],
//                 ),
//                 body: RefreshIndicator(
//                   backgroundColor: darkPrimaryColor,
//                   color: secondaryColor,
//                   onRefresh: _refresh,
//                   child: CustomScrollView(
//                     controller: _scrollController,
//                     slivers: [
//                       SliverList(
//                         delegate: SliverChildListDelegate(
//                           [
//                             Container(
//                               margin: const EdgeInsets.all(20),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const SizedBox(
//                                     height: 30,
//                                   ),
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceBetween,
//                                     children: [
//                                       SizedBox(
//                                         width: size.width * 0.65,
//                                         child: Text(
//                                           network!.id,
//                                           overflow: TextOverflow.ellipsis,
//                                           maxLines: 5,
//                                           style: GoogleFonts.montserrat(
//                                             textStyle: const TextStyle(
//                                               color: secondaryColor,
//                                               fontSize: 27,
//                                               fontWeight: FontWeight.w700,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       Column(
//                                         children: [
//                                           members.length > 1
//                                               ? RoundedButton(
//                                                   pw: 80,
//                                                   ph: 40,
//                                                   text: 'Leave',
//                                                   press: () async {
//                                                     showDialog(
//                                                       barrierDismissible: false,
//                                                       context: context,
//                                                       builder: (BuildContext
//                                                           context) {
//                                                         return StatefulBuilder(
//                                                           builder: (context,
//                                                               StateSetter
//                                                                   setState) {
//                                                             return AlertDialog(
//                                                               backgroundColor:
//                                                                   darkPrimaryColor,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             20.0),
//                                                               ),
//                                                               title: const Text(
//                                                                 'Leave?',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         secondaryColor),
//                                                               ),
//                                                               content:
//                                                                   const Text(
//                                                                 'Are your sure you want to leave this network?',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         secondaryColor),
//                                                               ),
//                                                               actions: <Widget>[
//                                                                 TextButton(
//                                                                   onPressed:
//                                                                       () {
//                                                                     setState(
//                                                                         () {
//                                                                       loading =
//                                                                           true;
//                                                                     });
//                                                                     FirebaseFirestore
//                                                                         .instance
//                                                                         .collection(
//                                                                             'networks')
//                                                                         .doc(network!
//                                                                             .id)
//                                                                         .update({
//                                                                       if (network!
//                                                                           .get(
//                                                                               'admins')
//                                                                           .contains(userProfile!
//                                                                               .id))
//                                                                         'admins':
//                                                                             FieldValue.arrayRemove([
//                                                                           userProfile!
//                                                                               .id
//                                                                         ]),
//                                                                       if (network!
//                                                                           .get(
//                                                                               'admins')
//                                                                           .contains(userProfile!
//                                                                               .id))
//                                                                         'admins':
//                                                                             FieldValue.arrayRemove([
//                                                                           userProfile!
//                                                                               .id
//                                                                         ]),
//                                                                       if (network!.get('admins').contains(userProfile!
//                                                                               .id) &&
//                                                                           network!.get('admins').length <
//                                                                               2)
//                                                                         'admins':
//                                                                             [
//                                                                           members[1]
//                                                                               .id
//                                                                         ],
//                                                                       "members":
//                                                                           FieldValue
//                                                                               .arrayRemove([
//                                                                         userProfile!
//                                                                             .id
//                                                                       ]),
//                                                                     }).catchError(
//                                                                             (error) {
//                                                                       PushNotificationMessage
//                                                                           notification =
//                                                                           PushNotificationMessage(
//                                                                         title:
//                                                                             'Failed',
//                                                                         body:
//                                                                             'Failed to leave network',
//                                                                       );
//                                                                       showSimpleNotification(
//                                                                         Text(notification
//                                                                             .body),
//                                                                         position:
//                                                                             NotificationPosition.top,
//                                                                         background:
//                                                                             Colors.red,
//                                                                       );
//                                                                     });
//                                                                     Map oldTasks =
//                                                                         userProfile!
//                                                                             .get('activeTasks');
//                                                                     oldTasks.remove(
//                                                                         network!
//                                                                             .id);
//                                                                     FirebaseFirestore
//                                                                         .instance
//                                                                         .collection(
//                                                                             'profiles')
//                                                                         .doc(userProfile!
//                                                                             .id)
//                                                                         .update({
//                                                                       "networks":
//                                                                           FieldValue
//                                                                               .arrayRemove([
//                                                                         network!
//                                                                             .id
//                                                                       ]),
//                                                                       'activeTasks':
//                                                                           oldTasks,
//                                                                     }).catchError(
//                                                                             (error) {
//                                                                       PushNotificationMessage
//                                                                           notification =
//                                                                           PushNotificationMessage(
//                                                                         title:
//                                                                             'Failed',
//                                                                         body:
//                                                                             'Failed to leave network',
//                                                                       );
//                                                                       showSimpleNotification(
//                                                                         Text(notification
//                                                                             .body),
//                                                                         position:
//                                                                             NotificationPosition.top,
//                                                                         background:
//                                                                             Colors.red,
//                                                                       );
//                                                                     });
//                                                                     Navigator.of(
//                                                                             context)
//                                                                         .pop(
//                                                                             true);
//                                                                     isDeleted =
//                                                                         true;
//                                                                     _refresh();
//                                                                   },
//                                                                   child:
//                                                                       const Text(
//                                                                     'Yes',
//                                                                     style: TextStyle(
//                                                                         color:
//                                                                             secondaryColor),
//                                                                   ),
//                                                                 ),
//                                                                 TextButton(
//                                                                   onPressed: () =>
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop(
//                                                                               false),
//                                                                   child:
//                                                                       const Text(
//                                                                     'No',
//                                                                     style: TextStyle(
//                                                                         color: Colors
//                                                                             .red),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             );
//                                                           },
//                                                         );
//                                                       },
//                                                     );
//                                                   },
//                                                   color: Colors.orange,
//                                                   textColor: whiteColor,
//                                                 )
//                                               : RoundedButton(
//                                                   pw: 80,
//                                                   ph: 45,
//                                                   text: 'Delete',
//                                                   press: () async {
//                                                     showDialog(
//                                                       barrierDismissible: false,
//                                                       context: context,
//                                                       builder: (BuildContext
//                                                           context) {
//                                                         return StatefulBuilder(
//                                                           builder: (context,
//                                                               StateSetter
//                                                                   setState) {
//                                                             return AlertDialog(
//                                                               backgroundColor:
//                                                                   darkPrimaryColor,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             20.0),
//                                                               ),
//                                                               title: const Text(
//                                                                 'Delete?',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         secondaryColor),
//                                                               ),
//                                                               content:
//                                                                   const Text(
//                                                                 'Are your sure you want to delete this network?',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         secondaryColor),
//                                                               ),
//                                                               actions: <Widget>[
//                                                                 TextButton(
//                                                                   onPressed:
//                                                                       () async {
//                                                                     setState(
//                                                                         () {
//                                                                       loading =
//                                                                           true;
//                                                                     });
//                                                                     Map oldTasks =
//                                                                         userProfile!
//                                                                             .get('activeTasks');
//                                                                     oldTasks.remove(
//                                                                         network!
//                                                                             .id);
//                                                                     FirebaseFirestore
//                                                                         .instance
//                                                                         .collection(
//                                                                             'profiles')
//                                                                         .doc(userProfile!
//                                                                             .id)
//                                                                         .update({
//                                                                       "networks":
//                                                                           FieldValue
//                                                                               .arrayRemove([
//                                                                         network!
//                                                                             .id
//                                                                       ]),
//                                                                       'activeTasks':
//                                                                           oldTasks,
//                                                                     }).catchError(
//                                                                             (error) {
//                                                                       PushNotificationMessage
//                                                                           notification =
//                                                                           PushNotificationMessage(
//                                                                         title:
//                                                                             'Failed',
//                                                                         body:
//                                                                             'Failed to delete network',
//                                                                       );
//                                                                       showSimpleNotification(
//                                                                         Text(notification
//                                                                             .body),
//                                                                         position:
//                                                                             NotificationPosition.top,
//                                                                         background:
//                                                                             Colors.red,
//                                                                       );
//                                                                     });
//                                                                     DocumentSnapshot updatedNetwork = await FirebaseFirestore
//                                                                         .instance
//                                                                         .collection(
//                                                                             'networks')
//                                                                         .doc(network!
//                                                                             .id)
//                                                                         .get();
//                                                                     for (String taskId
//                                                                         in updatedNetwork
//                                                                             .get('tasks')) {
//                                                                       FirebaseFirestore
//                                                                           .instance
//                                                                           .collection(
//                                                                               'tasks')
//                                                                           .doc(
//                                                                               taskId)
//                                                                           .delete();
//                                                                     }
//                                                                     FirebaseFirestore
//                                                                         .instance
//                                                                         .collection(
//                                                                             'networks')
//                                                                         .doc(network!
//                                                                             .id)
//                                                                         .delete();
//                                                                     Navigator.of(
//                                                                             context)
//                                                                         .pop(
//                                                                             true);
//                                                                     isDeleted =
//                                                                         true;
//                                                                     _refresh();
//                                                                   },
//                                                                   child:
//                                                                       const Text(
//                                                                     'Yes',
//                                                                     style: TextStyle(
//                                                                         color:
//                                                                             secondaryColor),
//                                                                   ),
//                                                                 ),
//                                                                 TextButton(
//                                                                   onPressed: () =>
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop(
//                                                                               false),
//                                                                   child:
//                                                                       const Text(
//                                                                     'No',
//                                                                     style: TextStyle(
//                                                                         color: Colors
//                                                                             .red),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             );
//                                                           },
//                                                         );
//                                                       },
//                                                     );
//                                                   },
//                                                   color: Colors.red,
//                                                   textColor: whiteColor,
//                                                 ),
//                                           SizedBox(
//                                             height: 10,
//                                           ),
//                                           RoundedButton(
//                                             pw: 80,
//                                             ph: 45,
//                                             text: 'Invite',
//                                             press: () async {
//                                               EncryptionService encService =
//                                                   EncryptionService();
//                                               String encryptedId =
//                                                   encService.enc(network!.id);
//                                               String encId =
//                                                   Uri.encodeComponent(
//                                                       encryptedId);
//                                               final dynamicLinkParams =
//                                                   DynamicLinkParameters(
//                                                 link: Uri.parse(
//                                                     'https://ozod.page.link/join?encID=$encId'),
//                                                 uriPrefix:
//                                                     "https://ozod.page.link",
//                                                 androidParameters:
//                                                     const AndroidParameters(
//                                                         packageName:
//                                                             "com.ozod"),
//                                                 iosParameters:
//                                                     const IOSParameters(
//                                                         bundleId: "com.ozod"),
//                                               );

//                                               ShortDynamicLink link =
//                                                   await FirebaseDynamicLinks
//                                                       .instance
//                                                       .buildShortLink(
//                                                           dynamicLinkParams);
//                                               Uri dynamicLink = link.shortUrl;

//                                               showDialog(
//                                                   barrierDismissible: false,
//                                                   context: context,
//                                                   builder:
//                                                       (BuildContext context) {
//                                                     return StatefulBuilder(
//                                                       builder: (context,
//                                                           StateSetter
//                                                               setState) {
//                                                         return AlertDialog(
//                                                           backgroundColor:
//                                                               darkPrimaryColor,
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         20.0),
//                                                           ),
//                                                           title: const Text(
//                                                             'Invite',
//                                                             style: TextStyle(
//                                                                 color:
//                                                                     secondaryColor),
//                                                           ),
//                                                           content:
//                                                               SingleChildScrollView(
//                                                             child: Container(
//                                                               margin: EdgeInsets
//                                                                   .all(10),
//                                                               child: Column(
//                                                                 children: [
//                                                                   Container(
//                                                                     padding:
//                                                                         const EdgeInsets.all(
//                                                                             20),
//                                                                     decoration:
//                                                                         BoxDecoration(
//                                                                       borderRadius:
//                                                                           BorderRadius.circular(
//                                                                               20.0),
//                                                                       gradient:
//                                                                           const LinearGradient(
//                                                                         begin: Alignment
//                                                                             .topLeft,
//                                                                         end: Alignment
//                                                                             .bottomRight,
//                                                                         colors: [
//                                                                           darkPrimaryColor,
//                                                                           primaryColor
//                                                                         ],
//                                                                       ),
//                                                                     ),
//                                                                     child:
//                                                                         QrImage(
//                                                                       data: dynamicLink
//                                                                           .toString(),
//                                                                       foregroundColor:
//                                                                           secondaryColor,
//                                                                     ),
//                                                                   ),
//                                                                   SizedBox(
//                                                                     height: 10,
//                                                                   ),
//                                                                   Text(
//                                                                     dynamicLink
//                                                                         .toString(),
//                                                                     overflow:
//                                                                         TextOverflow
//                                                                             .ellipsis,
//                                                                     maxLines:
//                                                                         10,
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .center,
//                                                                     style: GoogleFonts
//                                                                         .montserrat(
//                                                                       textStyle:
//                                                                           const TextStyle(
//                                                                         color:
//                                                                             whiteColor,
//                                                                         fontSize:
//                                                                             10,
//                                                                         fontWeight:
//                                                                             FontWeight.w500,
//                                                                       ),
//                                                                     ),
//                                                                   ),
//                                                                   SizedBox(
//                                                                     height: 20,
//                                                                   ),
//                                                                   RoundedButton(
//                                                                     pw: 100,
//                                                                     ph: 45,
//                                                                     text:
//                                                                         'Share',
//                                                                     press:
//                                                                         () async {
//                                                                       Share.share(
//                                                                           dynamicLink
//                                                                               .toString());
//                                                                     },
//                                                                     color: Colors
//                                                                         .blue,
//                                                                     textColor:
//                                                                         whiteColor,
//                                                                   ),
//                                                                   SizedBox(
//                                                                     height: 20,
//                                                                   ),
//                                                                   RoundedButton(
//                                                                     pw: 100,
//                                                                     ph: 45,
//                                                                     text:
//                                                                         'Copy',
//                                                                     press:
//                                                                         () async {
//                                                                       await Clipboard.setData(
//                                                                           ClipboardData(
//                                                                               text: dynamicLink.toString()));
//                                                                       PushNotificationMessage
//                                                                           notification =
//                                                                           PushNotificationMessage(
//                                                                         title:
//                                                                             'Copied',
//                                                                         body:
//                                                                             'Link copied',
//                                                                       );
//                                                                       showSimpleNotification(
//                                                                         Text(notification
//                                                                             .body),
//                                                                         position:
//                                                                             NotificationPosition.top,
//                                                                         background:
//                                                                             greenColor,
//                                                                       );
//                                                                     },
//                                                                     color:
//                                                                         secondaryColor,
//                                                                     textColor:
//                                                                         darkPrimaryColor,
//                                                                   ),
//                                                                 ],
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           actions: <Widget>[
//                                                             TextButton(
//                                                               onPressed: () =>
//                                                                   Navigator.of(
//                                                                           context)
//                                                                       .pop(
//                                                                           false),
//                                                               child: const Text(
//                                                                 'Ok',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         secondaryColor),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         );
//                                                       },
//                                                     );
//                                                   });
//                                             },
//                                             color: secondaryColor,
//                                             textColor: darkPrimaryColor,
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(
//                                     height: 30,
//                                   ),

//                                   // Tasks
//                                   Row(
//                                     key: keyButton1,
//                                     mainAxisAlignment: MainAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Tasks',
//                                         overflow: TextOverflow.ellipsis,
//                                         style: GoogleFonts.montserrat(
//                                           textStyle: const TextStyle(
//                                             color: secondaryColor,
//                                             fontSize: 25,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         width: 10,
//                                       ),
//                                       network!.get('tasks').isNotEmpty
//                                           ? network!
//                                                   .get('admins')
//                                                   .contains(userProfile!.id)
//                                               ? IconButton(
//                                                   icon:
//                                                       Icon(CupertinoIcons.plus),
//                                                   color: secondaryColor,
//                                                   onPressed: () async {
//                                                     String taskName = "first";
//                                                     String taskMode = "daily";
//                                                     String taskPointsNeeded =
//                                                         "240";
//                                                     showDialog(
//                                                       barrierDismissible: true,
//                                                       context: context,
//                                                       builder: (BuildContext
//                                                           context) {
//                                                         return StatefulBuilder(
//                                                             builder: (context,
//                                                                 StateSetter
//                                                                     setState) {
//                                                           return AlertDialog(
//                                                             backgroundColor:
//                                                                 darkPrimaryColor,
//                                                             shape:
//                                                                 RoundedRectangleBorder(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           20.0),
//                                                             ),
//                                                             // title: Text(
//                                                             //     Languages.of(context).profileScreenSignOut),
//                                                             // content: Text(
//                                                             //     Languages.of(context)!.profileScreenWantToLeave),
//                                                             title: const Text(
//                                                               'Create a task',
//                                                               style: TextStyle(
//                                                                   color:
//                                                                       whiteColor),
//                                                             ),
//                                                             content:
//                                                                 SingleChildScrollView(
//                                                               child: Form(
//                                                                 key: _formKey,
//                                                                 child: Column(
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .start,
//                                                                   children: [
//                                                                     Text(
//                                                                       "Name",
//                                                                       overflow:
//                                                                           TextOverflow
//                                                                               .ellipsis,
//                                                                       style: GoogleFonts
//                                                                           .montserrat(
//                                                                         textStyle:
//                                                                             const TextStyle(
//                                                                           color:
//                                                                               whiteColor,
//                                                                           fontSize:
//                                                                               25,
//                                                                           fontWeight:
//                                                                               FontWeight.w500,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           20,
//                                                                     ),
//                                                                     Container(
//                                                                       // width: size.width * 0.3,
//                                                                       child:
//                                                                           TextFormField(
//                                                                         style: const TextStyle(
//                                                                             color:
//                                                                                 secondaryColor),
//                                                                         validator:
//                                                                             (val) {
//                                                                           return val!.isEmpty
//                                                                               ? 'Enter task name'
//                                                                               : null;
//                                                                         },
//                                                                         inputFormatters: [
//                                                                           FilteringTextInputFormatter.allow(
//                                                                               RegExp(r"[a-zA-z0-9]+|\s")),
//                                                                         ],
//                                                                         keyboardType:
//                                                                             TextInputType.text,
//                                                                         onChanged:
//                                                                             (val) {
//                                                                           setState(
//                                                                               () {
//                                                                             taskName =
//                                                                                 val;
//                                                                           });
//                                                                         },
//                                                                         decoration:
//                                                                             InputDecoration(
//                                                                           errorBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: Colors.red, width: 1.0),
//                                                                           ),
//                                                                           focusedBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: secondaryColor, width: 1.0),
//                                                                           ),
//                                                                           enabledBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: secondaryColor, width: 1.0),
//                                                                           ),
//                                                                           hintStyle:
//                                                                               TextStyle(color: secondaryColor.withOpacity(0.7)),
//                                                                           hintText:
//                                                                               'Name',
//                                                                           border:
//                                                                               InputBorder.none,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           40,
//                                                                     ),
//                                                                     Text(
//                                                                       "Type",
//                                                                       overflow:
//                                                                           TextOverflow
//                                                                               .ellipsis,
//                                                                       style: GoogleFonts
//                                                                           .montserrat(
//                                                                         textStyle:
//                                                                             const TextStyle(
//                                                                           color:
//                                                                               whiteColor,
//                                                                           fontSize:
//                                                                               25,
//                                                                           fontWeight:
//                                                                               FontWeight.w500,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           20,
//                                                                     ),
//                                                                     DropdownButton<
//                                                                         String>(
//                                                                       iconSize:
//                                                                           30,
//                                                                       value:
//                                                                           taskMode,
//                                                                       hint:
//                                                                           const Text(
//                                                                         "Every day",
//                                                                         style:
//                                                                             TextStyle(
//                                                                           color:
//                                                                               secondaryColor,
//                                                                         ),
//                                                                       ),
//                                                                       onChanged:
//                                                                           (String?
//                                                                               mode) {
//                                                                         setState(
//                                                                             () {
//                                                                           taskMode =
//                                                                               mode!;
//                                                                         });
//                                                                       },
//                                                                       items: const [
//                                                                         DropdownMenuItem(
//                                                                           value:
//                                                                               "daily",
//                                                                           child:
//                                                                               Text(
//                                                                             "Every day",
//                                                                             style:
//                                                                                 TextStyle(fontSize: 20, color: secondaryColor),
//                                                                           ),
//                                                                         ),
//                                                                         DropdownMenuItem(
//                                                                           value:
//                                                                               "monthly",
//                                                                           child:
//                                                                               Text(
//                                                                             "Every month",
//                                                                             style:
//                                                                                 TextStyle(fontSize: 20, color: secondaryColor),
//                                                                           ),
//                                                                         ),
//                                                                       ],
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           40,
//                                                                     ),
//                                                                     Text(
//                                                                       "Points needed (20 points = 1 hour)",
//                                                                       overflow:
//                                                                           TextOverflow
//                                                                               .ellipsis,
//                                                                       style: GoogleFonts
//                                                                           .montserrat(
//                                                                         textStyle:
//                                                                             const TextStyle(
//                                                                           color:
//                                                                               whiteColor,
//                                                                           fontSize:
//                                                                               25,
//                                                                           fontWeight:
//                                                                               FontWeight.w500,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           20,
//                                                                     ),
//                                                                     Container(
//                                                                       // width: size.width * 0.3,
//                                                                       child:
//                                                                           TextFormField(
//                                                                         style: const TextStyle(
//                                                                             color:
//                                                                                 secondaryColor),
//                                                                         validator:
//                                                                             (val) {
//                                                                           if (taskMode ==
//                                                                               'daily') {
//                                                                             return int.parse(val!) > 480 || int.parse(val) < 0
//                                                                                 ? 'Should be between 0 and 480'
//                                                                                 : null;
//                                                                           } else if (taskMode ==
//                                                                               'monthly') {
//                                                                             return int.parse(val!) > 14880 || int.parse(val) < 0
//                                                                                 ? 'Should be between 0 and 14880'
//                                                                                 : null;
//                                                                           }
//                                                                           return val!.isEmpty
//                                                                               ? 'Enter how many points needed'
//                                                                               : null;
//                                                                         },
//                                                                         keyboardType:
//                                                                             TextInputType.number,
//                                                                         onChanged:
//                                                                             (val) {
//                                                                           setState(
//                                                                               () {
//                                                                             taskPointsNeeded =
//                                                                                 val;
//                                                                           });
//                                                                         },
//                                                                         decoration:
//                                                                             InputDecoration(
//                                                                           errorBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: Colors.red, width: 1.0),
//                                                                           ),
//                                                                           focusedBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: secondaryColor, width: 1.0),
//                                                                           ),
//                                                                           enabledBorder:
//                                                                               const OutlineInputBorder(
//                                                                             borderSide:
//                                                                                 BorderSide(color: secondaryColor, width: 1.0),
//                                                                           ),
//                                                                           hintStyle:
//                                                                               TextStyle(color: secondaryColor.withOpacity(0.7)),
//                                                                           hintText:
//                                                                               'Points needed',
//                                                                           border:
//                                                                               InputBorder.none,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       height:
//                                                                           20,
//                                                                     ),
//                                                                     RoundedButton(
//                                                                       pw: 250,
//                                                                       ph: 45,
//                                                                       text:
//                                                                           'Create',
//                                                                       press:
//                                                                           () async {
//                                                                         if (_formKey
//                                                                             .currentState!
//                                                                             .validate()) {
//                                                                           setState(
//                                                                               () {
//                                                                             loading =
//                                                                                 true;
//                                                                           });
//                                                                           // Limits
//                                                                           bool
//                                                                               limitsPermit =
//                                                                               true;
//                                                                           String
//                                                                               limitsError =
//                                                                               '';
//                                                                           DocumentSnapshot potentialNetwork = await FirebaseFirestore
//                                                                               .instance
//                                                                               .collection('networks')
//                                                                               .doc(network!.id)
//                                                                               .get();
//                                                                           DocumentSnapshot limits = await FirebaseFirestore
//                                                                               .instance
//                                                                               .collection('appData')
//                                                                               .doc("limits")
//                                                                               .get();
//                                                                           if (limits.get('tasks_per_net') <=
//                                                                               potentialNetwork.get('tasks').length) {
//                                                                             limitsPermit =
//                                                                                 false;
//                                                                             limitsError =
//                                                                                 'You can have only 5 tasks';
//                                                                           }
//                                                                           if (limitsPermit) {
//                                                                             // Task
//                                                                             String
//                                                                                 id =
//                                                                                 DateTime.now().millisecondsSinceEpoch.toString();
//                                                                             taskMode == 'daily'
//                                                                                 ?
//                                                                                 // DAILY
//                                                                                 FirebaseFirestore.instance.collection('tasks').doc(id).set({
//                                                                                     'id': id,
//                                                                                     'name': taskName,
//                                                                                     'mode': taskMode,
//                                                                                     'pointsNeeded': taskPointsNeeded,
//                                                                                     'dateCreated': DateTime.now(),
//                                                                                     DateTime.now().year.toString(): {
//                                                                                       DateTime.now().month.toString(): {
//                                                                                         DateTime.now().day.toString(): getMembersResults()
//                                                                                       }
//                                                                                     },
//                                                                                   }).catchError((error) {
//                                                                                     PushNotificationMessage notification = PushNotificationMessage(
//                                                                                       title: 'Failed',
//                                                                                       body: 'Failed to create task',
//                                                                                     );
//                                                                                     showSimpleNotification(
//                                                                                       Text(notification.body),
//                                                                                       position: NotificationPosition.top,
//                                                                                       background: Colors.red,
//                                                                                     );
//                                                                                   })
//                                                                                 :
//                                                                                 // MONTHLY
//                                                                                 FirebaseFirestore.instance.collection('tasks').doc(id).set({
//                                                                                     'id': id,
//                                                                                     'name': taskName,
//                                                                                     'mode': taskMode,
//                                                                                     'pointsNeeded': taskPointsNeeded,
//                                                                                     'dateCreated': DateTime.now(),
//                                                                                     DateTime.now().year.toString(): {
//                                                                                       DateTime.now().month.toString(): getMembersResults(mode: 'monthly')
//                                                                                     },
//                                                                                   }).catchError((error) {
//                                                                                     PushNotificationMessage notification = PushNotificationMessage(
//                                                                                       title: 'Failed',
//                                                                                       body: 'Failed to create task',
//                                                                                     );
//                                                                                     showSimpleNotification(
//                                                                                       Text(notification.body),
//                                                                                       position: NotificationPosition.top,
//                                                                                       background: Colors.red,
//                                                                                     );
//                                                                                   });

//                                                                             // Network
//                                                                             FirebaseFirestore.instance.collection('networks').doc(network!.id).update({
//                                                                               'tasks': FieldValue.arrayUnion([
//                                                                                 id
//                                                                               ])
//                                                                             }).catchError((error) {
//                                                                               PushNotificationMessage notification = PushNotificationMessage(
//                                                                                 title: 'Failed',
//                                                                                 body: 'Failed to create task',
//                                                                               );
//                                                                               showSimpleNotification(
//                                                                                 Text(notification.body),
//                                                                                 position: NotificationPosition.top,
//                                                                                 background: Colors.red,
//                                                                               );
//                                                                             });

//                                                                             // Members
//                                                                             DocumentSnapshot
//                                                                                 updatedNetwork =
//                                                                                 await FirebaseFirestore.instance.collection('networks').doc(network!.id).get();
//                                                                             for (String memberId
//                                                                                 in updatedNetwork.get('members')) {
//                                                                               DocumentSnapshot member = await FirebaseFirestore.instance.collection('profiles').doc(memberId).get();
//                                                                               Map activeTasks = member['activeTasks'];
//                                                                               if (activeTasks[network!.id] != null) {
//                                                                                 activeTasks[network!.id].add(id);
//                                                                               } else {
//                                                                                 activeTasks[network!.id] = [
//                                                                                   id
//                                                                                 ];
//                                                                               }
//                                                                               FirebaseFirestore.instance.collection('profiles').doc(member.id).update({
//                                                                                 'activeTasks': activeTasks,
//                                                                               }).catchError((error) {
//                                                                                 PushNotificationMessage notification = PushNotificationMessage(
//                                                                                   title: 'Failed',
//                                                                                   body: 'Failed to create task',
//                                                                                 );
//                                                                                 showSimpleNotification(
//                                                                                   Text(notification.body),
//                                                                                   position: NotificationPosition.top,
//                                                                                   background: Colors.red,
//                                                                                 );
//                                                                               });
//                                                                             }
//                                                                           } else {
//                                                                             PushNotificationMessage
//                                                                                 notification =
//                                                                                 PushNotificationMessage(
//                                                                               title: 'Failed',
//                                                                               body: limitsError,
//                                                                             );
//                                                                             showSimpleNotification(
//                                                                               Text(notification.body),
//                                                                               position: NotificationPosition.top,
//                                                                               background: Colors.red,
//                                                                             );
//                                                                           }
//                                                                           Navigator.of(context)
//                                                                               .pop(false);
//                                                                           _refresh();
//                                                                         }
//                                                                       },
//                                                                       color:
//                                                                           secondaryColor,
//                                                                       textColor:
//                                                                           darkPrimaryColor,
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                             actions: <Widget>[
//                                                               TextButton(
//                                                                 onPressed: () =>
//                                                                     Navigator.of(
//                                                                             context)
//                                                                         .pop(
//                                                                             false),
//                                                                 child:
//                                                                     const Text(
//                                                                   'Cancel',
//                                                                   style: TextStyle(
//                                                                       color:
//                                                                           darkColor),
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           );
//                                                         });
//                                                       },
//                                                     );
//                                                   },
//                                                 )
//                                               : Container()
//                                           : Container(),
//                                     ],
//                                   ),
//                                   const SizedBox(
//                                     height: 20,
//                                   ),
//                                   network!.get('tasks').isEmpty
//                                       ? Column(
//                                           children: [
//                                             const SizedBox(
//                                               height: 30,
//                                             ),
//                                             Center(
//                                               child: Image.asset(
//                                                 'assets/images/net2.png',
//                                                 height: 200,
//                                                 width: 200,
//                                               ),
//                                             ),
//                                             Text(
//                                               "You don't have any tasks fot this group. Add some, so that every member will be in shape",
//                                               overflow: TextOverflow.ellipsis,
//                                               maxLines: 10,
//                                               style: GoogleFonts.montserrat(
//                                                 textStyle: const TextStyle(
//                                                   color: secondaryColor,
//                                                   fontSize: 25,
//                                                   fontWeight: FontWeight.w700,
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(
//                                               height: 20,
//                                             ),
//                                             network!
//                                                     .get('admins')
//                                                     .contains(userProfile!.id)
//                                                 ? RoundedButton(
//                                                     pw: 250,
//                                                     ph: 45,
//                                                     text: 'Create Task',
//                                                     press: () async {
//                                                       String taskName = "first";
//                                                       String taskMode = "daily";
//                                                       String taskPointsNeeded =
//                                                           "240";
//                                                       showDialog(
//                                                         barrierDismissible:
//                                                             true,
//                                                         context: context,
//                                                         builder: (BuildContext
//                                                             context) {
//                                                           return StatefulBuilder(
//                                                               builder: (context,
//                                                                   StateSetter
//                                                                       setState) {
//                                                             return AlertDialog(
//                                                               backgroundColor:
//                                                                   darkPrimaryColor,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             20.0),
//                                                               ),
//                                                               // title: Text(
//                                                               //     Languages.of(context).profileScreenSignOut),
//                                                               // content: Text(
//                                                               //     Languages.of(context)!.profileScreenWantToLeave),
//                                                               title: const Text(
//                                                                 'Create a task',
//                                                                 style: TextStyle(
//                                                                     color:
//                                                                         whiteColor),
//                                                               ),
//                                                               content:
//                                                                   SingleChildScrollView(
//                                                                 child: Form(
//                                                                   key: _formKey,
//                                                                   child: Column(
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .start,
//                                                                     children: [
//                                                                       Text(
//                                                                         "Name",
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle:
//                                                                               const TextStyle(
//                                                                             color:
//                                                                                 whiteColor,
//                                                                             fontSize:
//                                                                                 25,
//                                                                             fontWeight:
//                                                                                 FontWeight.w500,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       Container(
//                                                                         // width: size.width * 0.3,
//                                                                         child:
//                                                                             TextFormField(
//                                                                           style:
//                                                                               const TextStyle(color: secondaryColor),
//                                                                           validator:
//                                                                               (val) {
//                                                                             return val!.isEmpty
//                                                                                 ? 'Enter task name'
//                                                                                 : null;
//                                                                           },
//                                                                           inputFormatters: [
//                                                                             FilteringTextInputFormatter.allow(RegExp(r"[a-zA-z0-9]+|\s")),
//                                                                           ],
//                                                                           keyboardType:
//                                                                               TextInputType.text,
//                                                                           onChanged:
//                                                                               (val) {
//                                                                             setState(() {
//                                                                               taskName = val;
//                                                                             });
//                                                                           },
//                                                                           decoration:
//                                                                               InputDecoration(
//                                                                             errorBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: Colors.red, width: 1.0),
//                                                                             ),
//                                                                             focusedBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: secondaryColor, width: 1.0),
//                                                                             ),
//                                                                             enabledBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: secondaryColor, width: 1.0),
//                                                                             ),
//                                                                             hintStyle:
//                                                                                 TextStyle(color: secondaryColor.withOpacity(0.7)),
//                                                                             hintText:
//                                                                                 'Name',
//                                                                             border:
//                                                                                 InputBorder.none,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             40,
//                                                                       ),
//                                                                       Text(
//                                                                         "Type",
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle:
//                                                                               const TextStyle(
//                                                                             color:
//                                                                                 whiteColor,
//                                                                             fontSize:
//                                                                                 25,
//                                                                             fontWeight:
//                                                                                 FontWeight.w500,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       DropdownButton<
//                                                                           String>(
//                                                                         iconSize:
//                                                                             30,
//                                                                         value:
//                                                                             taskMode,
//                                                                         hint:
//                                                                             const Text(
//                                                                           "Every day",
//                                                                           style:
//                                                                               TextStyle(
//                                                                             color:
//                                                                                 secondaryColor,
//                                                                           ),
//                                                                         ),
//                                                                         onChanged:
//                                                                             (String?
//                                                                                 mode) {
//                                                                           setState(
//                                                                               () {
//                                                                             taskMode =
//                                                                                 mode!;
//                                                                           });
//                                                                         },
//                                                                         items: const [
//                                                                           DropdownMenuItem(
//                                                                             value:
//                                                                                 "daily",
//                                                                             child:
//                                                                                 Text(
//                                                                               "Every day",
//                                                                               style: TextStyle(fontSize: 20, color: secondaryColor),
//                                                                             ),
//                                                                           ),
//                                                                           DropdownMenuItem(
//                                                                             value:
//                                                                                 "monthly",
//                                                                             child:
//                                                                                 Text(
//                                                                               "Every month",
//                                                                               style: TextStyle(fontSize: 20, color: secondaryColor),
//                                                                             ),
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             40,
//                                                                       ),
//                                                                       Text(
//                                                                         "Points needed (20 points = 1 hour)",
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle:
//                                                                               const TextStyle(
//                                                                             color:
//                                                                                 whiteColor,
//                                                                             fontSize:
//                                                                                 25,
//                                                                             fontWeight:
//                                                                                 FontWeight.w500,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       Container(
//                                                                         // width: size.width * 0.3,
//                                                                         child:
//                                                                             TextFormField(
//                                                                           style:
//                                                                               const TextStyle(color: secondaryColor),
//                                                                           validator:
//                                                                               (val) {
//                                                                             if (taskMode ==
//                                                                                 'daily') {
//                                                                               return int.parse(val!) > 480 || int.parse(val) < 0 ? 'Should be between 0 and 480' : null;
//                                                                             } else if (taskMode ==
//                                                                                 'monthly') {
//                                                                               return int.parse(val!) > 14880 || int.parse(val) < 0 ? 'Should be between 0 and 14880' : null;
//                                                                             }
//                                                                             return val!.isEmpty
//                                                                                 ? 'Enter how many points needed'
//                                                                                 : null;
//                                                                           },
//                                                                           keyboardType:
//                                                                               TextInputType.number,
//                                                                           onChanged:
//                                                                               (val) {
//                                                                             setState(() {
//                                                                               taskPointsNeeded = val;
//                                                                             });
//                                                                           },
//                                                                           decoration:
//                                                                               InputDecoration(
//                                                                             errorBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: Colors.red, width: 1.0),
//                                                                             ),
//                                                                             focusedBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: secondaryColor, width: 1.0),
//                                                                             ),
//                                                                             enabledBorder:
//                                                                                 const OutlineInputBorder(
//                                                                               borderSide: BorderSide(color: secondaryColor, width: 1.0),
//                                                                             ),
//                                                                             hintStyle:
//                                                                                 TextStyle(color: secondaryColor.withOpacity(0.7)),
//                                                                             hintText:
//                                                                                 'Points needed',
//                                                                             border:
//                                                                                 InputBorder.none,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             20,
//                                                                       ),
//                                                                       RoundedButton(
//                                                                         pw: 250,
//                                                                         ph: 45,
//                                                                         text:
//                                                                             'Create',
//                                                                         press:
//                                                                             () async {
//                                                                           if (_formKey
//                                                                               .currentState!
//                                                                               .validate()) {
//                                                                             setState(() {
//                                                                               loading = true;
//                                                                             });
//                                                                             // Limits
//                                                                             bool
//                                                                                 limitsPermit =
//                                                                                 true;
//                                                                             String
//                                                                                 limitsError =
//                                                                                 '';
//                                                                             DocumentSnapshot
//                                                                                 limits =
//                                                                                 await FirebaseFirestore.instance.collection('appData').doc("limits").get();
//                                                                             DocumentSnapshot
//                                                                                 potentialNetwork =
//                                                                                 await FirebaseFirestore.instance.collection('networks').doc(network!.id).get();
//                                                                             if (limits.get('tasks_per_net') <=
//                                                                                 potentialNetwork.get('tasks').length) {
//                                                                               limitsPermit = false;
//                                                                               limitsError = 'You can have only 5 tasks';
//                                                                             }
//                                                                             if (limitsPermit) {
//                                                                               // Task
//                                                                               String id = DateTime.now().millisecondsSinceEpoch.toString();
//                                                                               taskMode == 'daily'
//                                                                                   ?
//                                                                                   // DAILY
//                                                                                   FirebaseFirestore.instance.collection('tasks').doc(id).set({
//                                                                                       'id': id,
//                                                                                       'name': taskName,
//                                                                                       'mode': taskMode,
//                                                                                       'pointsNeeded': taskPointsNeeded,
//                                                                                       'dateCreated': DateTime.now(),
//                                                                                       DateTime.now().year.toString(): {
//                                                                                         DateTime.now().month.toString(): {
//                                                                                           DateTime.now().day.toString(): getMembersResults()
//                                                                                         }
//                                                                                       },
//                                                                                     }).catchError((error) {
//                                                                                       PushNotificationMessage notification = PushNotificationMessage(
//                                                                                         title: 'Failed',
//                                                                                         body: 'Failed to create task',
//                                                                                       );
//                                                                                       showSimpleNotification(
//                                                                                         Text(notification.body),
//                                                                                         position: NotificationPosition.top,
//                                                                                         background: Colors.red,
//                                                                                       );
//                                                                                     })
//                                                                                   :
//                                                                                   // MONTHLY
//                                                                                   FirebaseFirestore.instance.collection('tasks').doc(id).set({
//                                                                                       'id': id,
//                                                                                       'name': taskName,
//                                                                                       'mode': taskMode,
//                                                                                       'pointsNeeded': taskPointsNeeded,
//                                                                                       'dateCreated': DateTime.now(),
//                                                                                       DateTime.now().year.toString(): {
//                                                                                         DateTime.now().month.toString(): getMembersResults(mode: 'monthly')
//                                                                                       },
//                                                                                     }).catchError((error) {
//                                                                                       PushNotificationMessage notification = PushNotificationMessage(
//                                                                                         title: 'Failed',
//                                                                                         body: 'Failed to create task',
//                                                                                       );
//                                                                                       showSimpleNotification(
//                                                                                         Text(notification.body),
//                                                                                         position: NotificationPosition.top,
//                                                                                         background: Colors.red,
//                                                                                       );
//                                                                                     });

//                                                                               // Network
//                                                                               FirebaseFirestore.instance.collection('networks').doc(network!.id).update({
//                                                                                 'tasks': FieldValue.arrayUnion([
//                                                                                   id
//                                                                                 ])
//                                                                               }).catchError((error) {
//                                                                                 PushNotificationMessage notification = PushNotificationMessage(
//                                                                                   title: 'Failed',
//                                                                                   body: 'Failed to create task',
//                                                                                 );
//                                                                                 showSimpleNotification(
//                                                                                   Text(notification.body),
//                                                                                   position: NotificationPosition.top,
//                                                                                   background: Colors.red,
//                                                                                 );
//                                                                               });

//                                                                               // Members
//                                                                               DocumentSnapshot updatedNetwork = await FirebaseFirestore.instance.collection('networks').doc(network!.id).get();
//                                                                               for (String memberId in updatedNetwork.get('members')) {
//                                                                                 DocumentSnapshot member = await FirebaseFirestore.instance.collection('profiles').doc(memberId).get();
//                                                                                 Map activeTasks = member['activeTasks'];
//                                                                                 if (activeTasks[network!.id] != null) {
//                                                                                   activeTasks[network!.id].add(id);
//                                                                                   print(activeTasks[network!.id]);
//                                                                                 } else {
//                                                                                   print("HERER2");
//                                                                                   print(activeTasks[network!.id]);
//                                                                                   activeTasks[network!.id] = [id];
//                                                                                 }
//                                                                                 FirebaseFirestore.instance.collection('profiles').doc(member.id).update({
//                                                                                   'activeTasks': activeTasks,
//                                                                                 }).catchError((error) {
//                                                                                   PushNotificationMessage notification = PushNotificationMessage(
//                                                                                     title: 'Failed',
//                                                                                     body: 'Failed to create task',
//                                                                                   );
//                                                                                   showSimpleNotification(
//                                                                                     Text(notification.body),
//                                                                                     position: NotificationPosition.top,
//                                                                                     background: Colors.red,
//                                                                                   );
//                                                                                 });
//                                                                               }
//                                                                             } else {
//                                                                               PushNotificationMessage notification = PushNotificationMessage(
//                                                                                 title: 'Failed',
//                                                                                 body: limitsError,
//                                                                               );
//                                                                               showSimpleNotification(
//                                                                                 Text(notification.body),
//                                                                                 position: NotificationPosition.top,
//                                                                                 background: Colors.red,
//                                                                               );
//                                                                             }
//                                                                             Navigator.of(context).pop(false);
//                                                                             _refresh();
//                                                                           }
//                                                                         },
//                                                                         color:
//                                                                             secondaryColor,
//                                                                         textColor:
//                                                                             darkPrimaryColor,
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                               actions: <Widget>[
//                                                                 TextButton(
//                                                                   onPressed: () =>
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop(
//                                                                               false),
//                                                                   child:
//                                                                       const Text(
//                                                                     'Cancel',
//                                                                     style: TextStyle(
//                                                                         color:
//                                                                             darkColor),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             );
//                                                           });
//                                                         },
//                                                       );
//                                                     },
//                                                     color: darkPrimaryColor,
//                                                     textColor: secondaryColor,
//                                                   )
//                                                 : Container(),
//                                             const SizedBox(
//                                               height: 100,
//                                             ),
//                                           ],
//                                         )
//                                       : Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             for (DocumentSnapshot task in tasks)
//                                               task.get('mode') == 'daily'
//                                                   // Daily
//                                                   ? CupertinoButton(
//                                                       padding: EdgeInsets.zero,
//                                                       onPressed: () {
//                                                         Navigator.push(
//                                                           context,
//                                                           SlideRightRoute(
//                                                             page:
//                                                                 ViewDailyTaskScreen(
//                                                               networkId:
//                                                                   network!.id,
//                                                               taskId: task.id,
//                                                             ),
//                                                           ),
//                                                         );
//                                                       },
//                                                       child: Container(
//                                                         margin: const EdgeInsets
//                                                             .only(bottom: 20),
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .all(20),
//                                                         decoration:
//                                                             BoxDecoration(
//                                                           borderRadius:
//                                                               BorderRadius
//                                                                   .circular(
//                                                                       20.0),
//                                                           gradient:
//                                                               const LinearGradient(
//                                                             begin: Alignment
//                                                                 .topLeft,
//                                                             end: Alignment
//                                                                 .bottomRight,
//                                                             colors: [
//                                                               Color.fromRGBO(0,
//                                                                   146, 69, 1.0),
//                                                               Color.fromRGBO(
//                                                                   252,
//                                                                   238,
//                                                                   33,
//                                                                   1.0),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                         child: Column(
//                                                           children: [
//                                                             Row(
//                                                               mainAxisAlignment:
//                                                                   MainAxisAlignment
//                                                                       .spaceAround,
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .start,
//                                                               children: [
//                                                                 SizedBox(
//                                                                   width:
//                                                                       size.width *
//                                                                           0.3,
//                                                                   child: Column(
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .start,
//                                                                     children: [
//                                                                       Text(
//                                                                         task.get(
//                                                                             'name'),
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle:
//                                                                               const TextStyle(
//                                                                             color:
//                                                                                 whiteColor,
//                                                                             fontSize:
//                                                                                 23,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             5,
//                                                                       ),
//                                                                       Text(
//                                                                         task
//                                                                             .get('mode')
//                                                                             .toUpperCase(),
//                                                                         maxLines:
//                                                                             2,
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle: const TextStyle(
//                                                                               color: whiteColor,
//                                                                               fontSize: 15,
//                                                                               fontWeight: FontWeight.w400),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             10,
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                                 const SizedBox(
//                                                                   width: 10,
//                                                                 ),
//                                                                 SizedBox(
//                                                                   width:
//                                                                       size.width *
//                                                                           0.2,
//                                                                   child: Column(
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .start,
//                                                                     children: [
//                                                                       Text(
//                                                                         task
//                                                                             .get('pointsNeeded')
//                                                                             .toString(),
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         maxLines:
//                                                                             2,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle:
//                                                                               const TextStyle(
//                                                                             color:
//                                                                                 whiteColor,
//                                                                             fontSize:
//                                                                                 30,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             5,
//                                                                       ),
//                                                                       Text(
//                                                                         'points needed',
//                                                                         overflow:
//                                                                             TextOverflow.ellipsis,
//                                                                         maxLines:
//                                                                             2,
//                                                                         style: GoogleFonts
//                                                                             .montserrat(
//                                                                           textStyle: const TextStyle(
//                                                                               color: whiteColor,
//                                                                               fontSize: 10,
//                                                                               fontWeight: FontWeight.w400),
//                                                                         ),
//                                                                       ),
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                                 network!
//                                                                         .get(
//                                                                             'admins')
//                                                                         .contains(
//                                                                             userProfile!.id)
//                                                                     ? SizedBox(
//                                                                         width:
//                                                                             20,
//                                                                         child:
//                                                                             IconButton(
//                                                                           icon:
//                                                                               Icon(CupertinoIcons.trash),
//                                                                           color:
//                                                                               Colors.red,
//                                                                           onPressed:
//                                                                               () async {
//                                                                             showDialog(
//                                                                               barrierDismissible: false,
//                                                                               context: context,
//                                                                               builder: (BuildContext context) {
//                                                                                 return StatefulBuilder(
//                                                                                   builder: (context, StateSetter setState) {
//                                                                                     return AlertDialog(
//                                                                                       backgroundColor: darkPrimaryColor,
//                                                                                       shape: RoundedRectangleBorder(
//                                                                                         borderRadius: BorderRadius.circular(20.0),
//                                                                                       ),
//                                                                                       title: const Text(
//                                                                                         'Delete?',
//                                                                                         style: TextStyle(color: secondaryColor),
//                                                                                       ),
//                                                                                       content: const Text(
//                                                                                         'Are your sure you want to delete this task?',
//                                                                                         style: TextStyle(color: secondaryColor),
//                                                                                       ),
//                                                                                       actions: <Widget>[
//                                                                                         TextButton(
//                                                                                           onPressed: () async {
//                                                                                             setState(() {
//                                                                                               loading = true;
//                                                                                             });
//                                                                                             DocumentSnapshot updatedNetwork = await FirebaseFirestore.instance.collection('networks').doc(network!.id).get();
//                                                                                             for (String profileId in updatedNetwork.get('members')) {
//                                                                                               FirebaseFirestore.instance.collection('profiles').doc(profileId).update({
//                                                                                                 'activeTasks.${updatedNetwork.id}': FieldValue.arrayRemove([task.id]),
//                                                                                               }).catchError((error) {
//                                                                                                 PushNotificationMessage notification = PushNotificationMessage(
//                                                                                                   title: 'Failed',
//                                                                                                   body: 'Failed to delete task',
//                                                                                                 );
//                                                                                                 showSimpleNotification(
//                                                                                                   Text(notification.body),
//                                                                                                   position: NotificationPosition.top,
//                                                                                                   background: Colors.red,
//                                                                                                 );
//                                                                                               });
//                                                                                             }
//                                                                                             FirebaseFirestore.instance.collection('networks').doc(updatedNetwork.id).update({
//                                                                                               'tasks': FieldValue.arrayRemove([task.id]),
//                                                                                             }).catchError((error) {
//                                                                                               PushNotificationMessage notification = PushNotificationMessage(
//                                                                                                 title: 'Failed',
//                                                                                                 body: 'Failed to delete task',
//                                                                                               );
//                                                                                               showSimpleNotification(
//                                                                                                 Text(notification.body),
//                                                                                                 position: NotificationPosition.top,
//                                                                                                 background: Colors.red,
//                                                                                               );
//                                                                                             });

//                                                                                             FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
//                                                                                             Navigator.of(context).pop(true);
//                                                                                             _refresh();
//                                                                                           },
//                                                                                           child: const Text(
//                                                                                             'Yes',
//                                                                                             style: TextStyle(color: secondaryColor),
//                                                                                           ),
//                                                                                         ),
//                                                                                         TextButton(
//                                                                                           onPressed: () => Navigator.of(context).pop(false),
//                                                                                           child: const Text(
//                                                                                             'No',
//                                                                                             style: TextStyle(color: Colors.red),
//                                                                                           ),
//                                                                                         ),
//                                                                                       ],
//                                                                                     );
//                                                                                   },
//                                                                                 );
//                                                                               },
//                                                                             );
//                                                                           },
//                                                                         ),
//                                                                       )
//                                                                     : Container(),
//                                                               ],
//                                                             ),
//                                                             const SizedBox(
//                                                               height: 30,
//                                                             ),
//                                                             for (var resultId
//                                                                 in getTasksResults(
//                                                                         taskId: task
//                                                                             .id)
//                                                                     .keys
//                                                                     .take(5))
//                                                               if (members
//                                                                   .where((element) =>
//                                                                       element
//                                                                           .id ==
//                                                                       resultId)
//                                                                   .toList()
//                                                                   .isNotEmpty)
//                                                                 CupertinoButton(
//                                                                   padding:
//                                                                       EdgeInsets
//                                                                           .zero,
//                                                                   onPressed:
//                                                                       () {
//                                                                     setState(
//                                                                         () {
//                                                                       loading =
//                                                                           true;
//                                                                     });
//                                                                     Navigator
//                                                                         .push(
//                                                                       context,
//                                                                       SlideRightRoute(
//                                                                         page:
//                                                                             ViewProfileScreen(
//                                                                           profileId:
//                                                                               resultId,
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                     setState(
//                                                                         () {
//                                                                       loading =
//                                                                           false;
//                                                                     });
//                                                                   },
//                                                                   child:
//                                                                       Container(
//                                                                     margin: EdgeInsets.only(
//                                                                         bottom:
//                                                                             20),
//                                                                     child: Row(
//                                                                       mainAxisAlignment:
//                                                                           MainAxisAlignment
//                                                                               .start,
//                                                                       children: [
//                                                                         ClipRRect(
//                                                                           borderRadius:
//                                                                               BorderRadius.circular(10000),
//                                                                           child:
//                                                                               CachedNetworkImage(
//                                                                             fit:
//                                                                                 BoxFit.cover,
//                                                                             filterQuality:
//                                                                                 FilterQuality.none,
//                                                                             height:
//                                                                                 30,
//                                                                             width:
//                                                                                 30,
//                                                                             placeholder: (context, url) =>
//                                                                                 SizedBox(
//                                                                               height: 50,
//                                                                               width: 50,
//                                                                               child: Transform.scale(
//                                                                                 scale: 0.3,
//                                                                                 child: const CircularProgressIndicator(
//                                                                                   strokeWidth: 3.0,
//                                                                                   backgroundColor: secondaryColor,
//                                                                                   valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                                                                                 ),
//                                                                               ),
//                                                                             ),
//                                                                             errorWidget: (context, url, error) =>
//                                                                                 const Icon(
//                                                                               Icons.error,
//                                                                               color: primaryColor,
//                                                                             ),
//                                                                             imageUrl:
//                                                                                 members.where((element) => element.id == resultId).toList()[0].get("photo"),
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                           width:
//                                                                               10,
//                                                                         ),
//                                                                         SizedBox(
//                                                                           width:
//                                                                               size.width * 0.3,
//                                                                           child:
//                                                                               Column(
//                                                                             crossAxisAlignment:
//                                                                                 CrossAxisAlignment.start,
//                                                                             children: [
//                                                                               Text(
//                                                                                 members.where((element) => element.id == resultId).toList()[0].get('id'),
//                                                                                 style: GoogleFonts.montserrat(
//                                                                                   textStyle: const TextStyle(
//                                                                                     color: whiteColor,
//                                                                                     fontSize: 15,
//                                                                                     fontWeight: FontWeight.w700,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                               const SizedBox(
//                                                                                 width: 25,
//                                                                               ),
//                                                                               Text(
//                                                                                 members.where((element) => element.id == resultId).toList()[0].get('name') + " " + members.where((element) => element.id == resultId).toList()[0].get('surname'),
//                                                                                 style: GoogleFonts.montserrat(
//                                                                                   textStyle: const TextStyle(
//                                                                                     color: whiteColor,
//                                                                                     fontSize: 10,
//                                                                                     fontWeight: FontWeight.w400,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             ],
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                           width:
//                                                                               20,
//                                                                         ),
//                                                                         SizedBox(
//                                                                           width:
//                                                                               size.width * 0.15,
//                                                                           child:
//                                                                               Text(
//                                                                             getTasksResults(taskId: task.id)[resultId]['score'].toStringAsFixed(1),
//                                                                             maxLines:
//                                                                                 2,
//                                                                             style:
//                                                                                 GoogleFonts.montserrat(
//                                                                               textStyle: const TextStyle(
//                                                                                 color: whiteColor,
//                                                                                 fontSize: 20,
//                                                                                 fontWeight: FontWeight.w700,
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                           width:
//                                                                               20,
//                                                                         ),
//                                                                         if (getTasksResults(
//                                                                             taskId:
//                                                                                 task.id)[resultId]['isCompleted'])
//                                                                           SizedBox(
//                                                                             width:
//                                                                                 size.width * 0.05,
//                                                                             child:
//                                                                                 Icon(
//                                                                               CupertinoIcons.checkmark_square_fill,
//                                                                               color: darkPrimaryColor,
//                                                                             ),
//                                                                           )
//                                                                       ],
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                     )
//                                                   : task.get('mode') ==
//                                                           'monthly'
//                                                       ?
//                                                       // MONTHLY
//                                                       CupertinoButton(
//                                                           padding:
//                                                               EdgeInsets.zero,
//                                                           onPressed: () {
//                                                             Navigator.push(
//                                                               context,
//                                                               SlideRightRoute(
//                                                                 page:
//                                                                     ViewMonthlyTaskScreen(
//                                                                   networkId:
//                                                                       network!
//                                                                           .id,
//                                                                   taskId:
//                                                                       task.id,
//                                                                 ),
//                                                               ),
//                                                             );
//                                                           },
//                                                           child: Container(
//                                                             margin:
//                                                                 const EdgeInsets
//                                                                         .only(
//                                                                     bottom: 20),
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                     .all(20),
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           20.0),
//                                                               gradient:
//                                                                   const LinearGradient(
//                                                                 begin: Alignment
//                                                                     .topLeft,
//                                                                 end: Alignment
//                                                                     .bottomRight,
//                                                                 colors: [
//                                                                   Color
//                                                                       .fromRGBO(
//                                                                           46,
//                                                                           49,
//                                                                           146,
//                                                                           1.0),
//                                                                   Color
//                                                                       .fromRGBO(
//                                                                           27,
//                                                                           255,
//                                                                           255,
//                                                                           1.0),
//                                                                 ],
//                                                               ),
//                                                             ),
//                                                             child: Column(
//                                                               children: [
//                                                                 Row(
//                                                                   mainAxisAlignment:
//                                                                       MainAxisAlignment
//                                                                           .spaceAround,
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .start,
//                                                                   children: [
//                                                                     SizedBox(
//                                                                       width: size
//                                                                               .width *
//                                                                           0.3,
//                                                                       child:
//                                                                           Column(
//                                                                         crossAxisAlignment:
//                                                                             CrossAxisAlignment.start,
//                                                                         children: [
//                                                                           Text(
//                                                                             task.get('name'),
//                                                                             overflow:
//                                                                                 TextOverflow.ellipsis,
//                                                                             style:
//                                                                                 GoogleFonts.montserrat(
//                                                                               textStyle: const TextStyle(
//                                                                                 color: whiteColor,
//                                                                                 fontSize: 23,
//                                                                                 fontWeight: FontWeight.bold,
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                           const SizedBox(
//                                                                             height:
//                                                                                 5,
//                                                                           ),
//                                                                           Text(
//                                                                             task.get('mode').toUpperCase(),
//                                                                             maxLines:
//                                                                                 2,
//                                                                             overflow:
//                                                                                 TextOverflow.ellipsis,
//                                                                             style:
//                                                                                 GoogleFonts.montserrat(
//                                                                               textStyle: const TextStyle(color: whiteColor, fontSize: 15, fontWeight: FontWeight.w400),
//                                                                             ),
//                                                                           ),
//                                                                           const SizedBox(
//                                                                             height:
//                                                                                 10,
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 10,
//                                                                     ),
//                                                                     SizedBox(
//                                                                       width: size
//                                                                               .width *
//                                                                           0.2,
//                                                                       child:
//                                                                           Column(
//                                                                         crossAxisAlignment:
//                                                                             CrossAxisAlignment.start,
//                                                                         children: [
//                                                                           Text(
//                                                                             task.get('pointsNeeded').toString(),
//                                                                             overflow:
//                                                                                 TextOverflow.ellipsis,
//                                                                             maxLines:
//                                                                                 2,
//                                                                             style:
//                                                                                 GoogleFonts.montserrat(
//                                                                               textStyle: const TextStyle(
//                                                                                 color: whiteColor,
//                                                                                 fontSize: 30,
//                                                                                 fontWeight: FontWeight.bold,
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                           const SizedBox(
//                                                                             height:
//                                                                                 5,
//                                                                           ),
//                                                                           Text(
//                                                                             'points needed',
//                                                                             overflow:
//                                                                                 TextOverflow.ellipsis,
//                                                                             maxLines:
//                                                                                 2,
//                                                                             style:
//                                                                                 GoogleFonts.montserrat(
//                                                                               textStyle: const TextStyle(color: whiteColor, fontSize: 10, fontWeight: FontWeight.w400),
//                                                                             ),
//                                                                           ),
//                                                                         ],
//                                                                       ),
//                                                                     ),
//                                                                     network!
//                                                                             .get('admins')
//                                                                             .contains(userProfile!.id)
//                                                                         ? SizedBox(
//                                                                             width:
//                                                                                 20,
//                                                                             child:
//                                                                                 IconButton(
//                                                                               icon: Icon(CupertinoIcons.trash),
//                                                                               color: Colors.red,
//                                                                               onPressed: () async {
//                                                                                 showDialog(
//                                                                                   barrierDismissible: false,
//                                                                                   context: context,
//                                                                                   builder: (BuildContext context) {
//                                                                                     return StatefulBuilder(
//                                                                                       builder: (context, StateSetter setState) {
//                                                                                         return AlertDialog(
//                                                                                           backgroundColor: darkPrimaryColor,
//                                                                                           shape: RoundedRectangleBorder(
//                                                                                             borderRadius: BorderRadius.circular(20.0),
//                                                                                           ),
//                                                                                           title: const Text(
//                                                                                             'Delete?',
//                                                                                             style: TextStyle(color: secondaryColor),
//                                                                                           ),
//                                                                                           content: const Text(
//                                                                                             'Are your sure you want to delete this task?',
//                                                                                             style: TextStyle(color: secondaryColor),
//                                                                                           ),
//                                                                                           actions: <Widget>[
//                                                                                             TextButton(
//                                                                                               onPressed: () async {
//                                                                                                 setState(() {
//                                                                                                   loading = true;
//                                                                                                 });
//                                                                                                 DocumentSnapshot updatedNetwork = await FirebaseFirestore.instance.collection('networks').doc(network!.id).get();
//                                                                                                 for (String profileId in updatedNetwork.get('members')) {
//                                                                                                   FirebaseFirestore.instance.collection('profiles').doc(profileId).update({
//                                                                                                     'activeTasks.${updatedNetwork.id}': FieldValue.arrayRemove([task.id]),
//                                                                                                   }).catchError((error) {
//                                                                                                     PushNotificationMessage notification = PushNotificationMessage(
//                                                                                                       title: 'Failed',
//                                                                                                       body: 'Failed to delete task',
//                                                                                                     );
//                                                                                                     showSimpleNotification(
//                                                                                                       Text(notification.body),
//                                                                                                       position: NotificationPosition.top,
//                                                                                                       background: Colors.red,
//                                                                                                     );
//                                                                                                   });
//                                                                                                 }
//                                                                                                 FirebaseFirestore.instance.collection('networks').doc(updatedNetwork.id).update({
//                                                                                                   'tasks': FieldValue.arrayRemove([task.id]),
//                                                                                                 }).catchError((error) {
//                                                                                                   PushNotificationMessage notification = PushNotificationMessage(
//                                                                                                     title: 'Failed',
//                                                                                                     body: 'Failed to delete task',
//                                                                                                   );
//                                                                                                   showSimpleNotification(
//                                                                                                     Text(notification.body),
//                                                                                                     position: NotificationPosition.top,
//                                                                                                     background: Colors.red,
//                                                                                                   );
//                                                                                                 });

//                                                                                                 FirebaseFirestore.instance.collection('tasks').doc(task.id).delete();
//                                                                                                 Navigator.of(context).pop(true);
//                                                                                                 _refresh();
//                                                                                               },
//                                                                                               child: const Text(
//                                                                                                 'Yes',
//                                                                                                 style: TextStyle(color: primaryColor),
//                                                                                               ),
//                                                                                             ),
//                                                                                             TextButton(
//                                                                                               onPressed: () => Navigator.of(context).pop(false),
//                                                                                               child: const Text(
//                                                                                                 'No',
//                                                                                                 style: TextStyle(color: Colors.red),
//                                                                                               ),
//                                                                                             ),
//                                                                                           ],
//                                                                                         );
//                                                                                       },
//                                                                                     );
//                                                                                   },
//                                                                                 );
//                                                                               },
//                                                                             ),
//                                                                           )
//                                                                         : Container(),
//                                                                   ],
//                                                                 ),
//                                                                 const SizedBox(
//                                                                   height: 30,
//                                                                 ),
//                                                                 for (var resultId in getTasksResults(
//                                                                         mode:
//                                                                             'monthly',
//                                                                         taskId: task
//                                                                             .id)
//                                                                     .keys
//                                                                     .take(5))
//                                                                   if (members
//                                                                       .where((element) =>
//                                                                           element
//                                                                               .id ==
//                                                                           resultId)
//                                                                       .toList()
//                                                                       .isNotEmpty)
//                                                                     CupertinoButton(
//                                                                       padding:
//                                                                           EdgeInsets
//                                                                               .zero,
//                                                                       onPressed:
//                                                                           () {
//                                                                         setState(
//                                                                             () {
//                                                                           loading =
//                                                                               true;
//                                                                         });
//                                                                         Navigator
//                                                                             .push(
//                                                                           context,
//                                                                           SlideRightRoute(
//                                                                             page:
//                                                                                 ViewProfileScreen(
//                                                                               profileId: resultId,
//                                                                             ),
//                                                                           ),
//                                                                         );
//                                                                         setState(
//                                                                             () {
//                                                                           loading =
//                                                                               false;
//                                                                         });
//                                                                       },
//                                                                       child:
//                                                                           Container(
//                                                                         margin: EdgeInsets.only(
//                                                                             bottom:
//                                                                                 20),
//                                                                         child:
//                                                                             Row(
//                                                                           mainAxisAlignment:
//                                                                               MainAxisAlignment.start,
//                                                                           children: [
//                                                                             ClipRRect(
//                                                                               borderRadius: BorderRadius.circular(10000),
//                                                                               child: CachedNetworkImage(
//                                                                                 fit: BoxFit.cover,
//                                                                                 filterQuality: FilterQuality.none,
//                                                                                 height: 30,
//                                                                                 width: 30,
//                                                                                 placeholder: (context, url) => SizedBox(
//                                                                                   height: 50,
//                                                                                   width: 50,
//                                                                                   child: Transform.scale(
//                                                                                     scale: 0.3,
//                                                                                     child: const CircularProgressIndicator(
//                                                                                       strokeWidth: 3.0,
//                                                                                       backgroundColor: secondaryColor,
//                                                                                       valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
//                                                                                     ),
//                                                                                   ),
//                                                                                 ),
//                                                                                 errorWidget: (context, url, error) => const Icon(
//                                                                                   Icons.error,
//                                                                                   color: primaryColor,
//                                                                                 ),
//                                                                                 imageUrl: members.where((element) => element.id == resultId).toList()[0].get("photo"),
//                                                                               ),
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 10,
//                                                                             ),
//                                                                             SizedBox(
//                                                                               width: size.width * 0.3,
//                                                                               child: Column(
//                                                                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                                                                 children: [
//                                                                                   Text(
//                                                                                     members.where((element) => element.id == resultId).toList()[0].get('id'),
//                                                                                     style: GoogleFonts.montserrat(
//                                                                                       textStyle: const TextStyle(
//                                                                                         color: whiteColor,
//                                                                                         fontSize: 15,
//                                                                                         fontWeight: FontWeight.w700,
//                                                                                       ),
//                                                                                     ),
//                                                                                   ),
//                                                                                   const SizedBox(
//                                                                                     width: 25,
//                                                                                   ),
//                                                                                   Text(
//                                                                                     members.where((element) => element.id == resultId).toList()[0].get('name') + " " + members.where((element) => element.id == resultId).toList()[0].get('surname'),
//                                                                                     style: GoogleFonts.montserrat(
//                                                                                       textStyle: const TextStyle(
//                                                                                         color: whiteColor,
//                                                                                         fontSize: 10,
//                                                                                         fontWeight: FontWeight.w400,
//                                                                                       ),
//                                                                                     ),
//                                                                                   ),
//                                                                                 ],
//                                                                               ),
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 20,
//                                                                             ),
//                                                                             SizedBox(
//                                                                               width: size.width * 0.15,
//                                                                               child: Text(
//                                                                                 getTasksResults(mode: 'monthly', taskId: task.id)[resultId]['score'].toStringAsFixed(1),
//                                                                                 maxLines: 2,
//                                                                                 style: GoogleFonts.montserrat(
//                                                                                   textStyle: const TextStyle(
//                                                                                     color: whiteColor,
//                                                                                     fontSize: 20,
//                                                                                     fontWeight: FontWeight.w700,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 20,
//                                                                             ),
//                                                                             if (getTasksResults(
//                                                                                 mode: 'monthly',
//                                                                                 taskId: task.id)[resultId]['isCompleted'])
//                                                                               SizedBox(
//                                                                                 width: size.width * 0.05,
//                                                                                 child: Icon(
//                                                                                   CupertinoIcons.checkmark_square_fill,
//                                                                                   color: darkPrimaryColor,
//                                                                                 ),
//                                                                               )
//                                                                           ],
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         )
//                                                       : Container(),
//                                           ],
//                                         ),
//                                   const SizedBox(
//                                     height: 30,
//                                   ),

//                                   // Best members
//                                   const SizedBox(
//                                     height: 30,
//                                   ),
//                                   Container(
//                                     key: keyButton2,
//                                     margin: const EdgeInsets.only(bottom: 20),
//                                     padding: const EdgeInsets.all(10),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20.0),
//                                       gradient: const LinearGradient(
//                                         begin: Alignment.topCenter,
//                                         end: Alignment.bottomCenter,
//                                         colors: [
//                                           // Colors.white,
//                                           Color.fromARGB(255, 220, 225, 234),
//                                           Color.fromRGBO(134, 147, 171, 1.0),
//                                           Color.fromARGB(255, 57, 66, 83),
//                                           // Colors.black
//                                         ],
//                                       ),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           'Top 3',
//                                           overflow: TextOverflow.ellipsis,
//                                           style: GoogleFonts.montserrat(
//                                             textStyle: const TextStyle(
//                                               color: darkColor,
//                                               fontSize: 23,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                           height: 30,
//                                         ),
//                                         for (var resultId
//                                             in bestMembers.keys.take(3))
//                                           if (members
//                                               .where((element) =>
//                                                   element.id == resultId)
//                                               .toList()
//                                               .isNotEmpty)
//                                             CupertinoButton(
//                                               padding: EdgeInsets.zero,
//                                               onPressed: () {
//                                                 setState(() {
//                                                   loading = true;
//                                                 });
//                                                 Navigator.push(
//                                                   context,
//                                                   SlideRightRoute(
//                                                     page: ViewProfileScreen(
//                                                       profileId: resultId,
//                                                     ),
//                                                   ),
//                                                 );
//                                                 setState(() {
//                                                   loading = false;
//                                                 });
//                                               },
//                                               child: Container(
//                                                 margin:
//                                                     EdgeInsets.only(bottom: 20),
//                                                 child: Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.start,
//                                                   children: [
//                                                     ClipRRect(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               10000),
//                                                       child: CachedNetworkImage(
//                                                         fit: BoxFit.cover,
//                                                         filterQuality:
//                                                             FilterQuality.none,
//                                                         height: 30,
//                                                         width: 30,
//                                                         placeholder:
//                                                             (context, url) =>
//                                                                 SizedBox(
//                                                           height: 50,
//                                                           width: 50,
//                                                           child:
//                                                               Transform.scale(
//                                                             scale: 0.3,
//                                                             child:
//                                                                 const CircularProgressIndicator(
//                                                               strokeWidth: 3.0,
//                                                               backgroundColor:
//                                                                   secondaryColor,
//                                                               valueColor:
//                                                                   AlwaysStoppedAnimation<
//                                                                           Color>(
//                                                                       primaryColor),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         errorWidget: (context,
//                                                                 url, error) =>
//                                                             const Icon(
//                                                           Icons.error,
//                                                           color: primaryColor,
//                                                         ),
//                                                         imageUrl: members
//                                                             .where((element) =>
//                                                                 element.id ==
//                                                                 resultId)
//                                                             .toList()[0]
//                                                             .get("photo"),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 10,
//                                                     ),
//                                                     SizedBox(
//                                                       width: size.width * 0.3,
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           Text(
//                                                             members
//                                                                 .where((element) =>
//                                                                     element
//                                                                         .id ==
//                                                                     resultId)
//                                                                 .toList()[0]
//                                                                 .get('id'),
//                                                             style: GoogleFonts
//                                                                 .montserrat(
//                                                               textStyle:
//                                                                   const TextStyle(
//                                                                 color:
//                                                                     darkColor,
//                                                                 fontSize: 15,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w700,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 25,
//                                                           ),
//                                                           Text(
//                                                             members
//                                                                     .where((element) =>
//                                                                         element
//                                                                             .id ==
//                                                                         resultId)
//                                                                     .toList()[0]
//                                                                     .get(
//                                                                         'name') +
//                                                                 " " +
//                                                                 members
//                                                                     .where((element) =>
//                                                                         element
//                                                                             .id ==
//                                                                         resultId)
//                                                                     .toList()[0]
//                                                                     .get(
//                                                                         'surname'),
//                                                             style: GoogleFonts
//                                                                 .montserrat(
//                                                               textStyle:
//                                                                   const TextStyle(
//                                                                 color:
//                                                                     darkColor,
//                                                                 fontSize: 10,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w400,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 20,
//                                                     ),
//                                                     SizedBox(
//                                                       width: size.width * 0.2,
//                                                       child: Text(
//                                                         bestMembers[resultId]!
//                                                             .toStringAsFixed(1),
//                                                         maxLines: 2,
//                                                         style: GoogleFonts
//                                                             .montserrat(
//                                                           textStyle:
//                                                               const TextStyle(
//                                                             color: darkColor,
//                                                             fontSize: 20,
//                                                             fontWeight:
//                                                                 FontWeight.w700,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 20,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                         SizedBox(
//                                           height: 30,
//                                         ),
//                                         Text(
//                                           'Bottom 3',
//                                           overflow: TextOverflow.ellipsis,
//                                           style: GoogleFonts.montserrat(
//                                             textStyle: const TextStyle(
//                                               color: whiteColor,
//                                               fontSize: 23,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                           height: 30,
//                                         ),
//                                         for (var resultId
//                                             in wortsMembers.keys.take(3))
//                                           if (members
//                                               .where((element) =>
//                                                   element.id == resultId)
//                                               .toList()
//                                               .isNotEmpty)
//                                             CupertinoButton(
//                                               padding: EdgeInsets.zero,
//                                               onPressed: () {
//                                                 setState(() {
//                                                   loading = true;
//                                                 });
//                                                 Navigator.push(
//                                                   context,
//                                                   SlideRightRoute(
//                                                     page: ViewProfileScreen(
//                                                       profileId: resultId,
//                                                     ),
//                                                   ),
//                                                 );
//                                                 setState(() {
//                                                   loading = false;
//                                                 });
//                                               },
//                                               child: Container(
//                                                 margin:
//                                                     EdgeInsets.only(bottom: 20),
//                                                 child: Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.start,
//                                                   children: [
//                                                     ClipRRect(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               10000),
//                                                       child: CachedNetworkImage(
//                                                         fit: BoxFit.cover,
//                                                         filterQuality:
//                                                             FilterQuality.none,
//                                                         height: 30,
//                                                         width: 30,
//                                                         placeholder:
//                                                             (context, url) =>
//                                                                 SizedBox(
//                                                           height: 50,
//                                                           width: 50,
//                                                           child:
//                                                               Transform.scale(
//                                                             scale: 0.3,
//                                                             child:
//                                                                 const CircularProgressIndicator(
//                                                               strokeWidth: 3.0,
//                                                               backgroundColor:
//                                                                   secondaryColor,
//                                                               valueColor:
//                                                                   AlwaysStoppedAnimation<
//                                                                           Color>(
//                                                                       primaryColor),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         errorWidget: (context,
//                                                                 url, error) =>
//                                                             const Icon(
//                                                           Icons.error,
//                                                           color: primaryColor,
//                                                         ),
//                                                         imageUrl: members
//                                                             .where((element) =>
//                                                                 element.id ==
//                                                                 resultId)
//                                                             .toList()[0]
//                                                             .get("photo"),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 10,
//                                                     ),
//                                                     SizedBox(
//                                                       width: size.width * 0.3,
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .start,
//                                                         children: [
//                                                           Text(
//                                                             members
//                                                                 .where((element) =>
//                                                                     element
//                                                                         .id ==
//                                                                     resultId)
//                                                                 .toList()[0]
//                                                                 .get('id'),
//                                                             style: GoogleFonts
//                                                                 .montserrat(
//                                                               textStyle:
//                                                                   const TextStyle(
//                                                                 color:
//                                                                     whiteColor,
//                                                                 fontSize: 15,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w700,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 25,
//                                                           ),
//                                                           Text(
//                                                             members
//                                                                     .where((element) =>
//                                                                         element
//                                                                             .id ==
//                                                                         resultId)
//                                                                     .toList()[0]
//                                                                     .get(
//                                                                         'name') +
//                                                                 " " +
//                                                                 members
//                                                                     .where((element) =>
//                                                                         element
//                                                                             .id ==
//                                                                         resultId)
//                                                                     .toList()[0]
//                                                                     .get(
//                                                                         'surname'),
//                                                             style: GoogleFonts
//                                                                 .montserrat(
//                                                               textStyle:
//                                                                   const TextStyle(
//                                                                 color:
//                                                                     whiteColor,
//                                                                 fontSize: 10,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w400,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 20,
//                                                     ),
//                                                     SizedBox(
//                                                       width: size.width * 0.2,
//                                                       child: Text(
//                                                         wortsMembers[resultId]!
//                                                             .toStringAsFixed(1),
//                                                         maxLines: 2,
//                                                         style: GoogleFonts
//                                                             .montserrat(
//                                                           textStyle:
//                                                               const TextStyle(
//                                                             color: whiteColor,
//                                                             fontSize: 20,
//                                                             fontWeight:
//                                                                 FontWeight.w700,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 20,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                       ],
//                                     ),
//                                   ),

//                                   // Info
//                                   Row(
//                                     mainAxisAlignment:
//                                         MainAxisAlignment.spaceAround,
//                                     children: [
//                                       Text(
//                                         'Info',
//                                         overflow: TextOverflow.ellipsis,
//                                         style: GoogleFonts.montserrat(
//                                           textStyle: const TextStyle(
//                                             color: secondaryColor,
//                                             fontSize: 25,
//                                             fontWeight: FontWeight.w700,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         width: 10,
//                                       ),
//                                       RoundedButton(
//                                         pw: 100,
//                                         ph: 45,
//                                         text: 'Invite',
//                                         press: () async {
//                                           EncryptionService encService =
//                                               EncryptionService();
//                                           String encryptedId =
//                                               encService.enc(network!.id);
//                                           String encId =
//                                               Uri.encodeComponent(encryptedId);
//                                           final dynamicLinkParams =
//                                               DynamicLinkParameters(
//                                             link: Uri.parse(
//                                                 'https://ozod.page.link/join?encID=$encId'),
//                                             uriPrefix: "https://ozod.page.link",
//                                             androidParameters:
//                                                 const AndroidParameters(
//                                                     packageName: "com.ozod"),
//                                             iosParameters: const IOSParameters(
//                                                 bundleId: "com.ozod"),
//                                           );

//                                           ShortDynamicLink link =
//                                               await FirebaseDynamicLinks
//                                                   .instance
//                                                   .buildShortLink(
//                                                       dynamicLinkParams);
//                                           Uri dynamicLink = link.shortUrl;

//                                           showDialog(
//                                               barrierDismissible: false,
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return StatefulBuilder(
//                                                   builder: (context,
//                                                       StateSetter setState) {
//                                                     return AlertDialog(
//                                                       backgroundColor:
//                                                           darkPrimaryColor,
//                                                       shape:
//                                                           RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(20.0),
//                                                       ),
//                                                       title: const Text(
//                                                         'Invite',
//                                                         style: TextStyle(
//                                                             color:
//                                                                 secondaryColor),
//                                                       ),
//                                                       content:
//                                                           SingleChildScrollView(
//                                                         child: Container(
//                                                           margin:
//                                                               EdgeInsets.all(
//                                                                   10),
//                                                           child: Column(
//                                                             children: [
//                                                               Container(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .all(20),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               20.0),
//                                                                   gradient:
//                                                                       const LinearGradient(
//                                                                     begin: Alignment
//                                                                         .topLeft,
//                                                                     end: Alignment
//                                                                         .bottomRight,
//                                                                     colors: [
//                                                                       darkPrimaryColor,
//                                                                       primaryColor
//                                                                     ],
//                                                                   ),
//                                                                 ),
//                                                                 child: QrImage(
//                                                                   data: dynamicLink
//                                                                       .toString(),
//                                                                   foregroundColor:
//                                                                       secondaryColor,
//                                                                 ),
//                                                               ),
//                                                               SizedBox(
//                                                                 height: 10,
//                                                               ),
//                                                               Text(
//                                                                 dynamicLink
//                                                                     .toString(),
//                                                                 overflow:
//                                                                     TextOverflow
//                                                                         .ellipsis,
//                                                                 maxLines: 10,
//                                                                 textAlign:
//                                                                     TextAlign
//                                                                         .center,
//                                                                 style: GoogleFonts
//                                                                     .montserrat(
//                                                                   textStyle:
//                                                                       const TextStyle(
//                                                                     color:
//                                                                         whiteColor,
//                                                                     fontSize:
//                                                                         10,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .w500,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                               SizedBox(
//                                                                 height: 20,
//                                                               ),
//                                                               RoundedButton(
//                                                                 pw: 100,
//                                                                 ph: 45,
//                                                                 text: 'Share',
//                                                                 press:
//                                                                     () async {
//                                                                   Share.share(
//                                                                       dynamicLink
//                                                                           .toString());
//                                                                 },
//                                                                 color:
//                                                                     Colors.blue,
//                                                                 textColor:
//                                                                     whiteColor,
//                                                               ),
//                                                               SizedBox(
//                                                                 height: 20,
//                                                               ),
//                                                               RoundedButton(
//                                                                 pw: 100,
//                                                                 ph: 45,
//                                                                 text: 'Copy',
//                                                                 press:
//                                                                     () async {
//                                                                   await Clipboard.setData(
//                                                                       ClipboardData(
//                                                                           text:
//                                                                               dynamicLink.toString()));
//                                                                   PushNotificationMessage
//                                                                       notification =
//                                                                       PushNotificationMessage(
//                                                                     title:
//                                                                         'Copied',
//                                                                     body:
//                                                                         'Link copied',
//                                                                   );
//                                                                   showSimpleNotification(
//                                                                     Text(notification
//                                                                         .body),
//                                                                     position:
//                                                                         NotificationPosition
//                                                                             .top,
//                                                                     background:
//                                                                         greenColor,
//                                                                   );
//                                                                 },
//                                                                 color:
//                                                                     secondaryColor,
//                                                                 textColor:
//                                                                     darkPrimaryColor,
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ),
//                                                       actions: <Widget>[
//                                                         TextButton(
//                                                           onPressed: () =>
//                                                               Navigator.of(
//                                                                       context)
//                                                                   .pop(false),
//                                                           child: const Text(
//                                                             'Ok',
//                                                             style: TextStyle(
//                                                                 color:
//                                                                     secondaryColor),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     );
//                                                   },
//                                                 );
//                                               });
//                                         },
//                                         color: secondaryColor,
//                                         textColor: darkPrimaryColor,
//                                       ),
//                                     ],
//                                   ),

//                                   const SizedBox(
//                                     height: 20,
//                                   ),
//                                   Container(
//                                     key: keyButton3,
//                                     // margin: const EdgeInsets.only(bottom: 20),
//                                     padding: const EdgeInsets.all(20),
//                                     decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20.0),
//                                       gradient: const LinearGradient(
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                         colors: [
//                                           Color.fromARGB(255, 255, 190, 99),
//                                           Color.fromARGB(255, 255, 81, 83)
//                                         ],
//                                       ),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.center,
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.spaceEvenly,
//                                           children: [
//                                             SizedBox(
//                                               width: size.width * 0.35,
//                                               child: Column(
//                                                 children: [
//                                                   Text(
//                                                     networkYearPoints
//                                                         .toStringAsFixed(1),
//                                                     maxLines: 3,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style: GoogleFonts.anton(
//                                                       textStyle:
//                                                           const TextStyle(
//                                                         color: darkColor,
//                                                         fontSize: 35,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     'in ${DateTime.now().year}',
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style:
//                                                         GoogleFonts.montserrat(
//                                                       textStyle:
//                                                           const TextStyle(
//                                                         color: darkColor,
//                                                         fontSize: 15,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               width: size.width * 0.35,
//                                               child: Column(
//                                                 children: [
//                                                   Text(
//                                                     avgDayPoints
//                                                         .toStringAsFixed(1),
//                                                     maxLines: 3,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style: GoogleFonts.anton(
//                                                       textStyle:
//                                                           const TextStyle(
//                                                         color: darkColor,
//                                                         fontSize: 35,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     'per day',
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style:
//                                                         GoogleFonts.montserrat(
//                                                       textStyle:
//                                                           const TextStyle(
//                                                         color: darkColor,
//                                                         fontSize: 15,
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         SizedBox(
//                                           height: 20,
//                                         ),
//                                         for (DocumentSnapshot member in members)
//                                           if (member.exists)
//                                             CupertinoButton(
//                                               onPressed: () {
//                                                 setState(() {
//                                                   loading = true;
//                                                 });
//                                                 Navigator.push(
//                                                   context,
//                                                   SlideRightRoute(
//                                                     page: ViewProfileScreen(
//                                                       profileId: member.id,
//                                                     ),
//                                                   ),
//                                                 );
//                                                 setState(() {
//                                                   loading = false;
//                                                 });
//                                               },
//                                               child: Container(
//                                                 // margin: EdgeInsets.only(bottom: 20),
//                                                 child: Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment.start,
//                                                   children: [
//                                                     Container(
//                                                       width: 20,
//                                                       margin: EdgeInsets.only(
//                                                           right: 10),
//                                                       child: network!
//                                                               .get('admins')
//                                                               .contains(
//                                                                   member.id)
//                                                           ? Icon(
//                                                               CupertinoIcons
//                                                                   .star_circle_fill,
//                                                               color: darkColor,
//                                                               size: 20,
//                                                             )
//                                                           : Container(),
//                                                     ),
//                                                     ClipRRect(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               10000),
//                                                       child: CachedNetworkImage(
//                                                         fit: BoxFit.cover,
//                                                         filterQuality:
//                                                             FilterQuality.none,
//                                                         height: 30,
//                                                         width: 30,
//                                                         placeholder:
//                                                             (context, url) =>
//                                                                 SizedBox(
//                                                           height: 50,
//                                                           width: 50,
//                                                           child:
//                                                               Transform.scale(
//                                                             scale: 0.3,
//                                                             child:
//                                                                 const CircularProgressIndicator(
//                                                               strokeWidth: 3.0,
//                                                               backgroundColor:
//                                                                   darkColor,
//                                                               valueColor:
//                                                                   AlwaysStoppedAnimation<
//                                                                           Color>(
//                                                                       primaryColor),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         errorWidget: (context,
//                                                                 url, error) =>
//                                                             const Icon(
//                                                           Icons.error,
//                                                           color: primaryColor,
//                                                         ),
//                                                         imageUrl:
//                                                             member.get("photo"),
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 20,
//                                                     ),
//                                                     Column(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         Text(
//                                                           member.get('id'),
//                                                           style: GoogleFonts
//                                                               .montserrat(
//                                                             textStyle:
//                                                                 const TextStyle(
//                                                               color: darkColor,
//                                                               fontSize: 15,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w700,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 25,
//                                                         ),
//                                                         Text(
//                                                           member.get('name') +
//                                                               " " +
//                                                               member.get(
//                                                                   'surname'),
//                                                           style: GoogleFonts
//                                                               .montserrat(
//                                                             textStyle:
//                                                                 const TextStyle(
//                                                               color: darkColor,
//                                                               fontSize: 10,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .w400,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             )
//                                       ],
//                                     ),
//                                   ),

//                                   SizedBox(
//                                     height: 100,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//   }
// }
