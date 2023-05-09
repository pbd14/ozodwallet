import 'package:bip39/bip39.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
  bool usingPrivateKey = false;
  String error = '';

  String? userMnemonicPhrase;
  String? password;
  String? privateKey;
  String name = "Wallet Name";
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Private key",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: secondaryColor,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              onChanged: (bool value) {
                                setState(() {
                                  usingPrivateKey = value;
                                });
                              },
                              activeColor: secondaryColor,
                              trackColor: lightPrimaryColor,
                              value: usingPrivateKey,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          usingPrivateKey ? "Private key" : "Seed phrase",
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
                          height: 10,
                        ),
                        Text(
                          usingPrivateKey
                              ? "Enter wallet private key"
                              : "Enter 12 words phrase of your wallet",
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
                        usingPrivateKey
                            ? TextFormField(
                                style: const TextStyle(color: secondaryColor),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Enter your private key';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (val) {
                                  setState(() {
                                    privateKey = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.red, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  hintStyle: TextStyle(
                                      color: darkPrimaryColor.withOpacity(0.7)),
                                  hintText: 'Private Key',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              )
                            : Center(
                                child: Container(
                                  width: size.width * 0.8,
                                  height: 200,
                                  padding: const EdgeInsets.all(15),
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
                                    style: const TextStyle(
                                        color: darkPrimaryColor),
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
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.red, width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      hintStyle: TextStyle(
                                          color: darkPrimaryColor
                                              .withOpacity(0.7)),
                                      hintText: 'Seed phrase',
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: darkPrimaryColor,
                                            width: 1.0),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                        const SizedBox(
                          height: 40,
                        ),
                        // Text(
                        //   "Password",
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
                        //   height: 10,
                        // ),
                        // Text(
                        //   "Enter password for your wallet",
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
                          height: 10,
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
                        const SizedBox(height: 40),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'IMPORT',
                            press: () async {
                              setState(() {
                                loading = true;
                              });
                              // if (_formKey.currentState!.validate() &&
                              //     password != null &&
                              //     password!.isNotEmpty
                              //     )
                              if (_formKey.currentState!.validate()) {
                                if (usingPrivateKey) {
                                  try {
                                    final walletPrivateKey = privateKey!;
                                    final publicKey =
                                        EthPrivateKey.fromHex(walletPrivateKey)
                                            .address;
                                    try {
                                      DocumentSnapshot firestoreWallet =
                                          await FirebaseFirestore.instance
                                              .collection('wallets')
                                              .doc(publicKey.toString())
                                              .get();
                                      if (!firestoreWallet.exists) {
                                        await FirebaseFirestore.instance
                                            .collection('wallets')
                                            .doc(publicKey.toString())
                                            .set({
                                          'loyalty_programs': [],
                                          'publicKey': publicKey.toString(),
                                          'assets': [],
                                        });
                                      }
                                    } catch (e) {
                                      await FirebaseFirestore.instance
                                          .collection('wallets')
                                          .doc(publicKey.toString())
                                          .set({
                                        'loyalty_programs': [],
                                        'publicKey': publicKey.toString(),
                                        'assets': [],
                                      });
                                    }
                                    String? lastWalletIndex;
                                    lastWalletIndex = await SafeStorageService().storage.read(
                                            key: "lastWalletIndex") ??
                                        "1";
                                    await SafeStorageService().addNewWallet(
                                        Web3Wallet(
                                            privateKey: walletPrivateKey,
                                            publicKey: publicKey.toString(),
                                            name: name,
                                            localIndex: lastWalletIndex));
                                    if (widget.isWelcomeScreen) {
                                      Navigator.pop(context);
                                    }
                                    Navigator.pop(context);
                                  } catch (e) {
                                    print("ERROR: $e");
                                    setState(() {
                                      loading = false;
                                      error = 'Error. Try again later';
                                    });
                                    showNotification("Failed",
                                        'Error. Try again later', Colors.red);
                                  }
                                } else {
                                  try {
                                    if (validateMnemonic(userMnemonicPhrase!)) {
                                      final seed =
                                          mnemonicToSeed(userMnemonicPhrase!);
                                      final master = await ED25519_HD_KEY
                                          .getMasterKeyFromSeed(seed);
                                      final walletPrivateKey =
                                          HEX.encode(master.key);
                                      final publicKey = EthPrivateKey.fromHex(
                                              walletPrivateKey)
                                          .address;

                                      await FirebaseFirestore.instance
                                          .collection('wallets')
                                          .doc(publicKey.toString())
                                          .set({
                                        'loyalty_programs': [],
                                        'publicKey': publicKey.toString(),
                                        'assets': [],
                                      });

                                      String? lastWalletIndex;
                                      if (!widget.isWelcomeScreen) {
                                        lastWalletIndex = await SafeStorageService().storage.read(
                                            key: "lastWalletIndex");
                                      } else {
                                        lastWalletIndex = "1";
                                      }

                                      if (lastWalletIndex != null) {
                                        await SafeStorageService().addNewWallet(
                                          Web3Wallet(
                                              privateKey: walletPrivateKey,
                                              publicKey: publicKey.toString(),
                                              name: name,
                                              localIndex: lastWalletIndex),
                                        );
                                      }

                                      showNotification("Success",
                                    'Wallet imported', greenColor);
                                      if (widget.isWelcomeScreen) {
                                        Navigator.pop(context);
                                      }

                                      Navigator.pop(context);
                                    } else {
                                      setState(() {
                                        loading = false;
                                        error = 'Incorrect seed phrase';
                                      });
                                      showNotification("Failed",
                                          'Incorrect seed phrase', Colors.red);
                                    }
                                  } catch (e) {
                                    setState(() {
                                      loading = false;
                                      error = 'Error. Try again later';
                                    });
                                    showNotification("Failed",
                                        'Error. Try again later', Colors.red);
                                  }
                                }
                              } else {
                                setState(() {
                                  loading = false;
                                  error = 'Incorrect credentials';
                                });
                                showNotification("Failed",
                                    'Incorrect credentials', Colors.red);
                              }
                              setState(() {
                                loading = false;
                              });
                            },
                            color: secondaryColor,
                            textColor: darkPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 300),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }
}
