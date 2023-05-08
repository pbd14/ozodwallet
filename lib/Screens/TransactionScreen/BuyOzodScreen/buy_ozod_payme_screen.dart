import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:http/http.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: must_be_immutable
class BuyOzodPaymeScreen extends StatefulWidget {
  String error;
  Web3Wallet wallet;
  Web3Client web3client;
  BuyOzodPaymeScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.wallet,
    required this.web3client,
  }) : super(key: key);

  @override
  State<BuyOzodPaymeScreen> createState() => _BuyOzodPaymeScreenState();
}

class _BuyOzodPaymeScreenState extends State<BuyOzodPaymeScreen> {
  bool loading = true;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  double amount = 0;

  List coins = [];

  // Web
  bool showWeb = false;
  String webUrl = '';
  WebViewController webViewController = WebViewController();
  Client httpClient = Client();

  // Pay Me
  String? cardNumber = "";
  String? cardMonth = "";
  String? cardYear = "";

  EtherAmount? balance;

  DocumentSnapshot? appDataPaymentOptions;

  Future<void> prepare() async {
    balance = await widget.web3client.getBalance(widget.wallet.valueAddress);

    appDataPaymentOptions = await FirebaseFirestore.instance
        .collection("app_data")
        .doc("payment_options")
        .get();

    if (mounted) {
      setState(() {
        loading = false;
      });
    } else {
      loading = false;
    }
  }

