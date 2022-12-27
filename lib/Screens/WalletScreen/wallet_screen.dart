import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: must_be_immutable
class WalletScreen extends StatefulWidget {
  String error;
  WalletScreen({Key? key, this.error = 'Something Went Wrong'})
      : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool loading = true;
  ScrollController _scrollController = ScrollController();

  String publicKey = 'Loading';
  String privateKey = 'Loading';
  String selectedWalletIndex = "1";
  String selectedWalletName = "Wallet1";
  String selectedWalletBalance = "0 ETH";
  List selectedWalletTxs = [];
  List wallets = [];

  Client httpClient = Client();
  late Web3Client web3client;

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    publicKey = 'Loading';
    privateKey = 'Loading';
    selectedWalletName = "Wallet1";
    selectedWalletBalance = "0 ETH";
    selectedWalletTxs = [];
    wallets = [];

    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> getWallets() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    String? lastWalletIndex = await storage.read(key: 'lastWalletIndex');
    for (int i = 1; i <= int.parse(lastWalletIndex!) - 1; i++) {
      String? valuePublicKey =
          await storage.read(key: 'publicKey${i}');
      String? valueName =
          await storage.read(key: 'Wallet${i}');
      wallets.add({i: valueName});
    }
  }

  Future<void> prepare() async {
    await dotenv.load(fileName: ".env");
    await getWallets();
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    web3client = Web3Client(dotenv.env['WEB3_INFURA_GOERLI_URL']!, httpClient);
    String? valuePublicKey =
        await storage.read(key: 'publicKey${selectedWalletIndex}');
    String? valuePrivateKey =
        await storage.read(key: 'privateKey${selectedWalletIndex}');
    String? valueName = await storage.read(key: 'Wallet${selectedWalletIndex}');
    EthereumAddress valueAddress =
        EthPrivateKey.fromHex(valuePrivateKey!).address;
    EtherAmount valueBalance = await web3client.getBalance(valueAddress);
    final response = await httpClient.get(Uri.parse(
        "https://api-goerli.etherscan.io//api?module=account&action=txlist&address=${valueAddress}&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey=${dotenv.env['ETHERSCAN_API']!}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = jsonBody['result'];

    setState(() {
      valuePublicKey != null ? publicKey = valuePublicKey : publicKey = 'Error';
      valuePrivateKey != null
          ? privateKey = valuePrivateKey
          : privateKey = 'Error';
      valueName != null
          ? selectedWalletName = valueName
          : selectedWalletName = 'Error';
      valueBalance != null
          ? selectedWalletBalance =
              '${valueBalance.getValueInUnit(EtherUnit.ether)} ETH'
          : selectedWalletBalance = 'Error';
      valueTxs != null
          ? selectedWalletTxs = valueTxs.reversed.toList()
          : selectedWalletTxs = [];

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
            backgroundColor: primaryColor,
            body: RefreshIndicator(
              backgroundColor: darkPrimaryColor,
              color: secondaryColor,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Center(
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.1),
                              RoundedButton(
                                pw: 250,
                                ph: 45,
                                text: 'Create wallet',
                                press: () {
                                  Navigator.push(
                                    context,
                                    SlideRightRoute(
                                      page: CreateWalletScreen(
                                        isWelcomeScreen: false,
                                      ),
                                    ),
                                  );
                                },
                                color: secondaryColor,
                                textColor: darkPrimaryColor,
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              RoundedButton(
                                pw: 250,
                                ph: 45,
                                text: 'Import wallet',
                                press: () {
                                  setState(() {
                                    loading = true;
                                  });
                                  Navigator.push(
                                    context,
                                    SlideRightRoute(
                                      page: ImportWalletScreen(
                                        isWelcomeScreen: false,
                                      ),
                                    ),
                                  );
                                  setState(() {
                                    loading = false;
                                  });
                                },
                                color: darkPrimaryColor,
                                textColor: secondaryColor,
                              ),
                              SizedBox(height: 30),

                              // Wallet
                              Container(
                                width: size.width * 0.8,
                                height: 200,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20.0),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.blue,
                                      Colors.green,
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: size.width * 0.8 - 20,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<int>(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          dropdownColor: darkPrimaryColor,
                                          focusColor: whiteColor,
                                          iconEnabledColor: whiteColor,
                                          alignment: Alignment.centerLeft,
                                          onChanged: (walletIndex) {
                                            setState(() {
                                              selectedWalletIndex =
                                                  walletIndex.toString();
                                              loading = true;
                                            });
                                            _refresh();
                                          },
                                          hint: Text(
                                            selectedWalletName,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 25,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          items: [
                                            for (Map wallet in wallets)
                                              DropdownMenuItem<int>(
                                                value:
                                                    wallets.indexOf(wallet) +
                                                        1,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      (wallets.indexOf(
                                                                      wallet) +
                                                                  1)
                                                              .toString() +
                                                          "   " +
                                                          wallet[
                                                              wallets.indexOf(
                                                                      wallet) +
                                                                  1],
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: whiteColor,
                                                          fontSize: 25,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text(
                                      selectedWalletBalance,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: whiteColor,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: size.width * 0.6 - 30,
                                          child: Text(
                                            publicKey,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Container(
                                          width: size.width * 0.15 - 30,
                                          child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                await Clipboard.setData(
                                                    ClipboardData(
                                                        text: publicKey));
                                                PushNotificationMessage
                                                    notification =
                                                    PushNotificationMessage(
                                                  title: 'Copied',
                                                  body: 'Public key copied',
                                                );
                                                showSimpleNotification(
                                                  Text(notification.body),
                                                  position:
                                                      NotificationPosition
                                                          .top,
                                                  background: greenColor,
                                                );
                                              },
                                              icon: Icon(
                                                CupertinoIcons.doc,
                                                color: whiteColor,
                                              )),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 30),
                              // Txs
                              selectedWalletTxs.length != 0
                                  ? Container(
                                      width: size.width * 0.8,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            whiteColor,
                                            Color.fromARGB(
                                                255, 220, 225, 234),
                                            Color.fromRGBO(134, 147, 171, 1.0)
                                          ],
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "Activity",
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: darkDarkColor,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 30,
                                          ),
                                          for (dynamic tx
                                              in selectedWalletTxs.take(5))
                                            Container(
                                              margin:
                                                  EdgeInsets.only(bottom: 30),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  // Icons + Date
                                                  Container(
                                                    width: size.width * 0.1,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        tx['from'] ==
                                                                publicKey
                                                            ? Icon(
                                                                CupertinoIcons
                                                                    .arrow_up_circle_fill,
                                                                color:
                                                                    darkDarkColor,
                                                              )
                                                            : Icon(
                                                                CupertinoIcons
                                                                    .arrow_down_circle_fill,
                                                                color: Colors
                                                                    .green,
                                                              ),
                                                        Text(
                                                          "${DateFormat.MMMd().format(DateTime.fromMillisecondsSinceEpoch(int.parse(tx['timeStamp'])))}",
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  darkDarkColor,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: size.width * 0.4,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        tx['from'] ==
                                                                publicKey
                                                            ? Text(
                                                                "Sent",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      const TextStyle(
                                                                    color:
                                                                        darkDarkColor,
                                                                    fontSize:
                                                                        25,
                                                                    fontWeight:
                                                                        FontWeight.w700,
                                                                  ),
                                                                ),
                                                              )
                                                            : Text(
                                                                "Received",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      const TextStyle(
                                                                    color:
                                                                        darkDarkColor,
                                                                    fontSize:
                                                                        25,
                                                                    fontWeight:
                                                                        FontWeight.w700,
                                                                  ),
                                                                ),
                                                              ),
                                                        tx['from'] ==
                                                                publicKey
                                                            ? Text(
                                                                "To ${tx['to']}",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                maxLines: 2,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      const TextStyle(
                                                                    color:
                                                                        darkDarkColor,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight.w400,
                                                                  ),
                                                                ),
                                                              )
                                                            : Text(
                                                                "From ${tx['from']}",
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                maxLines: 2,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      const TextStyle(
                                                                    color:
                                                                        darkDarkColor,
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight.w400,
                                                                  ),
                                                                ),
                                                              ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    width: size.width * 0.2,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          (int.parse(tx[
                                                                      'value']) /
                                                                  pow(10, 18))
                                                              .toString(),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  darkDarkColor,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          "ETH",
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  darkDarkColor,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : Container(),
                                  SizedBox(
                                            height: 100,
                                          ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
