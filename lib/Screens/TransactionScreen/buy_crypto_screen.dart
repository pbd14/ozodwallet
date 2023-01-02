import 'dart:convert';
import 'dart:io';
import 'package:bip39/bip39.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Screens/WalletScreen/check_seed_screen.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
import 'package:ozodwallet/Services/exchanges/mercury_api_service.dart';
import 'package:ozodwallet/Services/exchanges/simpleswap_api_service.dart';
import 'package:ozodwallet/Services/exchanges/swapzone_api_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: must_be_immutable
class BuyCryptoScreen extends StatefulWidget {
  String error;
  String walletIndex;
  Web3Client web3client;
  BuyCryptoScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.walletIndex,
    required this.web3client,
  }) : super(key: key);

  @override
  State<BuyCryptoScreen> createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  bool loading = true;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  double amount = 0;

  List coins = [];

  // Web
  bool showWeb = false;
  String webUrl = '';
  WebViewController webViewController = WebViewController();

  // Exchanges
  // Map<String, Map> exchanges = {
  //   'simpleswap': {
  //     'name': 'SimpleSwap',
  //     'image':
  //         'https://images.g2crowd.com/uploads/product/image/large_detail/large_detail_652890b0859641a280e40ecba8c92e0f/simpleswap.png',
  //     'exchange_link':
  //         'https://simpleswap.io/?cur_from=btc&cur_to=eth&amount=0.1&ref=a8e65f24b017',
  //   },
  //   'mercuryo': {
  //     'name': 'Mercuryo',
  //     'image':
  //         'https://raw.githubusercontent.com/mercuryoio/iOS-SDK/main/images/logo.png',
  //     'exchange_link': 'https://exchange.mercuryo.io/'
  //   },
  //   'swapzone': {
  //     'name': 'Swapzone',
  //     'image':
  //         'https://blockspot-io.b-cdn.net/wp-content/uploads/swapzone-exchange-logo.png'
  //   },
  // };
  List<String> possibleExchanges = [];
  // Swapzone
  List swapzone_coins = [];

  Map selectedCoin = {};
  Map selectedExchange = {};
  Map walletData = {};
  EtherAmount? balance;
  DocumentSnapshot? appData;
  DocumentSnapshot? appDataExchanges;

  void getPossibleExchanges() {
    possibleExchanges.clear();
    selectedExchange = {};
    // Mercuryo
    if (MercuryoApiService().checkCoinForFiat(selectedCoin['symbol'])) {
      if (mounted) {
        setState(() {
          possibleExchanges.add('mercuryo');
          selectedExchange = appDataExchanges!.get('mercuryo');
          appDataExchanges!.get('mercuryo')['exchange_link'] =
              'https://exchange.mercuryo.io/?currency=${selectedCoin['symbol']}&fiat_currency=USD';
          webUrl = appDataExchanges!.get('mercuryo')!['exchange_link'];
        });
      } else {
        possibleExchanges.add('mercuryo');
        selectedExchange = appDataExchanges!.get('mercuryo');
        webUrl = appDataExchanges!.get('mercuryo')['exchange_link'];
      }
    }

    // SimpleSwap
    if (SimpleswapApiService().checkCoinForFiat(selectedCoin['symbol'])) {
      if (mounted) {
        setState(() {
          possibleExchanges.add('simpleswap');
          selectedExchange = appDataExchanges!.get('simpleswap');
          webUrl = appDataExchanges!.get('simpleswap')['exchange_link'];
        });
      } else {
        possibleExchanges.add('simpleswap');
        selectedExchange = appDataExchanges!.get('simpleswap');
        webUrl = appDataExchanges!.get('simpleswap')['exchange_link'];
      }
    }
  }

  Future<void> prepare() async {
    // get app data
    appData = await FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('data')
        .get();
    appDataExchanges = await FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('exchanges')
        .get();
    walletData = await SafeStorageService().getWalletData(widget.walletIndex);
    balance = await widget.web3client.getBalance(walletData['address']);
    coins = json.decode(appData!.get('ETHER_TOP20_COINS_JSON'));
    selectedCoin = coins[0];
    getPossibleExchanges();
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
    Size size = MediaQuery.of(context).size;
    return loading
        ? const LoadingScreen()
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
              child: Container(
                margin: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: size.height * 0.05,
                      ),
                      Text(
                        "Buy Crypto",
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Jazzicon.getIconWidget(
                                Jazzicon.getJazziconData(160,
                                    address: walletData['publicKey']),
                                size: 25),
                            SizedBox(width: 10,),
                            Expanded(
                              child: Text(
                                walletData['name'],
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
                        "Coin",
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
                      const SizedBox(
                        height: 20,
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<int>(
                          isDense: false,
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                            hintStyle: TextStyle(
                                color: darkPrimaryColor.withOpacity(0.7)),
                            hintText: 'Coin',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                          ),
                          menuMaxHeight: 200,
                          borderRadius: BorderRadius.circular(40.0),
                          dropdownColor: darkPrimaryColor,
                          focusColor: whiteColor,
                          iconEnabledColor: secondaryColor,
                          alignment: Alignment.centerLeft,
                          onChanged: (coinId) async {
                            setState(() {
                              loading = true;
                            });

                            setState(() {
                              selectedCoin = coins[coinId!];
                            });
                            possibleExchanges = [];
                            getPossibleExchanges();
                            setState(() {
                              loading = false;
                            });
                          },
                          hint: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.network(
                                selectedCoin['image'],
                                width: 30,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                width: size.width * 0.6 - 20,
                                child: Text(
                                  selectedCoin['id']
                                          .substring(0, 1)
                                          .toUpperCase() +
                                      selectedCoin['id'].substring(1),
                                  overflow: TextOverflow.ellipsis,
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
                          items: [
                            for (Map coin in coins)
                              DropdownMenuItem<int>(
                                value: coins.indexOf(coin),
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Image + symbol
                                      Row(
                                        children: [
                                          Image.network(
                                            coin['image'],
                                            width: 30,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            coin['symbol'].toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: secondaryColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: size.width * 0.5 - 20,
                                        child: Text(
                                          coin['id']
                                                  .substring(0, 1)
                                                  .toUpperCase() +
                                              coin['id'].substring(1),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Text(
                      //   "Amount",
                      //   overflow: TextOverflow.ellipsis,
                      //   maxLines: 3,
                      //   textAlign: TextAlign.start,
                      //   style: GoogleFonts.montserrat(
                      //     textStyle: const TextStyle(
                      //       color: secondaryColor,
                      //       fontSize: 25,
                      //       fontWeight: FontWeight.w700,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: 50,
                      // ),

                      // // Amount
                      // Container(
                      //   margin: EdgeInsets.only(
                      //       left: size.width * 0.2,
                      //       right: size.width * 0.1 + 40),
                      //   child: TextFormField(
                      //     cursorColor: darkPrimaryColor,
                      //     textAlign: TextAlign.start,
                      //     style: GoogleFonts.montserrat(
                      //       textStyle: const TextStyle(
                      //         color: secondaryColor,
                      //         fontSize: 60,
                      //         fontWeight: FontWeight.w700,
                      //       ),
                      //     ),
                      //     validator: (val) {
                      //       if (val!.isEmpty) {
                      //         return 'Enter amount';
                      //       } else if (double.parse(val) < 50) {
                      //         return 'Min \$50';
                      //       } else {
                      //         return null;
                      //       }
                      //     },
                      //     keyboardType: TextInputType.number,
                      //     onChanged: (val) {
                      //       setState(() {
                      //         amount = double.parse(val);
                      //       });
                      //     },
                      //     decoration: InputDecoration(
                      //         prefix: Text(
                      //           "\$",
                      //           overflow: TextOverflow.ellipsis,
                      //           maxLines: 3,
                      //           textAlign: TextAlign.end,
                      //           style: GoogleFonts.montserrat(
                      //             textStyle: const TextStyle(
                      //               color: secondaryColor,
                      //               fontSize: 60,
                      //               fontWeight: FontWeight.w700,
                      //             ),
                      //           ),
                      //         ),
                      //         errorBorder: const OutlineInputBorder(
                      //           borderSide:
                      //               BorderSide(color: Colors.red, width: 1.0),
                      //         ),
                      //         hintStyle: TextStyle(
                      //           color: secondaryColor.withOpacity(0.7),
                      //         ),
                      //         hintText: "0.0",
                      //         border: InputBorder.none),
                      //   ),
                      // ),
                      // const SizedBox(
                      //   height: 10,
                      // ),
                      // Text(
                      //   exchangeName.substring(0, 1).toUpperCase() +
                      //       exchangeName.substring(1),
                      //   textAlign: TextAlign.center,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: GoogleFonts.montserrat(
                      //     textStyle: const TextStyle(
                      //       color: secondaryColor,
                      //       fontSize: 20,
                      //       fontWeight: FontWeight.w400,
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 30),

                      // // Exchange
                      DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          isDense: false,
                          decoration: InputDecoration(
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: Colors.red, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                            hintStyle: TextStyle(
                                color: darkPrimaryColor.withOpacity(0.7)),
                            hintText: 'Exchange',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(40.0),
                              borderSide:
                                  BorderSide(color: secondaryColor, width: 1.0),
                            ),
                          ),
                          menuMaxHeight: 200,
                          borderRadius: BorderRadius.circular(40.0),
                          dropdownColor: darkPrimaryColor,
                          focusColor: whiteColor,
                          iconEnabledColor: whiteColor,
                          alignment: Alignment.centerLeft,
                          onChanged: (exchangeName) {
                            setState(() {
                              webUrl = appDataExchanges!
                                  .get(exchangeName!)['exchange_link'];
                              selectedExchange =
                                  appDataExchanges!.get(exchangeName);
                            });
                          },
                          hint: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (selectedExchange.isNotEmpty)
                                Image.network(
                                  selectedExchange['image'],
                                  width: 30,
                                ),
                              SizedBox(
                                width: 10,
                              ),
                              Container(
                                width: size.width * 0.6 - 20,
                                child: Text(
                                  selectedExchange.isNotEmpty
                                      ? selectedExchange['name']
                                              .substring(0, 1)
                                              .toUpperCase() +
                                          selectedExchange['name'].substring(1)
                                      : 'N/A',
                                  overflow: TextOverflow.ellipsis,
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
                          items: [
                            for (String exchangeName in possibleExchanges)
                              DropdownMenuItem<String>(
                                value: exchangeName,
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Image.network(
                                        appDataExchanges!
                                            .get(exchangeName)['image'],
                                        width: 30,
                                      ),
                                      Container(
                                        width: size.width * 0.5 - 20,
                                        child: Text(
                                          exchangeName
                                                  .substring(0, 1)
                                                  .toUpperCase() +
                                              exchangeName.substring(1),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),
                      showWeb
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              margin: EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    primaryColor,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      walletData['publicKey'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 10,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: secondaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 30,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () async {
                                        await Clipboard.setData(ClipboardData(
                                            text: walletData['publicKey']));
                                        PushNotificationMessage notification =
                                            PushNotificationMessage(
                                          title: 'Copied',
                                          body: 'Public key copied',
                                        );
                                        showSimpleNotification(
                                          Text(notification.body),
                                          position: NotificationPosition.top,
                                          background: greenColor,
                                        );
                                      },
                                      icon: Icon(
                                        CupertinoIcons.doc,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      showWeb
                          ? Container(
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
                              child:
                                  WebViewWidget(controller: webViewController),
                            )
                          : Container(),
                      SizedBox(height: showWeb ? 50 : 0),
                      showWeb
                          ? Container()
                          : Center(
                              child: RoundedButton(
                                pw: 250,
                                ph: 45,
                                text: 'CONTINUE',
                                press: () async {
                                  setState(() {
                                    loading = true;
                                  });
                                  if (_formKey.currentState!.validate() &&
                                      possibleExchanges.isNotEmpty) {
                                    webViewController = WebViewController()
                                      ..setJavaScriptMode(
                                          JavaScriptMode.unrestricted)
                                      ..setBackgroundColor(
                                          const Color(0x00000000))
                                      ..setNavigationDelegate(
                                        NavigationDelegate(
                                          onProgress: (int progress) {
                                            // Update loading bar.
                                          },
                                          onPageStarted: (String url) {},
                                          onPageFinished: (String url) {},
                                          onWebResourceError:
                                              (WebResourceError error) {},
                                          onNavigationRequest:
                                              (NavigationRequest request) {
                                            if (request.url.startsWith(
                                                'https://www.youtube.com/')) {
                                              return NavigationDecision.prevent;
                                            }
                                            return NavigationDecision.navigate;
                                          },
                                        ),
                                      )
                                      ..loadRequest(Uri.parse(webUrl));
                                    setState(() {
                                      showWeb = true;
                                      loading = false;
                                    });
                                    // Navigator.pop(context);
                                  } else {
                                    setState(() {
                                      loading = false;
                                      error = 'Error';
                                    });
                                  }
                                },
                                color: secondaryColor,
                                textColor: darkPrimaryColor,
                              ),
                            ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
