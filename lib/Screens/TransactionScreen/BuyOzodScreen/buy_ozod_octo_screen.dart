import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
import 'package:web3dart/contracts.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:webview_flutter/webview_flutter.dart';

// ignore: must_be_immutable
class BuyOzodOctoScreen extends StatefulWidget {
  String error;
  Web3Wallet wallet;
  String selectedNetworkId;
  DeployedContract contract;
  web3.Web3Client web3client;
  BuyOzodOctoScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.wallet,
    required this.web3client,
    required this.contract,
    required this.selectedNetworkId,
  }) : super(key: key);

  @override
  State<BuyOzodOctoScreen> createState() => _BuyOzodOctoScreenState();
}

class _BuyOzodOctoScreenState extends State<BuyOzodOctoScreen> {
  bool loading = true;
  bool loading1 = false;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  double amount = 10;

  List coins = [];

  // Web
  bool showWeb = false;
  WebViewController webViewController = WebViewController();
  Client httpClient = Client();

  // Octo
  String? cardNumber = "";
  String? cardMonth = "";
  String? cardYear = "";
  String? cardholderName = "";
  String? cvc = "";
  String? email = "";
  String? octoPaymentId;

  web3.EtherAmount? balance;

  DocumentSnapshot? appDataPaymentOptions;
  DocumentSnapshot? appData;
  DocumentSnapshot? appDataApi;
  int paymentId = DateTime.now().millisecondsSinceEpoch;

