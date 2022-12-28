import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Screens/TransactionScreen/buy_crypto_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_tx_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web3dart/crypto.dart';
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
  EtherAmount selectedWalletBalance = EtherAmount.zero();
  List selectedWalletTxs = [];
  List wallets = [];
  Map<EtherUnit, String> cryptoUnits = {
    EtherUnit.ether: 'ETH',
    EtherUnit.wei: 'WEI',
    EtherUnit.gwei: 'GWEI',
  };
  EtherUnit selectedEtherUnit = EtherUnit.ether;

  Client httpClient = Client();
  late Web3Client web3client;

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    publicKey = 'Loading';
    privateKey = 'Loading';
    selectedWalletName = "Wallet1";
    selectedWalletBalance = EtherAmount.zero();
    selectedWalletTxs = [];
    wallets = [];

    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> prepare() async {
    await dotenv.load(fileName: ".env");
    wallets = await SafeStorageService().getAllWallets();
    web3client =
        Web3Client(dotenv.env['WEB3_QUICKNODE_GOERLI_URL']!, httpClient);
    Map walletData =
        await SafeStorageService().getWalletData(selectedWalletIndex);
    EtherAmount valueBalance =
        await web3client.getBalance(walletData['address']);

    // get txs
    final response = await httpClient.get(Uri.parse(
        "https://api-goerli.etherscan.io//api?module=account&action=txlist&address=${walletData['address']}&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey=${dotenv.env['ETHERSCAN_API']!}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = jsonBody['result'];

    setState(() {
      walletData['publicKey'] != null
          ? publicKey = walletData['publicKey']
          : publicKey = 'Error';
      walletData['privateKey'] != null
          ? privateKey = walletData['privateKey']
          : privateKey = 'Error';
      walletData['name'] != null
          ? selectedWalletName = walletData['name']
          : selectedWalletName = 'Error';
      valueBalance != null
          ? selectedWalletBalance = valueBalance
          : selectedWalletBalance = EtherAmount.zero();
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                                    wallets.indexOf(wallet) + 1,
                                                child: Text(
                                                  (wallets.indexOf(wallet) +
                                                              1)
                                                          .toString() +
                                                      "   " +
                                                      wallet[
                                                          wallets.indexOf(
                                                                  wallet) +
                                                              1],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts
                                                      .montserrat(
                                                    textStyle:
                                                        const TextStyle(
                                                      color: secondaryColor,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            selectedWalletBalance
                                                .getValueInUnit(
                                                    selectedEtherUnit)
                                                .toString(),
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
                                        ),
                                        Container(
                                          width: 100,
                                          child: DropdownButtonHideUnderline(
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: DropdownButton<EtherUnit>(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                dropdownColor: darkPrimaryColor,
                                                focusColor: whiteColor,
                                                iconEnabledColor: whiteColor,
                                                alignment: Alignment.centerLeft,
                                                onChanged: (unit) {
                                                  setState(() {
                                                    selectedEtherUnit = unit!;
                                                  });
                                                },
                                                hint: Text(
                                                  cryptoUnits[
                                                      selectedEtherUnit]!,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 25,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                items: [
                                                  for (EtherUnit unit
                                                      in cryptoUnits.keys)
                                                    DropdownMenuItem<EtherUnit>(
                                                      value: unit,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: <Widget>[
                                                          Text(
                                                            cryptoUnits[unit]!,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: GoogleFonts
                                                                .montserrat(
                                                              textStyle:
                                                                  const TextStyle(
                                                                color:
                                                                    secondaryColor,
                                                                fontSize: 20,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
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
                                        ),
                                      ],
                                    ),
                                    Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            publicKey,
                                            maxLines: 2,
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
                                        Container(
                                          width: 30,
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
                                                    NotificationPosition.top,
                                                background: greenColor,
                                              );
                                            },
                                            icon: Icon(
                                              CupertinoIcons.doc,
                                              color: whiteColor,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 30,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {},
                                            icon: Icon(
                                              CupertinoIcons.settings,
                                              color: whiteColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),

                              // Buttons
                              Container(
                                width: size.width * 0.8,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        RawMaterialButton(
                                          constraints: const BoxConstraints(
                                              minWidth: 70, minHeight: 60),
                                          fillColor: secondaryColor,
                                          shape: CircleBorder(),
                                          onPressed: () {
                                            setState(() {
                                              loading = true;
                                            });
                                            Navigator.push(
                                              context,
                                              SlideRightRoute(
                                                page: SendTxScreen(
                                                  web3client: web3client,
                                                  walletIndex:
                                                      selectedWalletIndex,
                                                ),
                                              ),
                                            );
                                            setState(() {
                                              loading = false;
                                            });
                                          },
                                          child: Icon(
                                            CupertinoIcons.arrow_up,
                                            color: darkPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          "Send",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        RawMaterialButton(
                                          constraints: const BoxConstraints(
                                              minWidth: 70, minHeight: 60),
                                          fillColor: secondaryColor,
                                          shape: CircleBorder(),
                                          onPressed: () {
                                            showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return StatefulBuilder(
                                                    builder: (context,
                                                        StateSetter setState) {
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            darkPrimaryColor,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.0),
                                                        ),
                                                        title: const Text(
                                                          'QR Code',
                                                          style: TextStyle(
                                                              color:
                                                                  secondaryColor),
                                                        ),
                                                        content:
                                                            SingleChildScrollView(
                                                          child: Container(
                                                            margin:
                                                                EdgeInsets.all(
                                                                    10),
                                                            child: Column(
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(20),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20.0),
                                                                    gradient:
                                                                        const LinearGradient(
                                                                      begin: Alignment
                                                                          .topLeft,
                                                                      end: Alignment
                                                                          .bottomRight,
                                                                      colors: [
                                                                        darkPrimaryColor,
                                                                        primaryColor
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      QrImage(
                                                                    data: EthereumAddress.fromHex(
                                                                            publicKey)
                                                                        .addressBytes
                                                                        .toString(),
                                                                    foregroundColor:
                                                                        secondaryColor,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Expanded(
                                                                      child: Text(
                                                                          publicKey,
                                                                          overflow:
                                                                        TextOverflow.ellipsis,
                                                                          maxLines:
                                                                        10,
                                                                          textAlign:
                                                                        TextAlign.start,
                                                                          style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.w500,
                                                                      ),
                                                                          ),
                                                                        ),
                                                                    ),
                                                                    Container(
                                                                      width: 30,
                                                                      child:
                                                                          IconButton(
                                                                        padding:
                                                                            EdgeInsets.zero,
                                                                        onPressed:
                                                                            () async {
                                                                          await Clipboard.setData(
                                                                              ClipboardData(text: publicKey));
                                                                          PushNotificationMessage
                                                                              notification =
                                                                              PushNotificationMessage(
                                                                            title:
                                                                                'Copied',
                                                                            body:
                                                                                'Public key copied',
                                                                          );
                                                                          showSimpleNotification(
                                                                            Text(notification.body),
                                                                            position:
                                                                                NotificationPosition.top,
                                                                            background:
                                                                                greenColor,
                                                                          );
                                                                        },
                                                                        icon:
                                                                            Icon(
                                                                          CupertinoIcons
                                                                              .doc,
                                                                          color:
                                                                              secondaryColor,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(false),
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
                                          },
                                          child: Icon(
                                            CupertinoIcons.arrow_down,
                                            color: darkPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          "Receive",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        RawMaterialButton(
                                          constraints: const BoxConstraints(
                                              minWidth: 70, minHeight: 60),
                                          fillColor: secondaryColor,
                                          shape: CircleBorder(),
                                          onPressed: () {
                                            setState(() {
                                              loading = true;
                                            });
                                            Navigator.push(
                                              context,
                                              SlideRightRoute(
                                                page: BuyCryptoScreen(
                                                  web3client: web3client,
                                                  walletIndex:
                                                      selectedWalletIndex,
                                                ),
                                              ),
                                            );
                                            setState(() {
                                              loading = false;
                                            });
                                          },
                                          child: Icon(
                                            CupertinoIcons.money_dollar,
                                            color: darkPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          "Buy",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: secondaryColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),

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
                                            Color.fromARGB(255, 220, 225, 234),
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
                                                        tx['from'] == publicKey
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
                                                          overflow: TextOverflow
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
                                                        tx['from'] == publicKey
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
                                                                        FontWeight
                                                                            .w700,
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
                                                                        FontWeight
                                                                            .w700,
                                                                  ),
                                                                ),
                                                              ),
                                                        tx['from'] == publicKey
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
                                                                        FontWeight
                                                                            .w400,
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
                                                                        FontWeight
                                                                            .w400,
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
                                                          EtherAmount.fromUnitAndValue(
                                                                  EtherUnit.wei,
                                                                  tx['value'])
                                                              .getValueInUnit(
                                                                  selectedEtherUnit)
                                                              .toString(),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
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
                                                          cryptoUnits[
                                                                  selectedEtherUnit]
                                                              .toString(),
                                                          overflow: TextOverflow
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
