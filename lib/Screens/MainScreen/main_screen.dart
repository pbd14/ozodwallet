import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Screens/LoyaltyScreen/loyalty_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/wallet_screen.dart';
import 'package:ozodwallet/Screens/WelcomeScreen/welcome_screen.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
// import 'package:package_info/package_info.dart';
import 'package:persistent_bottom_nav_bar/persistent-tab-view.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MainScreen extends StatefulWidget {
  int tabNum;
  MainScreen({
    Key? key,
    this.tabNum = 0,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? tabNum;
  bool loading = true;
  bool walletExists = false;
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      WalletScreen(),
      LoyaltyScreen(),
      WalletScreen(),
      WalletScreen(),
    ];
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    walletExists = false;
    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  void changeTabNumber(int number) {
    _controller.jumpToTab(number);
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      if (!kIsWeb)
        PersistentBottomNavBarItem(
          icon: const Icon(CupertinoIcons.money_dollar),
          title: ("Home"),
          activeColorPrimary: secondaryColor,
          activeColorSecondary: secondaryColor,
          inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
        ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.square_grid_3x2_fill),
        title: ("Loyalty"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: secondaryColor,
        inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.gamecontroller_fill),
        title: ("Battle"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: secondaryColor,
        inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
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

  Future<void> prepare() async {
    
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    String? value = await storage.read(key: 'walletExists');
    if (value != 'true') {
      Navigator.push(
        context,
        SlideRightRoute(
          page: WelcomeScreen(),
        ),
      );
    } else{
      walletExists = true;
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    prepare();
    tabNum = widget.tabNum;
    if (widget.tabNum != 0) {
      _controller.jumpToTab(widget.tabNum);
    }
    prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const LoadingScreen()
        : !walletExists
            ? Scaffold(
                backgroundColor: primaryColor,
                body: Container(
                  margin: const EdgeInsets.all(20),
                  child: Center(
                    child: RoundedButton(
                      pw: 150,
                      ph: 45,
                      text: 'Start',
                      press: () async {
                        _refresh();
                      },
                      color: secondaryColor,
                      textColor: darkPrimaryColor,
                    ),
                  ),
                ),
              )
            : PersistentTabView(
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
