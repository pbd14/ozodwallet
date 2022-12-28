import 'dart:math';
import 'dart:typed_data';

import 'package:bip39/bip39.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:ozodwallet/Screens/WalletScreen/check_seed_screen.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/credentials.dart';

// ignore: must_be_immutable
class ImportWalletScreen extends StatefulWidget {
  String error;
  bool isWelcomeScreen;
  ImportWalletScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    this.isWelcomeScreen = true,
  }) : super(key: key);

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  bool loading = true;
  String error = '';

  String? userMnemonicPhrase;
  String? password;
  String name = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  void prepare() {
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    Size size = MediaQuery.of(context).size;
    return loading
        ? const LoadingScreen()
        : Scaffold(
            backgroundColor: darkPrimaryColor,
            body: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: size.height * 0.1,
                      ),
                      Text(
                        "Seed phrase",
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
                        "Enter 12 words phrase of your wallet",
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
                        child: Container(
                          width: size.width * 0.8,
                          height: 200,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                lightPrimaryColor,
                                lightPrimaryColor,
                              ],
                            ),
                          ),
                          child: TextFormField(
                            style: const TextStyle(color: darkPrimaryColor),
                            validator: (val) {
                              if (val!.isEmpty) {
                                return 'Enter your seed phrase';
                              } else {
                                return null;
                              }
                            },
                            keyboardType: TextInputType.multiline,
                            maxLines: 1000,
                            onChanged: (val) {
                              setState(() {
                                userMnemonicPhrase = val;
                              });
                            },
                            decoration: InputDecoration(
                              errorBorder: const OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.red, width: 1.0),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: darkPrimaryColor, width: 1.0),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: darkPrimaryColor, width: 1.0),
                              ),
                              hintStyle: TextStyle(
                                  color: darkPrimaryColor.withOpacity(0.7)),
                              hintText: 'Seed phrase',
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: darkPrimaryColor, width: 1.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          error,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "Password",
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
                        "Enter password for your wallet",
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
                            return 'Enter your password';
                          } else {
                            return null;
                          }
                        },
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (val) {
                          setState(() {
                            password = val;
                          });
                        },
                        decoration: InputDecoration(
                          errorBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.0),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          hintStyle: TextStyle(
                              color: darkPrimaryColor.withOpacity(0.7)),
                          hintText: 'Password',
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
                            return 'Enter your name';
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
                          errorBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.0),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          hintStyle: TextStyle(
                              color: darkPrimaryColor.withOpacity(0.7)),
                          hintText: 'Name',
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                      Center(
                        child: RoundedButton(
                          pw: 250,
                          ph: 45,
                          text: 'IMPORT',
                          press: () async {
                            setState(() {
                              loading = true;
                            });
                            if (_formKey.currentState!.validate() &&
                                password != null &&
                                password!.isNotEmpty) {
                              if (validateMnemonic(userMnemonicPhrase!)) {
                                final seed =
                                    mnemonicToSeed(userMnemonicPhrase!);
                                final master = await ED25519_HD_KEY
                                    .getMasterKeyFromSeed(seed);
                                final privateKey = HEX.encode(master.key);
                                final publicKey =
                                    EthPrivateKey.fromHex(privateKey).address;

                                AndroidOptions _getAndroidOptions() =>
                                    const AndroidOptions(
                                      encryptedSharedPreferences: true,
                                    );
                                final storage = FlutterSecureStorage(
                                    aOptions: _getAndroidOptions());
                                String? lastWalletIndex;
                                if (!widget.isWelcomeScreen) {
                                  lastWalletIndex = await storage.read(
                                      key: "lastWalletIndex");
                                } else {
                                  lastWalletIndex = "1";
                                }

                                if (lastWalletIndex != null) {
                                  await SafeStorageService().addNewWallet(
                                      lastWalletIndex,
                                      privateKey,
                                      publicKey.toString(),
                                      password!,
                                      name);
                                }
                                if (widget.isWelcomeScreen) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }

                                Navigator.pop(context);
                              } else {
                                setState(() {
                                  loading = false;
                                  error = 'Incorrect credentials';
                                });
                              }
                            } else {
                              setState(() {
                                loading = false;
                                error = 'Incorrect seed phrase';
                              });
                            }
                            setState(() {
                                    loading = false;
                                  });
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
          );
  }
}
