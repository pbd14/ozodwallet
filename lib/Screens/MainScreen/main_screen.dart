import 'dart:async';
import 'dart:io' as io;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodwallet/Screens/HomeScreen/home_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/wallet_screen.dart';
import 'package:ozodwallet/Screens/WelcomeScreen/welcome_screen.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
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
  bool appIsActive = true;
  StreamSubscription? firebaseVarsSubscription;
  StreamSubscription? walletExistsSubscription;
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        refreshFunction: _refresh,
      ),
      WalletScreen(),
      // LoyaltyScreen(),
      // WalletScreen(),
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
      // if (!kIsWeb)
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.wallet),
        title: ("Home"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: darkPrimaryColor,
        inactiveColorPrimary: darkPrimaryColor,
        textStyle: GoogleFonts.montserrat(
          textStyle: const TextStyle(
            color: darkPrimaryColor,
            // fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(CupertinoIcons.suit_diamond_fill),
        title: ("Ethereum"),
        activeColorPrimary: secondaryColor,
        activeColorSecondary: darkPrimaryColor,
        inactiveColorPrimary: darkPrimaryColor,
        textStyle: GoogleFonts.montserrat(
          textStyle: const TextStyle(
            color: darkPrimaryColor,
            // fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(CupertinoIcons.square_grid_3x2_fill),
      //   title: ("Loyalty"),
      //   activeColorPrimary: secondaryColor,
      //   activeColorSecondary: secondaryColor,
      //   inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      // ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(CupertinoIcons.person),
      //   title: ("Profile"),
      //   activeColorPrimary: secondaryColor,
      //   activeColorSecondary: secondaryColor,
      //   inactiveColorPrimary: const Color.fromRGBO(200, 200, 200, 1.0),
      // ),
    ];
  }

  Future<void> prepare() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    firebaseVarsSubscription = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('vars')
        .snapshots()
        .listen((vars) {
      if (mounted) {
        setState(() {
          appIsActive = vars.get('ozod_wallet_app_active');
        });
      } else {
        appIsActive = vars.get('ozod_wallet_app_active');
      }
    });

    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

    String? value = await storage.read(key: 'walletExists');
    if (value != 'true') {
      Navigator.push(
        context,
        SlideRightRoute(
          page: WelcomeScreen(),
        ),
      );
    } else {
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
    super.initState();
  }

  @override
  void dispose() {
    firebaseVarsSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen()
        : !appIsActive
            ? Scaffold(
                backgroundColor: darkPrimaryColor,
                body: Container(
                    margin: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/images/iso2.png",
                          width: 400,
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          'App is currently unavailable. Check again later',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: lightPrimaryColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )),
              )
            : !walletExists
                ? Scaffold(
                    backgroundColor: darkPrimaryColor,
                    body: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 200,
                              ),
                              Image.asset(
                                "assets/images/iso6.png",
                                width: size.width * 0.9,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  'What is Web3 Wallet?',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'A Web3 wallet is a safe storage of your money on blockchain. It lets you control and own your money, without any intermediaries.',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                              Image.asset(
                                "assets/images/iso7.png",
                                width: size.width * 0.9,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Public key',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Each wallet has a public key, which is like username for your wallet. You can share it with everyone, so that they can send you money',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  'Private key',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Private key on the other hand is a password to your wallet. DO NOT shate it. Anyone who has your private key, has full access of your wallet',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                              Image.asset(
                                "assets/images/iso8.png",
                                width: size.width * 0.9,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Gas',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Gas is a fee you pay to make transactions on the blockchain. You need to buy some gas for very cheap to make transactions',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),
                              RoundedButton(
                                pw: 150,
                                ph: 45,
                                text: 'Start',
                                press: () async {
                                  _refresh();
                                },
                                color: secondaryColor,
                                textColor: darkPrimaryColor,
                              ),
                              SizedBox(
                                height: size.height * 0.1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : PersistentTabView(
                    context,
                    controller: _controller,
                    screens: _buildScreens(),
                    items: _navBarsItems(),
                    navBarHeight: 60,
                    confineInSafeArea: false,
                    backgroundColor:
                        lightPrimaryColor, // Default is Colors.white.
                    handleAndroidBackButtonPress: true, // Default is true.
                    resizeToAvoidBottomInset:
                        true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
                    stateManagement: true, // Default is true.
                    hideNavigationBarWhenKeyboardShows:
                        true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
                    decoration: NavBarDecoration(
                      borderRadius: BorderRadius.circular(40.0),
                      colorBehindNavBar: darkPrimaryColor,
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
                    navBarStyle: NavBarStyle.style7,
                    margin: kIsWeb
                        ? size.width >= 600
                            ? EdgeInsets.fromLTRB((size.width - 600) / 2 + 20,
                                0, (size.width - 600) / 2 + 20, 20)
                            : EdgeInsets.fromLTRB(20, 0, 20, 20)
                        : io.Platform.isIOS
                            ? const EdgeInsets.fromLTRB(20, 0, 20, 20)
                            : const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  );
  }
}
