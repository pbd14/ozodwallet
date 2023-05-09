import 'dart:async';
import 'dart:math';

import 'package:bip39/bip39.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glass/glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Screens/WalletScreen/check_seed_screen.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class CreateWalletScreen extends StatefulWidget {
  String error;
  bool isWelcomeScreen;
  CreateWalletScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    this.isWelcomeScreen = true,
  }) : super(key: key);

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  bool loading = true;
  String? mnemonicPhrase;
  Uint8List? seed;
  String? password;
  String name = "Wallet1";
  bool showSeed = false;
  final _formKey = GlobalKey<FormState>();

  // Ozod ID
  User? ozodIdUser;
  StreamSubscription<User?>? authStream;

  void prepare() {
    setState(() {
      mnemonicPhrase = generateMnemonic();
      seed = mnemonicToSeed(mnemonicPhrase!);
      loading = false;
    });
  }

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
    prepare();
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
    // ignore: unused_local_variable
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
    return loading
        ? LoadingScreen()
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: true,
              toolbarHeight: 30,
              backgroundColor: darkPrimaryColor,
              foregroundColor: secondaryColor,
              centerTitle: true,
              actions: [],
            ),
            backgroundColor: darkPrimaryColor,
            body: SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  constraints:
                      BoxConstraints(maxWidth: kIsWeb ? 600 : double.infinity),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 30,
                        ),

                        // Ozod ID
                        ozodIdUser != null
                            ? Center(
                                child: Container(
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
                                    child: Column(
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
                                        Text(
                                          "Create easily with Ozod ID. Just one click",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          maxLines: 10,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: whiteColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 20),
                                          child: RoundedButton(
                                            pw: 150,
                                            ph: 35,
                                            text: 'CREATE',
                                            press: () async {
                                              setState(() {
                                                loading = true;
                                              });
                                              try {
                                                // Create Web3 Wallet
                                                String mnemonicPhrase =
                                                    generateMnemonic();
                                                Uint8List seed = mnemonicToSeed(
                                                    mnemonicPhrase);
                                                final master =
                                                    await ED25519_HD_KEY
                                                        .getMasterKeyFromSeed(
                                                            seed);
                                                final privateKey =
                                                    HEX.encode(master.key);
                                                final publicKey =
                                                    EthPrivateKey.fromHex(
                                                            privateKey)
                                                        .address;
                                                String lastWalletIndex =
                                                    await SafeStorageService().storage.read(
                                                            key:
                                                                "lastWalletIndex") ??
                                                        "1";
                                                Web3Wallet web3wallet =
                                                    Web3Wallet(
                                                        privateKey: privateKey,
                                                        publicKey: publicKey
                                                            .toString(),
                                                        name: "Wallet Name",
                                                        localIndex:
                                                            lastWalletIndex);
                                                await SafeStorageService()
                                                    .addNewWallet(web3wallet);
                                                // ignore: unused_local_variable
                                                Wallet wallet =
                                                    Wallet.createNew(
                                                        EthPrivateKey.fromHex(
                                                            privateKey),
                                                        "Password",
                                                        Random());
                                                await FirebaseFirestore.instance
                                                    .collection('wallets')
                                                    .doc(publicKey.toString())
                                                    .set({
                                                  'loyalty_programs': [],
                                                  'publicKey':
                                                      publicKey.toString(),
                                                  'assets': [],
                                                  'privateKey': web3wallet
                                                      .encPrivateKey(web3wallet
                                                          .privateKey),
                                                  'ozodIdConnected': true,
                                                  'ozodIdAccount': FirebaseAuth
                                                      .instance
                                                      .currentUser!
                                                      .uid,
                                                });

                                                await FirebaseFirestore.instance
                                                    .collection(
                                                        'ozod_id_accounts')
                                                    .doc(FirebaseAuth.instance
                                                        .currentUser!.uid)
                                                    .update({
                                                  'wallets':
                                                      FieldValue.arrayUnion([
                                                    web3wallet.publicKey
                                                  ]),
                                                });
                                                showNotification(
                                                    'Success',
                                                    'Wallet has been created',
                                                    greenColor);
                                              } catch (e) {
                                                showNotification(
                                                    'Failed',
                                                    'Try again later',
                                                    greenColor);
                                              }
                                              Navigator.pop(context);
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
                                    clipBorderRadius:
                                        BorderRadius.circular(20.0),
                                    tintColor: darkDarkColor,
                                  ),
                                ),
                              )
                            : Container(),
                        SizedBox(
                          height: ozodIdUser != null ? 50 : 0,
                        ),
                        Text(
                          "Your seed phrase",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "This is your secret phrase to access your wallet. Save this phrase in a safe physical place. DO NOT SHARE OR LOSE THESE PHRASES. Ozod Wallet does not save these phrases, so if you lose this phrase you will your wallet.",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Center(
                          child: CupertinoButton(
                            child: showSeed
                                ? Container(
                                    width: size.width * 0.8,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 255, 190, 99),
                                          Color.fromARGB(255, 255, 81, 83)
                                        ],
                                      ),
                                    ),
                                    child: Text(
                                      mnemonicPhrase!,
                                      maxLines: 1000,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 255, 190, 99),
                                          Color.fromARGB(255, 255, 81, 83)
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                        child: Icon(
                                      CupertinoIcons.eye_fill,
                                      color: whiteColor,
                                    )),
                                  ),
                            onPressed: () {
                              setState(() {
                                showSeed = !showSeed;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Text(
                        //   "Your password",
                        //   overflow: TextOverflow.ellipsis,
                        //   maxLines: 3,
                        //   textAlign: TextAlign.start,
                        //   style: GoogleFonts.montserrat(
                        //     textStyle: const TextStyle(
                        //       color: secondaryColor,
                        //       fontSize: 35,
                        //       fontWeight: FontWeight.w700,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(
                        //   height: 20,
                        // ),
                        // Text(
                        //   "This is your password for wallet. Save this password in a safe physical place. DO NOT SHARE OR LOSE THIS PASSWORD. Ozod Wallet does not save this password, so if you lose this password you will your wallet.",
                        //   overflow: TextOverflow.ellipsis,
                        //   maxLines: 1000,
                        //   textAlign: TextAlign.start,
                        //   style: GoogleFonts.montserrat(
                        //     textStyle: const TextStyle(
                        //       color: secondaryColor,
                        //       fontSize: 20,
                        //       fontWeight: FontWeight.w400,
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(
                        //   height: 20,
                        // ),
                        // TextFormField(
                        //   style: const TextStyle(color: secondaryColor),
                        //   validator: (val) {
                        //     if (val!.isEmpty) {
                        //       return 'Enter your password';
                        //     } else {
                        //       return null;
                        //     }
                        //   },
                        //   keyboardType: TextInputType.visiblePassword,
                        //   onChanged: (val) {
                        //     setState(() {
                        //       password = val;
                        //     });
                        //   },
                        //   decoration: InputDecoration(
                        //     errorBorder: OutlineInputBorder(
                        //       borderSide:
                        //           BorderSide(color: Colors.red, width: 1.0),
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     focusedBorder: OutlineInputBorder(
                        //       borderSide:
                        //           BorderSide(color: secondaryColor, width: 1.0),
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     enabledBorder: OutlineInputBorder(
                        //       borderSide:
                        //           BorderSide(color: secondaryColor, width: 1.0),
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //     hintStyle: TextStyle(
                        //         color: darkPrimaryColor.withOpacity(0.7)),
                        //     hintText: 'Password',
                        //     border: OutlineInputBorder(
                        //       borderSide:
                        //           BorderSide(color: secondaryColor, width: 1.0),
                        //       borderRadius: BorderRadius.circular(20),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 40),
                        Text(
                          "Wallet name",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "Name your wallet. You do not have to save this",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        TextFormField(
                          style: const TextStyle(color: secondaryColor),
                          validator: (val) {
                            if (val!.isEmpty) {
                              return 'Enter wallet name';
                            } else {
                              return null;
                            }
                          },
                          keyboardType: TextInputType.name,
                          onChanged: (val) {
                            setState(() {
                              name = val;
                            });
                          },
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            hintStyle: TextStyle(
                                color: darkPrimaryColor.withOpacity(0.7)),
                            hintText: 'Name',
                            border: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'DONE',
                            press: () {
                              // if (_formKey.currentState!.validate() &&
                              //     password != null &&
                              //     password!.isNotEmpty)
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  loading = true;
                                });
                                Navigator.push(
                                  context,
                                  SlideRightRoute(
                                    page: CheckSeedScreen(
                                      name: name,
                                      password: password ?? "Password",
                                      mnemonicPhrase: mnemonicPhrase!,
                                      isWelcomeScreen: widget.isWelcomeScreen,
                                    ),
                                  ),
                                );
                                setState(() {
                                  loading = false;
                                });
                              }
                            },
                            color: secondaryColor,
                            textColor: darkPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
