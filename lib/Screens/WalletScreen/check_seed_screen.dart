import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bip39/bip39.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/credentials.dart';

// ignore: must_be_immutable
class CheckSeedScreen extends StatefulWidget {
  String error;
  String mnemonicPhrase;
  String password;
  String name;
  bool isWelcomeScreen;
  CheckSeedScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.mnemonicPhrase,
    required this.password,
    required this.name,
    this.isWelcomeScreen = true,
  }) : super(key: key);

  @override
  State<CheckSeedScreen> createState() => _CheckSeedScreenState();
}

class _CheckSeedScreenState extends State<CheckSeedScreen> {
  bool loading = true;
  final _formKey = GlobalKey<FormState>();
  String error = '';
  String? mnemonicPhrase;
  String? userMnemonicPhrase;
  bool showSeed = false;

  void prepare() {
    setState(() {
      mnemonicPhrase = widget.mnemonicPhrase;
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
                          height: size.height * 0.1,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(0.0),
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
                        Text(
                          "Check seed phrase",
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
                          "Please verify that you saved seed phrase. Type all words from phrase below",
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
                                } else if (val != mnemonicPhrase) {
                                  return 'Seed phrase is not correct';
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
                                errorBorder: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: darkPrimaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: darkPrimaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                hintStyle: TextStyle(
                                    color: darkPrimaryColor.withOpacity(0.7)),
                                hintText: 'Seed phrase',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: darkPrimaryColor, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        const SizedBox(height: 50),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'CONTINUE',
                            press: () async {
                              setState(() {
                                loading = true;
                              });
                              if (_formKey.currentState!.validate()) {
                                if (userMnemonicPhrase == mnemonicPhrase!) {
                                  if (validateMnemonic(mnemonicPhrase!)) {
                                    try {
                                      final seed =
                                          mnemonicToSeed(mnemonicPhrase!);
                                      final master = await ED25519_HD_KEY
                                          .getMasterKeyFromSeed(seed);
                                      final privateKey = HEX.encode(master.key);
                                      final publicKey =
                                          EthPrivateKey.fromHex(privateKey)
                                              .address;
                                      String? lastWalletIndex;
                                      lastWalletIndex =
                                          await SafeStorageService()
                                                  .storage
                                                  .read(
                                                      key: "lastWalletIndex") ??
                                              "1";

                                      await SafeStorageService().addNewWallet(
                                        Web3Wallet(
                                            privateKey: privateKey,
                                            publicKey: publicKey.toString(),
                                            name: widget.name,
                                            localIndex: lastWalletIndex),
                                      );

                                      // ignore: unused_local_variable
                                      Wallet wallet = Wallet.createNew(
                                          EthPrivateKey.fromHex(privateKey),
                                          widget.password,
                                          Random());

                                      await FirebaseFirestore.instance
                                          .collection('wallets')
                                          .doc(publicKey.toString())
                                          .set({
                                        'loyalty_programs': [],
                                        'publicKey': publicKey.toString(),
                                        'assets': [],
                                      });
                                      if (widget.isWelcomeScreen) {
                                        Navigator.pop(context);
                                      }

                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                    } catch (e) {
                                      setState(() {
                                        loading = false;
                                        error = 'Error. Try again later';
                                      });
                                      showNotification("Failed",
                                          'Error. Try again later', Colors.red);
                                    }
                                  } else {
                                    setState(() {
                                      loading = false;
                                      error = 'Failed to create wallet';
                                    });
                                    showNotification(
                                        "Failed",
                                        'Failed to create wallet. Try again later',
                                        Colors.red);
                                  }
                                } else {
                                  setState(() {
                                    loading = false;
                                    error = 'Seed phrase is not correct';
                                  });
                                  showNotification("Failed",
                                      'Seed phrase is not correct', Colors.red);
                                }
                              }
                              setState(() {
                                loading = false;
                              });
                            },
                            color: secondaryColor,
                            textColor: darkPrimaryColor,
                          ),
                        ),
                        const SizedBox(
                          height: 100,
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