  @override
  void initState() {
    prepare();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
    return loading
        ?  LoadingScreen()
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
                  constraints: BoxConstraints(
                                  maxWidth: kIsWeb ? 600 : double.infinity),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: size.height * 0.05,
                        ),
                        Text(
                          "Buy UZSO via PayMe",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 45,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor,
                                darkPrimaryColor,
                              ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Jazzicon.getIconWidget(
                                  Jazzicon.getJazziconData(160,
                                      address: widget.wallet.publicKey),
                                  size: 25),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  widget.wallet.name,
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Text(
                          "Amount",
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

                        // Amount
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: secondaryColor, width: 1.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.only(
                              left: size.width * 0.1, right: size.width * 0.1),
                          child: Column(
                            children: [
                              TextFormField(
                                cursorColor: secondaryColor,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    overflow: TextOverflow.ellipsis,
                                    color: secondaryColor,
                                    fontSize: 60,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Enter amount';
                                  } else if (double.parse(val) < 1) {
                                    return 'Min 1 UZS0';
                                  } else if (double.parse(val) > 1000) {
                                    return 'Max 1000 UZS0';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    amount =
                                        val.isNotEmpty ? double.parse(val) : 0;
                                  });
                                },
                                decoration: InputDecoration(
                                    errorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 1.0),
                                    ),
                                    hintStyle: TextStyle(
                                      color: secondaryColor.withOpacity(0.7),
                                    ),
                                    hintText: "0.0",
                                    border: InputBorder.none),
                              ),
                              Text(
                                "UZSO",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                textAlign: TextAlign.end,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: secondaryColor,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 50),

                        // Cost
                        Text(
                          "Cost",
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
                        Container(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            (amount * 1000).toString() + " UZS",
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                overflow: TextOverflow.ellipsis,
                                color: secondaryColor,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // Pay Me
                        Center(
                          child: Container(
                            width: size.width * 0.8,
                            height: 400,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20.0),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  darkPrimaryColor,
                                  primaryColor,
                                ],
                              ),
                              // image: DecorationImage(
                              //     image: AssetImage(
                              //         "assets/images/card.png"),
                              //     fit: BoxFit.fill),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Powered by",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            color: secondaryColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Image.asset(
                                      "assets/images/payme.png",
                                      width: 80,
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                TextFormField(
                                  style: const TextStyle(color: secondaryColor),
                                  cursorColor: secondaryColor,
                                  validator: (val) {
                                    if (val!.isEmpty) {
                                      return 'Enter your card number';
                                    } else if (val.length < 12) {
                                      return 'Wrong card number';
                                    } else {
                                      return null;
                                    }
                                  },
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      cardNumber = val.trim();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    labelText: "Card Number",
                                    labelStyle: TextStyle(color: secondaryColor),
                                    errorBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: Colors.red, width: 1.0),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: secondaryColor, width: 1.0),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: secondaryColor, width: 1.0),
                                    ),
                                    hintStyle: TextStyle(
                                        color: secondaryColor.withOpacity(0.7)),
                                    hintText: 'Card number',
                                    border: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: secondaryColor, width: 1.0),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Container(
                                      width: 100,
                                      child: TextFormField(
                                        cursorColor: secondaryColor,
                                        style: const TextStyle(
                                            color: secondaryColor),
                                        validator: (val) {
                                          if (val!.isEmpty) {
                                            return 'Enter expiration date';
                                          } else if (val.length != 2) {
                                            return 'Only 2 numbers';
                                          } else {
                                            return null;
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {
                                            cardMonth = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Month",
                                          labelStyle:
                                              TextStyle(color: secondaryColor),
                                          errorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 1.0),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                          enabledBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                          hintStyle: TextStyle(
                                              color: secondaryColor
                                                  .withOpacity(0.7)),
                                          hintText: 'Month',
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 2.5,
                                    ),
                                    Text(
                                      "/",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: secondaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 2.5,
                                    ),
                                    Container(
                                      width: 100,
                                      child: TextFormField(
                                        cursorColor: secondaryColor,
                                        style: const TextStyle(
                                            color: secondaryColor),
                                        validator: (val) {
                                          if (val!.isEmpty) {
                                            return 'Enter expiration date';
                                          } else if (val.length != 2) {
                                            return 'Only two numbers';
                                          } else {
                                            return null;
                                          }
                                        },
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          setState(() {
                                            cardYear = val;
                                          });
                                        },
                                        decoration: InputDecoration(
                                          labelText: "Year",
                                          labelStyle:
                                              TextStyle(color: secondaryColor),
                                          errorBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.red, width: 1.0),
                                          ),
                                          focusedBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                          enabledBorder: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                          hintStyle: TextStyle(
                                              color: secondaryColor
                                                  .withOpacity(0.7)),
                                          hintText: 'Year',
                                          border: const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: secondaryColor,
                                                width: 1.0),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 30,
                                ),
                                RoundedButton(
                                  pw: 250,
                                  ph: 45,
                                  text: 'Buy UZSO',
                                  press: () async {
                                    if (_formKey.currentState!.validate()) {
                                      String notificationTitle = "Success";
                                      String notificationBody = "Payment made";
                                      Color notificaitonColor = greenColor;
                                      bool paymentMade = false;
                                      setState(() {
                                        loading = true;
                                      });

                                      // Create card
                                      String cardToken = await cardsCreate();
                                      if (cardToken.isEmpty) {
                                        notificationTitle = "Failed";
                                        notificationBody =
                                            "Wrong card credentials";
                                        notificaitonColor = Colors.red;
                                        endPayment(
                                            notificationTitle,
                                            notificationBody,
                                            notificaitonColor,
                                            paymentMade);
                                      } else {
                                        // Get Verif code
                                        Map cardGetVerify =
                                            await cardsGetVerifyCode(cardToken);
                                        if (!cardGetVerify['sent']) {
                                          notificationTitle = "Failed";
                                          notificationBody =
                                              "Failed to send code";
                                          notificaitonColor = Colors.red;
                                          endPayment(
                                              notificationTitle,
                                              notificationBody,
                                              notificaitonColor,
                                              paymentMade);
                                        } else {
                                          String verifCode = "";
                                          // Get code
                                          showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (BuildContext context) {
                                                return StatefulBuilder(
                                                  builder: (context,
                                                      StateSetter setState) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          darkPrimaryColor,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20.0),
                                                      ),
                                                      title: const Text(
                                                        'Enter code',
                                                        style: TextStyle(
                                                            color:
                                                                secondaryColor),
                                                      ),
                                                      content:
                                                          SingleChildScrollView(
                                                        child: Container(
                                                          margin:
                                                              EdgeInsets.all(10),
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                "Enter the code that was sent to your phone ${cardGetVerify['phone']}",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 1000,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      const TextStyle(
                                                                    color:
                                                                        secondaryColor,
                                                                    fontSize: 20,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 20,
                                                              ),
                                                              TextFormField(
                                                                cursorColor:
                                                                    secondaryColor,
                                                                style: const TextStyle(
                                                                    color:
                                                                        secondaryColor),
                                                                validator: (val) {
                                                                  if (val!
                                                                      .isEmpty) {
                                                                    return 'Enter code';
                                                                  } else {
                                                                    return null;
                                                                  }
                                                                },
                                                                keyboardType:
                                                                    TextInputType
                                                                        .number,
                                                                onChanged: (val) {
                                                                  setState(() {
                                                                    verifCode =
                                                                        val;
                                                                  });
                                                                },
                                                                decoration:
                                                                    InputDecoration(
                                                                  labelText:
                                                                      "Code",
                                                                  labelStyle:
                                                                      TextStyle(
                                                                          color:
                                                                              secondaryColor),
                                                                  errorBorder:
                                                                      const OutlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                        color: Colors
                                                                            .red,
                                                                        width:
                                                                            1.0),
                                                                  ),
                                                                  focusedBorder:
                                                                      const OutlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                secondaryColor,
                                                                            width:
                                                                                1.0),
                                                                  ),
                                                                  enabledBorder:
                                                                      const OutlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                secondaryColor,
                                                                            width:
                                                                                1.0),
                                                                  ),
                                                                  hintStyle: TextStyle(
                                                                      color: secondaryColor
                                                                          .withOpacity(
                                                                              0.7)),
                                                                  hintText:
                                                                      'Code',
                                                                  border:
                                                                      const OutlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                secondaryColor,
                                                                            width:
                                                                                1.0),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () async {
                                                            setState(() {
                                                              loading = true;
                                                            });
                                                            Navigator.of(context)
                                                                .pop(false);
                                                            if (verifCode
                                                                .isEmpty) {
                                                              notificationTitle =
                                                                  "Failed";
                                                              notificationBody =
                                                                  "Wrong SMS code";
                                                              notificaitonColor =
                                                                  Colors.red;
                                                              endPayment(
                                                                  notificationTitle,
                                                                  notificationBody,
                                                                  notificaitonColor,
                                                                  paymentMade);
                                                            } else {
                                                              bool cardVerify =
                                                                  await cardsVerify(
                                                                      cardToken,
                                                                      verifCode);
                                                              if (!cardVerify) {
                                                                notificationTitle =
                                                                    "Failed";
                                                                notificationBody =
                                                                    "Wrong SMS code";
                                                                notificaitonColor =
                                                                    Colors.red;
                                                                endPayment(
                                                                    notificationTitle,
                                                                    notificationBody,
                                                                    notificaitonColor,
                                                                    paymentMade);
                                                              } else {
                                                                String receiptId =
                                                                    await receiptsCreate(
                                                                        cardToken);
                                                                if (receiptId
                                                                    .isEmpty) {
                                                                  notificationTitle =
                                                                      "Failed";
                                                                  notificationBody =
                                                                      "Payment Failed";
                                                                  notificaitonColor =
                                                                      Colors.red;
                                                                  endPayment(
                                                                      notificationTitle,
                                                                      notificationBody,
                                                                      notificaitonColor,
                                                                      paymentMade);
                                                                } else {
                                                                  String
                                                                      receiptState =
                                                                      await receiptsPay(
                                                                    receiptId,
                                                                    cardToken,
                                                                  );
                                                                  if (receiptState
                                                                      .isEmpty) {
                                                                    notificationTitle =
                                                                        "Failed";
                                                                    notificationBody =
                                                                        "Payment Failed";
                                                                    notificaitonColor =
                                                                        Colors
                                                                            .red;
                                                                    endPayment(
                                                                        notificationTitle,
                                                                        notificationBody,
                                                                        notificaitonColor,
                                                                        paymentMade);
                                                                  } else {
                                                                    if (receiptState !=
                                                                        "5") {
                                                                      notificationTitle =
                                                                          "Failed";
                                                                      notificationBody =
                                                                          "Payment Failed";
                                                                      notificaitonColor =
                                                                          Colors
                                                                              .red;
                                                                      endPayment(
                                                                          notificationTitle,
                                                                          notificationBody,
                                                                          notificaitonColor,
                                                                          paymentMade);
                                                                    } else {
                                                                      String
                                                                          // ignore: unused_local_variable
                                                                          receiptStateHold =
                                                                          await receiptsConfirmHold(
                                                                        receiptId,
                                                                      );
                                                                      if (receiptState !=
                                                                          "4") {
                                                                        notificationTitle =
                                                                            "Failed";
                                                                        notificationBody =
                                                                            "Payment Failed";
                                                                        notificaitonColor =
                                                                            Colors
                                                                                .red;
                                                                        endPayment(
                                                                            notificationTitle,
                                                                            notificationBody,
                                                                            notificaitonColor,
                                                                            paymentMade);
                                                                      } else {
                                                                        paymentMade =
                                                                            true;
                                                                      }
                                                                      endPayment(
                                                                          notificationTitle,
                                                                          notificationBody,
                                                                          notificaitonColor,
                                                                          paymentMade);
                                                                    }
                                                                  }
                                                                }
                                                              }
                                                            }
                                                          },
                                                          child: const Text(
                                                            'Ok',
                                                            style: TextStyle(
                                                                color:
                                                                    secondaryColor),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              });
                                        }
                                      }
                                    }
                                  },
                                  color: secondaryColor,
                                  textColor: darkPrimaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
  }

  // PAY ME FUNCTIONS
  Future<String> cardsCreate() async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        'id': 250,
        "method": "cards.create",
        "params": {
          "card": {"number": cardNumber, "expire": "${cardMonth}${cardYear}"},
          "save": true
        },
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    String result = "";
    try {
      result = decodedResponse['result']['card']['token'];
    } catch (e) {
      result = "";
    }


    return result;
  }

  Future<Map> cardsGetVerifyCode(String token) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        "id": 250,
        "method": "cards.get_verify_code",
        "params": {
          "token": token,
        }
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    Map result = {};
    try {
      result = {
        'sent': decodedResponse['result']['sent'],
        'phone': decodedResponse['result']['phone'],
      };
    } catch (e) {
      result = {};
    }


    return result;
  }

  Future<bool> cardsVerify(String token, String code) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        "id": 250,
        "method": "cards.verify",
        "params": {"token": token, "code": code}
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    bool result = false;
    try {
      result = decodedResponse['result']['card']['verify'];
    } catch (e) {
      result = false;
    }

    // print(decodedResponse['result']['card']);

    return result;
  }

  Future<String> receiptsCreate(String token) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        "id": 250,
        "method": "receipts.create",
        "params": {
          "amount": amount * 1000 * 100,
          "hold": true,
          "account": {"order_id": "ozod"},
          "detail": {
            "receipt_type": 0,
            // "shipping": {"title": "Доставка до ттз-4 28/23", "price": 500000},
            "items": [
              {
                // "discount": 0, //Скидка с учетом количества товаров или услуг в тийинах
                "title": "UZSO",
                "price": 1000,
                "count": amount,
                "code": "00702001001000001", // TO DO
                // "units": 241092,
                "vat_percent": 15,
                "package_code": "123456"
              }
            ]
          }
        }
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    String result = "";
    try {
      result = decodedResponse['result']['receipt']['_id'];
    } catch (e) {
      result = "";
    }
    return result;
  }

  Future<String> receiptsPay(String receiptId, String token) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        "id": 123,
        "method": "receipts.pay",
        "params": {
          "id": receiptId,
          "token": token,
          "hold": true,
          // "payer": {"phone": "998912345678"}
        },
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    String result = "";
    try {
      result = decodedResponse['result']['receipt']['state'];
    } catch (e) {
      result = "";
    }
    return result;
  }

  Future<String> receiptsConfirmHold(String receiptId) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('payme')['endpoint']),
      headers: <String, String>{
        'X-Auth': appDataPaymentOptions!.get('payme')['id'],
        'Content-Type': 'application/json',
        'Cache-Control': 'no-cache',
      },
      body: jsonEncode({
        "id": 123,
        "method": "receipts.confirm_hold",
        "params": {
          "id": receiptId,
        },
      }),
    );
    dynamic decodedResponse = jsonDecode(responseBalance.body);
    String result = "";
    try {
      result = decodedResponse['result']['receipt']['state'];
    } catch (e) {
      result = "";
    }
    return result;
  }

  void endPayment(String notificationTitle, String notificationBody,
      Color notificaitonColor, bool paymentMade) {
    
     showNotification(notificationTitle,notificationBody,notificaitonColor);
    if (paymentMade) {
      Navigator.pop(context);
    }
    setState(() {
      loading = false;
    });
  }
}