  Future<void> prepare() async {
    balance = await widget.web3client.getBalance(widget.wallet.valueAddress);

    appDataPaymentOptions = await FirebaseFirestore.instance
        .collection("app_data")
        .doc("payment_options")
        .get();

    appData = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('data')
        .get();

    appDataApi = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('api')
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
            body: Stack(
              children: [
                SingleChildScrollView(
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
                              "Buy UZSO via Octo",
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    darkPrimaryColor,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              height: 30,
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
                              height: 10,
                            ),

                            // Amount
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: secondaryColor, width: 1.0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.all(10),
                              margin: EdgeInsets.only(
                                  left: size.width * 0.1,
                                  right: size.width * 0.1),
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
                                        amount = val.isNotEmpty
                                            ? double.parse(val)
                                            : 0;
                                      });
                                    },
                                    decoration: InputDecoration(
                                        errorBorder: const OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Colors.red, width: 1.0),
                                        ),
                                        hintStyle: TextStyle(
                                          color:
                                              secondaryColor.withOpacity(0.7),
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
                            const SizedBox(height: 30),

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
                            const SizedBox(height: 30),

                            // Octo
                            if (!showWeb)
                              Center(
                                child: Container(
                                  width: size.width * 0.8,
                                  height: 300,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            "assets/images/octo.png",
                                            width: 80,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),

                                      Text(
                                        "Please press the button below and complete payment through octo",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 10,
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            color: secondaryColor,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      // TextFormField(
                                      //   style:
                                      //       const TextStyle(color: secondaryColor),
                                      //   cursorColor: secondaryColor,
                                      //   validator: (val) {
                                      //     if (val!.isEmpty) {
                                      //       return 'Enter your card number';
                                      //     } else if (val.length < 12) {
                                      //       return 'Wrong card number';
                                      //     } else {
                                      //       return null;
                                      //     }
                                      //   },
                                      //   keyboardType: TextInputType.number,
                                      //   onChanged: (val) {
                                      //     setState(() {
                                      //       cardNumber = val.trim();
                                      //     });
                                      //   },
                                      //   decoration: InputDecoration(
                                      //     labelText: "Card Number",
                                      //     labelStyle:
                                      //         TextStyle(color: secondaryColor),
                                      //     errorBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: Colors.red, width: 1.0),
                                      //     ),
                                      //     focusedBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     enabledBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     hintStyle: TextStyle(
                                      //         color:
                                      //             secondaryColor.withOpacity(0.7)),
                                      //     hintText: 'Card number',
                                      //     border: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //   ),
                                      // ),
                                      // SizedBox(
                                      //   height: 20,
                                      // ),
                                      // Row(
                                      //   mainAxisAlignment:
                                      //       MainAxisAlignment.spaceEvenly,
                                      //   children: [
                                      //     Container(
                                      //       width: 100,
                                      //       child: TextFormField(
                                      //         cursorColor: secondaryColor,
                                      //         style: const TextStyle(
                                      //             color: secondaryColor),
                                      //         validator: (val) {
                                      //           if (val!.isEmpty) {
                                      //             return 'Enter expiration date';
                                      //           } else if (val.length != 2) {
                                      //             return 'Only 2 numbers';
                                      //           } else {
                                      //             return null;
                                      //           }
                                      //         },
                                      //         keyboardType: TextInputType.number,
                                      //         onChanged: (val) {
                                      //           setState(() {
                                      //             cardMonth = val;
                                      //           });
                                      //         },
                                      //         decoration: InputDecoration(
                                      //           labelText: "Month",
                                      //           labelStyle: TextStyle(
                                      //               color: secondaryColor),
                                      //           errorBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: Colors.red,
                                      //                 width: 1.0),
                                      //           ),
                                      //           focusedBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //           enabledBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //           hintStyle: TextStyle(
                                      //               color: secondaryColor
                                      //                   .withOpacity(0.7)),
                                      //           hintText: 'Month',
                                      //           border: const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     SizedBox(
                                      //       width: 2.5,
                                      //     ),
                                      //     Text(
                                      //       "/",
                                      //       overflow: TextOverflow.ellipsis,
                                      //       maxLines: 3,
                                      //       textAlign: TextAlign.start,
                                      //       style: GoogleFonts.montserrat(
                                      //         textStyle: const TextStyle(
                                      //           color: secondaryColor,
                                      //           fontSize: 15,
                                      //           fontWeight: FontWeight.w700,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //     SizedBox(
                                      //       width: 2.5,
                                      //     ),
                                      //     Container(
                                      //       width: 100,
                                      //       child: TextFormField(
                                      //         cursorColor: secondaryColor,
                                      //         style: const TextStyle(
                                      //             color: secondaryColor),
                                      //         validator: (val) {
                                      //           if (val!.isEmpty) {
                                      //             return 'Enter expiration date';
                                      //           } else if (val.length != 2) {
                                      //             return 'Only two numbers';
                                      //           } else {
                                      //             return null;
                                      //           }
                                      //         },
                                      //         keyboardType: TextInputType.number,
                                      //         onChanged: (val) {
                                      //           setState(() {
                                      //             cardYear = val;
                                      //           });
                                      //         },
                                      //         decoration: InputDecoration(
                                      //           labelText: "Year",
                                      //           labelStyle: TextStyle(
                                      //               color: secondaryColor),
                                      //           errorBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: Colors.red,
                                      //                 width: 1.0),
                                      //           ),
                                      //           focusedBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //           enabledBorder:
                                      //               const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //           hintStyle: TextStyle(
                                      //               color: secondaryColor
                                      //                   .withOpacity(0.7)),
                                      //           hintText: 'Year',
                                      //           border: const OutlineInputBorder(
                                      //             borderSide: BorderSide(
                                      //                 color: secondaryColor,
                                      //                 width: 1.0),
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ],
                                      // ),
                                      // SizedBox(
                                      //   height: 20,
                                      // ),
                                      // TextFormField(
                                      //   style:
                                      //       const TextStyle(color: secondaryColor),
                                      //   cursorColor: secondaryColor,
                                      //   validator: (val) {
                                      //     if (val!.isEmpty) {
                                      //       return 'Enter name on your card';
                                      //     } else {
                                      //       return null;
                                      //     }
                                      //   },
                                      //   keyboardType: TextInputType.name,
                                      //   onChanged: (val) {
                                      //     setState(() {
                                      //       cardholderName = val;
                                      //     });
                                      //   },
                                      //   decoration: InputDecoration(
                                      //     labelText: "Name",
                                      //     labelStyle:
                                      //         TextStyle(color: secondaryColor),
                                      //     errorBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: Colors.red, width: 1.0),
                                      //     ),
                                      //     focusedBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     enabledBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     hintStyle: TextStyle(
                                      //         color:
                                      //             secondaryColor.withOpacity(0.7)),
                                      //     hintText: 'Name on card',
                                      //     border: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //   ),
                                      // ),
                                      // SizedBox(
                                      //   height: 20,
                                      // ),
                                      // TextFormField(
                                      //   style:
                                      //       const TextStyle(color: secondaryColor),
                                      //   cursorColor: secondaryColor,
                                      //   validator: (val) {
                                      //     if (val!.isEmpty) {
                                      //       return 'Enter CVC';
                                      //     } else if (val.length != 3) {
                                      //       return 'Wrong CVC';
                                      //     } else {
                                      //       return null;
                                      //     }
                                      //   },
                                      //   keyboardType: TextInputType.number,
                                      //   onChanged: (val) {
                                      //     setState(() {
                                      //       cvc = val;
                                      //     });
                                      //   },
                                      //   decoration: InputDecoration(
                                      //     labelText: "CVC",
                                      //     labelStyle:
                                      //         TextStyle(color: secondaryColor),
                                      //     errorBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: Colors.red, width: 1.0),
                                      //     ),
                                      //     focusedBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     enabledBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     hintStyle: TextStyle(
                                      //         color:
                                      //             secondaryColor.withOpacity(0.7)),
                                      //     hintText: 'CVC',
                                      //     border: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //   ),
                                      // ),
                                      // SizedBox(
                                      //   height: 20,
                                      // ),
                                      // TextFormField(
                                      //   style:
                                      //       const TextStyle(color: secondaryColor),
                                      //   cursorColor: secondaryColor,
                                      //   validator: (val) {
                                      //     if (val!.isEmpty) {
                                      //       return 'Enter Email';
                                      //     } else {
                                      //       return null;
                                      //     }
                                      //   },
                                      //   keyboardType: TextInputType.emailAddress,
                                      //   onChanged: (val) {
                                      //     setState(() {
                                      //       email = val;
                                      //     });
                                      //   },
                                      //   decoration: InputDecoration(
                                      //     labelText: "Email",
                                      //     labelStyle:
                                      //         TextStyle(color: secondaryColor),
                                      //     errorBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: Colors.red, width: 1.0),
                                      //     ),
                                      //     focusedBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     enabledBorder: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //     hintStyle: TextStyle(
                                      //         color:
                                      //             secondaryColor.withOpacity(0.7)),
                                      //     hintText: 'Email',
                                      //     border: const OutlineInputBorder(
                                      //       borderSide: BorderSide(
                                      //           color: secondaryColor, width: 1.0),
                                      //     ),
                                      //   ),
                                      // ),

                                      SizedBox(
                                        height: 30,
                                      ),
                                      Center(
                                        child: RoundedButton(
                                          pw: 250,
                                          ph: 45,
                                          text: 'Buy UZSO',
                                          press: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              String notificationTitle =
                                                  "Success";
                                              String notificationBody =
                                                  "Payment made";
                                              Color notificaitonColor =
                                                  greenColor;
                                              bool paymentMade = false;
                                              setState(() {
                                                loading1 = true;
                                              });

                                              Map preparePaymentResult =
                                                  await preparePayment();
                                              if (preparePaymentResult[
                                                      'error'] !=
                                                  0) {
                                                notificationTitle = "Failed";
                                                notificationBody =
                                                    "Error. Try later again";
                                                notificaitonColor = Colors.red;
                                                endPayment(
                                                    notificationTitle,
                                                    notificationBody,
                                                    notificaitonColor,
                                                    paymentMade);
                                              } else {
                                                octoPaymentId =
                                                    preparePaymentResult[
                                                        'octo_payment_UUID'];
                                                Map payResult =
                                                    await pay(octoPaymentId!);
                                                if (payResult['error'] != 0 &&
                                                    payResult['error'] != 5) {
                                                  notificationTitle = "Failed";
                                                  notificationBody =
                                                      "Error. Try later again";
                                                  notificaitonColor =
                                                      Colors.red;
                                                  endPayment(
                                                      notificationTitle,
                                                      notificationBody,
                                                      notificaitonColor,
                                                      paymentMade);
                                                } else {
                                                  webViewController =
                                                      WebViewController()
                                                        ..setJavaScriptMode(
                                                            JavaScriptMode
                                                                .unrestricted)
                                                        ..setBackgroundColor(
                                                            const Color(
                                                                0x00000000))
                                                        ..setNavigationDelegate(
                                                          NavigationDelegate(
                                                            onProgress:
                                                                (int progress) {
                                                              // Update loading bar.
                                                            },
                                                            onPageStarted:
                                                                (String url) {},
                                                            onPageFinished:
                                                                (String url) {},
                                                            onWebResourceError:
                                                                (WebResourceError
                                                                    error) {},
                                                            onNavigationRequest:
                                                                (NavigationRequest
                                                                    request) {
                                                              if (request.url
                                                                  .startsWith(
                                                                      'https://www.youtube.com/')) {
                                                                return NavigationDecision
                                                                    .prevent;
                                                              }
                                                              return NavigationDecision
                                                                  .navigate;
                                                            },
                                                          ),
                                                        )
                                                        ..loadRequest(Uri.parse(payResult[
                                                                    'error'] ==
                                                                5
                                                            ? preparePaymentResult[
                                                                'octo_pay_url']
                                                            : payResult['data'][
                                                                'redirectUrl']));
                                                  setState(() {
                                                    showWeb = true;
                                                    loading1 = false;
                                                  });
                                                }
                                              }

                                              setState(() {
                                                loading1 = false;
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

                            // WEB PAGE

                            const SizedBox(height: 30),
                            if (showWeb)
                              Text(
                                "Please complete payment in the OCTO below, and then confirm it, so we can accept your payment.",
                                overflow: TextOverflow.ellipsis,
                                maxLines: 10,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            if (showWeb) const SizedBox(height: 10),
                            if (showWeb)
                              Center(
                                child: RoundedButton(
                                  pw: 250,
                                  ph: 45,
                                  text: 'Confirm payment',
                                  press: () async {
                                    String notificationTitle = "Success";
                                    String notificationBody = "Payment made";
                                    Color notificaitonColor = greenColor;
                                    bool paymentMade = false;
                                    setState(() {
                                      loading1 = true;
                                    });

                                    Map preparePaymentResult =
                                        await preparePayment();
                                    if (preparePaymentResult['error'] == 0 &&
                                        preparePaymentResult['status'] !=
                                            "created" &&
                                        preparePaymentResult['status'] !=
                                            "canceled" &&
                                        preparePaymentResult['status'] !=
                                            "wait_user_action") {
                                      Map confirmPaymentResult =
                                          await confirmPayment(octoPaymentId!);
                                      if (confirmPaymentResult['error'] == 0 &&
                                          confirmPaymentResult['status'] ==
                                              "succeeded") {
                                        bool web3TransactionMade = true;
                                        int paymentStatusCode = 1;
                                        await FirebaseFirestore.instance
                                            .collection('payments')
                                            .doc(paymentId.toString())
                                            .set({
                                          "id": paymentId,
                                          "walletPublicKey": widget.wallet.publicKey,
                                          "status_code": paymentStatusCode,
                                          "amount": amount,
                                          "product": "UZSO",
                                          "method": "octo",
                                          "details": {
                                            "octo_shop_transaction_id":
                                                confirmPaymentResult[
                                                    'shop_transaction_id'],
                                            "octo_payment_UUID":
                                                confirmPaymentResult[
                                                    'octo_payment_UUID'],
                                          },
                                        });
                                        try {
                                          final resp = await FirebaseFunctions
                                              .instance
                                              .httpsCallable('mintToCustomer')
                                              .call({
                                            'to': widget.wallet.valueAddress
                                                .toString(),
                                            'amount': (BigInt.from(amount) *
                                                    BigInt.from(pow(10, 18)))
                                                .toString(),
                                            'paymentId': paymentId,
                                            'blockchainNetwork':
                                                widget.selectedNetworkId,
                                          });
                                          print("FUNCDATA");
                                          print(resp.data);
                                          switch (resp.data) {
                                            case "ERROR":
                                              notificationTitle = "Error";
                                              notificationBody =
                                                  "Servers are overloaded. Try again later";
                                              notificaitonColor = Colors.red;
                                              web3TransactionMade = false;
                                              paymentStatusCode = 1;
                                              break;
                                            case "NOT ENOUGH GAS":
                                              notificationTitle = "Error";
                                              notificationBody =
                                                  "Problems with gas. Try again later";
                                              notificaitonColor = Colors.red;
                                              web3TransactionMade = false;
                                              paymentStatusCode = 1;
                                              break;
                                            default:
                                              web3TransactionMade = true;
                                              paymentStatusCode = 2;
                                          }

                                          await FirebaseFirestore.instance
                                              .collection('payments')
                                              .doc(paymentId.toString())
                                              .update({
                                            "status_code": paymentStatusCode,
                                            "web3Transaction": resp.data,
                                          });
                                        } on FirebaseFunctionsException catch (e) {
                                          print('FIREBASE ERROR');
                                          print(e);
                                          notificationTitle = "Error";
                                          notificationBody =
                                              "Servers are overloaded. Please try again later";
                                          notificaitonColor = Colors.red;
                                          web3TransactionMade = false;
                                        }

                                        if (web3TransactionMade) {
                                          if (mounted) {
                                            setState(() {
                                              showWeb = false;
                                            });
                                          } else {
                                            showWeb = false;
                                          }
                                          paymentMade = true;
                                        }
                                        endPayment(
                                            notificationTitle,
                                            notificationBody,
                                            notificaitonColor,
                                            paymentMade);
                                        Navigator.of(context).pop(false);
                                      } else {
                                        notificationTitle = "Failed";
                                        notificationBody =
                                            "Payment failed. Try again";
                                        notificaitonColor = Colors.red;
                                        endPayment(
                                            notificationTitle,
                                            notificationBody,
                                            notificaitonColor,
                                            paymentMade);
                                      }
                                    } else {
                                      notificationTitle = "Failed";
                                      notificationBody =
                                          "Payment is not completed";
                                      notificaitonColor = Colors.red;
                                      endPayment(
                                          notificationTitle,
                                          notificationBody,
                                          notificaitonColor,
                                          paymentMade);
                                    }
                                    setState(() {
                                      loading1 = false;
                                    });
                                  },
                                  color: greenColor,
                                  textColor: whiteColor,
                                ),
                              ),
                            if (showWeb) const SizedBox(height: 20),

                            if (showWeb)
                              Container(
                                height: size.height * 1.1,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      darkPrimaryColor,
                                      primaryColor,
                                      secondaryColor
                                    ],
                                  ),
                                ),
                                child: WebViewWidget(
                                    controller: webViewController),
                              ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (loading1) LoadingScreen(),
              ],
            ),
          );
  }

  // OCTO FUNCTIONS
  Future<Map> preparePayment() async {
    final responseBalance = await httpClient.post(
      Uri.parse(
          appDataPaymentOptions!.get('octo')['endpoint'] + "/prepare_payment"),
      headers: <String, String>{
        // 'X-Auth': appDataPaymentOptions!.get('octo')['id'],
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "octo_shop_id": appDataPaymentOptions!.get('octo')['shop_id'],
        "octo_secret": appDataPaymentOptions!.get('octo')['octo_secret'],
        "shop_transaction_id": paymentId.toString(),
        "auto_capture": false,
        "test": true,
        "init_time": DateTime.now().toString(),
        "user_data": {
          "user_id": widget.wallet.publicKey,
          "phone": "",
          "email": email,
        },
        "total_sum": amount * 1000,
        "currency": "UZS",
        "tag": "ticket",
        "description": "UZS Ozod Coin",
        // "basket": [
        //   {
        //     "position_desc": "Йогурт MANON клубничный",
        //     "count": 2,
        //     "price": 33.99,
        //     "supplier_shop_id": 33
        //   },
        // ],
        "payment_methods": [
          {"method": "bank_card"},
          {"method": "uzcard"},
          {"method": "humo"},
        ],
        // "tsp_id": 18,
        "return_url": "https://ozod-loyalty.web.app/" + paymentId.toString(),
        "notify_url": "https://ozod-loyalty.web.app/",
        "language": "en",
        "ttl": 15
      }),
    );
    Map decodedResponse = jsonDecode(responseBalance.body);
    return decodedResponse;
  }

  Future<Map> pay(String octoPaymentId) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('octo')['endpoint'] +
          "/pay/${octoPaymentId}"),
      headers: <String, String>{
        // 'X-Auth': appDataPaymentOptions!.get('octo')['id'],
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "pan": cardNumber,
        "exp": "${cardYear}${cardMonth}",
        "cardHolderName": cardholderName,
        "cvc2": cvc,
        "email": email,
        "method": "bank_card"
      }),
    );
    Map decodedResponse = jsonDecode(responseBalance.body);
    return decodedResponse;
  }

  Future<Map> confirmPayment(String octoPaymentId) async {
    final responseBalance = await httpClient.post(
      Uri.parse(appDataPaymentOptions!.get('octo')['endpoint'] + "/set_accept"),
      headers: <String, String>{
        // 'X-Auth': appDataPaymentOptions!.get('octo')['id'],
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "octo_shop_id": appDataPaymentOptions!.get('octo')['shop_id'],
        "octo_secret": appDataPaymentOptions!.get('octo')['octo_secret'],
        "octo_payment_UUID": octoPaymentId,
        "accept_status": "capture"
      }),
    );
    Map decodedResponse = jsonDecode(responseBalance.body);

    return decodedResponse;
  }

  void endPayment(String notificationTitle, String notificationBody,
      Color notificaitonColor, bool paymentMade) {
    showNotification(notificationTitle, notificationBody, notificaitonColor);
    if (paymentMade) {
      // Navigator.pop(context);
    }
    setState(() {
      loading = false;
    });
  }
}
