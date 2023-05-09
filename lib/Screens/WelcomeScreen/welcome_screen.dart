import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:glass/glass.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_login_screen.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_signup_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Services/auth/auth_service.dart';
import 'package:ozodwallet/Services/languages/languages.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: must_be_immutable
class WelcomeScreen extends StatefulWidget {
  Function mainScreenRefreshFunction;
  WelcomeScreen({
    required this.mainScreenRefreshFunction,
    Key? key,
  }) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool loading = false;
  User? ozodIdUser;
  StreamSubscription<User?>? authStream;

  @override
  void initState() {
    // Ozod ID Auth state listener
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          ozodIdUser = user;
        });
      } else {
        ozodIdUser = user;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    if (authStream != null) {
      authStream!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double realWidth = size.width;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
    return loading
        ? LoadingScreen()
        : WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              backgroundColor: darkPrimaryColor,
              body: Center(
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: 10,
                        child: Image.asset(
                          "assets/images/iso1.png",
                          width: size.width * 1.4,
                        ),
                      ),
                      Positioned(
                        top: 250,
                        left: 100,
                        child: Image.asset(
                          "assets/images/iso3.png",
                          width: size.width * 0.8,
                        ),
                      ),
                      Container(
                        // padding: EdgeInsets.all(20),
                        constraints: BoxConstraints(
                            maxWidth: kIsWeb ? 600 : double.infinity),
                        child: Column(
                          children: [
                            SizedBox(
                              height: size.height * 0.75,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  Languages.of(context)!.welcomeToOzod,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 45,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'OZOD',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 65,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                            Image.asset(
                              "assets/images/iso4.png",
                              width: size.width * 0.9,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  'Web3 Wallet Just',
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 55,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Text(
                                  'For You',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 65,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 100),
                            Image.asset(
                              "assets/images/iso5.png",
                              width: size.width * 1.5,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Best Way To Use',
                                  textAlign: TextAlign.start,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 55,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  'Your Money',
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 65,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),

                            // SizedBox(
                            //   width: size.width * 0.8,
                            //   child: Card(
                            //     color: lightPrimaryColor,
                            //     shape: RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(20.0),
                            //     ),
                            //     elevation: 10,
                            //     child: Padding(
                            //       padding: const EdgeInsets.all(20),
                            //       child: Column(
                            //         mainAxisAlignment: MainAxisAlignment.center,
                            //         children: <Widget>[
                            //           Text(
                            //             'Language',
                            //             overflow: TextOverflow.ellipsis,
                            //             style: GoogleFonts.montserrat(
                            //               textStyle: const TextStyle(
                            //                 color: darkPrimaryColor,
                            //                 fontSize: 17,
                            //                 fontWeight: FontWeight.w400,
                            //               ),
                            //             ),
                            //           ),
                            //           const SizedBox(height: 10),
                            //           DropdownButton<LanguageData>(
                            //             iconSize: 30,
                            //             hint: Text(
                            //               Languages.of(context)!.labelSelectLanguage,
                            //               style: const TextStyle(
                            //                   color: darkPrimaryColor),
                            //             ),
                            //             onChanged: (LanguageData? language) {
                            //               changeLanguage(
                            //                   context, language!.languageCode);
                            //             },
                            //             items: LanguageData.languageList()
                            //                 .map<DropdownMenuItem<LanguageData>>(
                            //                   (e) => DropdownMenuItem<LanguageData>(
                            //                     value: e,
                            //                     child: Row(
                            //                       mainAxisAlignment:
                            //                           MainAxisAlignment.spaceAround,
                            //                       children: <Widget>[
                            //                         Text(
                            //                           e.flag,
                            //                           style: const TextStyle(
                            //                               fontSize: 30),
                            //                         ),
                            //                         Text(e.name)
                            //                       ],
                            //                     ),
                            //                   ),
                            //                 )
                            //                 .toList(),
                            //           ),
                            //           const SizedBox(
                            //             height: 20,
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            // const SizedBox(height: 100),

                            // Ozod ID
                            Container(
                              margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                              width: size.width * 0.8,
                              // height: 200,
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromARGB(255, 70, 213, 196),
                                    Color.fromARGB(255, 19, 51, 77),
                                  ],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                child: ozodIdUser != null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Image.asset(
                                                'assets/icons/logoAuth300.png',
                                                width: 40,
                                                height: 40,
                                                // scale: 10,
                                              ),
                                              Text(
                                                'Ozod ID',
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: whiteColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Center(
                                            child: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: ozodIdColor1,
                                                    width: 1.0),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  Text(
                                                    "ID: ${ozodIdUser!.uid}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    maxLines: 4,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: ozodIdColor1,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Divider(
                                                    color: ozodIdColor1,
                                                  ),
                                                  Text(
                                                    "Session: ${ozodIdUser!.email}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    maxLines: 4,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: ozodIdColor1,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 5,
                                                  ),
                                                  Text(
                                                    "Email Verified: ${ozodIdUser!.emailVerified ? 'Yes' : 'No'}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    maxLines: 4,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: ozodIdColor1,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  !ozodIdUser!.emailVerified
                                                      ? Center(
                                                          child: RoundedButton(
                                                            pw: 200,
                                                            ph: 40,
                                                            text:
                                                                'Resend verification',
                                                            press: () async {
                                                              bool isError =
                                                                  false;
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser!
                                                                  .sendEmailVerification()
                                                                  .catchError(
                                                                      (error) {
                                                                isError = true;
                                                                showNotification(
                                                                    'Failed',
                                                                    'Failed to send email',
                                                                    Colors.red);
                                                              }).whenComplete(
                                                                      () {
                                                                if (!isError) {
                                                                  showNotification(
                                                                      'Success',
                                                                      'Email sent',
                                                                      greenColor);
                                                                }
                                                              });
                                                            },
                                                            color: ozodIdColor1,
                                                            textColor:
                                                                ozodIdColor2,
                                                          ),
                                                        )
                                                      : Container(),
                                                  SizedBox(
                                                    height: !ozodIdUser!
                                                            .emailVerified
                                                        ? 20
                                                        : 0,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: RoundedButton(
                                              pw: 250,
                                              ph: 45,
                                              text: 'Sign Out',
                                              press: () {
                                                showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          ozodIdColor2,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                      ),
                                                      // title: Text(
                                                      //     Languages.of(context).profileScreenSignOut),
                                                      // content: Text(
                                                      //     Languages.of(context)!.profileScreenWantToLeave),
                                                      title: const Text(
                                                        'Sign Out?',
                                                        style: TextStyle(
                                                            color:
                                                                ozodIdColor1),
                                                      ),
                                                      content: const Text(
                                                        'Sure?',
                                                        style: TextStyle(
                                                            color:
                                                                ozodIdColor1),
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () {
                                                            // prefs.setBool('local_auth', false);
                                                            // prefs.setString('local_password', '');
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true);
                                                            AuthService()
                                                                .signOut(
                                                                    context);
                                                          },
                                                          child: const Text(
                                                            'Yes',
                                                            style: TextStyle(
                                                                color:
                                                                    ozodIdColor1),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(false),
                                                          child: const Text(
                                                            'No',
                                                            style: TextStyle(
                                                                color:
                                                                    Colors.red),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              color: Colors.red,
                                              textColor: whiteColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Image.asset(
                                                'assets/icons/logoAuth300.png',
                                                width: 40,
                                                height: 40,
                                                // scale: 10,
                                              ),
                                              Text(
                                                'Ozod ID',
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: whiteColor,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 30,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: RoundedButton(
                                              pw: 250,
                                              ph: 45,
                                              text: 'Log In',
                                              press: () {
                                                setState(() {
                                                  loading = true;
                                                });
                                                Navigator.push(
                                                  context,
                                                  SlideRightRoute(
                                                    page: EmailLoginScreen(
                                                      mainScreenRefreshFunction: widget.mainScreenRefreshFunction
                                                    ),
                                                  ),
                                                );
                                                setState(() {
                                                  loading = false;
                                                });
                                              },
                                              color: ozodIdColor1,
                                              textColor: darkPrimaryColor,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 20),
                                            child: RoundedButton(
                                              pw: 250,
                                              ph: 45,
                                              text: 'Sign Up',
                                              press: () {
                                                setState(() {
                                                  loading = true;
                                                });
                                                Navigator.push(
                                                  context,
                                                  SlideRightRoute(
                                                    page: EmailSignUpScreen(),
                                                  ),
                                                );
                                                setState(() {
                                                  loading = false;
                                                });
                                              },
                                              color: ozodIdColor2,
                                              textColor: whiteColor,
                                            ),
                                          ),
                                        ],
                                      ),
                              ).asGlass(
                                blurX: 20,
                                blurY: 20,
                                clipBorderRadius: BorderRadius.circular(20.0),
                                tintColor: darkDarkColor,
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),

                            // Classic Wallet
                            Container(
                              margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                              width: size.width * 0.8,
                              // height: 200,
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    darkPrimaryColor,
                                    lightPrimaryColor,
                                  ],
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          'assets/icons/logo50.png',
                                          width: 30,
                                          height: 30,
                                          // scale: 10,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Text(
                                          'Classic Wallet',
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 30,
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: RoundedButton(
                                        pw: 250,
                                        ph: 45,
                                        text: 'Create wallet',
                                        press: () {
                                          setState(() {
                                            loading = true;
                                          });
                                          Navigator.push(
                                            context,
                                            SlideRightRoute(
                                              page: CreateWalletScreen(),
                                            ),
                                          );
                                          setState(() {
                                            loading = false;
                                          });
                                        },
                                        color: secondaryColor,
                                        textColor: darkPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: RoundedButton(
                                        pw: 250,
                                        ph: 45,
                                        text: 'Existing wallet',
                                        press: () {
                                          setState(() {
                                            loading = true;
                                          });
                                          Navigator.push(
                                            context,
                                            SlideRightRoute(
                                              page: ImportWalletScreen(),
                                            ),
                                          );
                                          setState(() {
                                            loading = false;
                                          });
                                        },
                                        color: darkPrimaryColor,
                                        textColor: secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ).asGlass(
                                blurX: 20,
                                blurY: 20,
                                clipBorderRadius: BorderRadius.circular(20.0),
                                tintColor: darkDarkColor,
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),

                            SizedBox(
                              height: 50,
                            ),
                            TextButton(
                              onPressed: () async {
                                await launchUrl(Uri.https('ozod-wallet.web.app',
                                    '/privacy_policy.html'));
                              },
                              child: Container(
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                                child: Text(
                                  Languages.of(context)!.loginScreenPolicy,
                                  textScaleFactor: 1,
                                  style: GoogleFonts.montserrat(
                                    textStyle: const TextStyle(
                                      color: secondaryColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: size.height * 0.2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
