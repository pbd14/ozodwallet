import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Screens/WalletScreen/wallet_screen.dart';
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
  String? country;
  String? state;
  String? city;
  int? tabNum;
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      WalletScreen(),
      WalletScreen(),
      WalletScreen(),
      WalletScreen(),
    ];
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

  @override
  void initState() {
    tabNum = widget.tabNum;
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