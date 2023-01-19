import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Screens/TransactionScreen/buy_crypto_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_ozod_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_tx_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String error;
  HomeScreen({Key? key, this.error = 'Something Went Wrong'}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  ScrollController _scrollController = ScrollController();
  SharedPreferences? sharedPreferences;

  String publicKey = 'Loading';
  String privateKey = 'Loading';
  String selectedWalletIndex = "1";
  String selectedWalletName = "Wallet1";
  String importingAssetContractAddress = "";
  String importingAssetContractSymbol = "";
  String selectedNetworkId = "mainnet";
  String selectedNetworkName = "Ethereum Mainnet";

  EtherAmount selectedWalletBalance = EtherAmount.zero();
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  List selectedWalletTxs = [];
  List selectedWalletAssets = [];
  Map selectedWalletAssetsData = {};
  List wallets = [];
  DocumentSnapshot? walletFirebase;
  DocumentSnapshot? appDataNodes;
  DocumentSnapshot? appDataApi;
  DocumentSnapshot? appData;
  DocumentSnapshot? appStablecoins;
  DocumentSnapshot? uzsoFirebase;

  Client httpClient = Client();
  late Web3Client web3client;

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    publicKey = 'Loading';
    privateKey = 'Loading';
    importingAssetContractAddress = "";
    importingAssetContractSymbol = "";
    selectedWalletName = "Wallet1";
    selectedWalletBalance = EtherAmount.zero();
    selectedWalletTxs = [];
    selectedWalletAssets = [];
    selectedWalletAssetsData = {};
    wallets = [];

    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> getDataFromSP() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? valueSelectedWalletIndex =
        await sharedPreferences!.getString("selectedWalletIndex");
    String? valueselectedNetworkId =
        await sharedPreferences!.getString("selectedNetworkId");
    String? valueselectedNetworkName =
        await sharedPreferences!.getString("selectedNetworkName");
    if (mounted) {
      setState(() {
        if (valueSelectedWalletIndex != null) {
          selectedWalletIndex = valueSelectedWalletIndex;
        }
        if (valueselectedNetworkId != null) {
          selectedNetworkId = valueselectedNetworkId;
        }
        if (valueselectedNetworkName != null) {
          selectedNetworkName = valueselectedNetworkName;
        }
      });
    } else {
      if (valueSelectedWalletIndex != null) {
        selectedWalletIndex = valueSelectedWalletIndex;
      }
      if (valueselectedNetworkId != null) {
        selectedNetworkId = valueselectedNetworkId;
      }
      if (valueselectedNetworkName != null) {
        selectedNetworkName = valueselectedNetworkName;
      }
    }
  }

  Future<void> prepare() async {
    wallets = await SafeStorageService().getAllWallets();
    await getDataFromSP();
    // get app data
    appDataNodes = await FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('nodes')
        .get();
    appDataApi = await FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('api')
        .get();
    appData = await FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('data')
        .get();
    appStablecoins = await FirebaseFirestore.instance
        .collection('stablecoins')
        .doc('all_stablecoins')
        .get();
    uzsoFirebase = await FirebaseFirestore.instance
        .collection('stablecoins')
        .doc(appStablecoins!["UZSO"])
        .get();

    if (appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId] == null) {
      if (!appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]
          ['active']) {
        selectedNetworkId = "mainnet";
      }
    }
    web3client = Web3Client(
        EncryptionService().dec(appDataNodes!.get(appData!
            .get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['node'])),
        httpClient);

    // Wallet
    Map walletData =
        await SafeStorageService().getWalletData(selectedWalletIndex);

    // get balance
    final responseBalance = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}//api?module=account&action=tokenbalance&contractaddress=${uzsoFirebase!.id}&address=${walletData['address']}&tag=latest&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));
    dynamic jsonBodyBalance = jsonDecode(responseBalance.body);
    EtherAmount valueBalance =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, jsonBodyBalance['result']);

    walletFirebase = await FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletData['address'].toString())
        .get();

    
    // get txs
    final response = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}//api?module=account&action=tokentx&contractaddress=${uzsoFirebase!.id}&address=${walletData['address']}&page=1&offset=10&startblock=0&endblock=99999999&sort=desc&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = jsonBody['result'];
    // remove duplicates
    final jsonList = valueTxs.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    valueTxs = uniqueJsonList.map((item) => jsonDecode(item)).toList();

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
          ? selectedWalletTxs = valueTxs.toSet().toList()
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
                              SizedBox(height: 50),

                              // Blockchain network
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 40),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        borderSide: BorderSide(
                                            color: Colors.red, width: 1.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        borderSide: BorderSide(
                                            color: secondaryColor, width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        borderSide: BorderSide(
                                            color: secondaryColor, width: 1.0),
                                      ),
                                      hintStyle: TextStyle(
                                          color: darkPrimaryColor
                                              .withOpacity(0.7)),
                                      hintText: 'Network',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(40.0),
                                        borderSide: BorderSide(
                                            color: secondaryColor, width: 1.0),
                                      ),
                                    ),
                                    isDense: true,
                                    menuMaxHeight: 200,
                                    borderRadius: BorderRadius.circular(40.0),
                                    dropdownColor: darkPrimaryColor,
                                    // focusColor: whiteColor,
                                    iconEnabledColor: secondaryColor,
                                    alignment: Alignment.centerLeft,
                                    onChanged: (networkId) async {
                                      setState(() {
                                        loading = true;
                                      });
                                      await sharedPreferences!.setString(
                                          "selectedNetworkId",
                                          appData!
                                              .get('AVAILABLE_OZOD_NETWORKS')[
                                                  networkId]['id']
                                              .toString());
                                      await sharedPreferences!.setString(
                                          "selectedNetworkName",
                                          appData!
                                              .get('AVAILABLE_OZOD_NETWORKS')[
                                                  networkId]['name']
                                              .toString());
                                      setState(() {
                                        selectedNetworkId = appData!
                                                .get('AVAILABLE_OZOD_NETWORKS')[
                                            networkId]['id'];
                                        selectedNetworkName = appData!
                                                .get('AVAILABLE_OZOD_NETWORKS')[
                                            networkId]['name'];
                                      });
                                      _refresh();
                                    },
                                    hint: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          // width: size.width * 0.6 - 20,
                                          child: Text(
                                            selectedNetworkName,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: secondaryColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    items: [
                                      for (String networkId in appData!
                                          .get('AVAILABLE_OZOD_NETWORKS')
                                          .keys)
                                        DropdownMenuItem<String>(
                                          value: networkId,
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Image + symbol
                                                Row(
                                                  children: [
                                                    Text(
                                                      appData!.get(
                                                              'AVAILABLE_OZOD_NETWORKS')[
                                                          networkId]['name'],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: secondaryColor,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Wallet
                              Container(
                                width: size.width * 0.8,
                                height: 200,
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    // gradient: const LinearGradient(
                                    //   begin: Alignment.topLeft,
                                    //   end: Alignment.bottomRight,
                                    //   colors: [
                                    //     Colors.blue,
                                    //     Colors.green,
                                    //   ],
                                    // ),
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/images/card.png"),
                                        fit: BoxFit.fill)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: size.width * 0.8 - 20,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Jazzicon.getIconWidget(
                                              Jazzicon.getJazziconData(160,
                                                  address: publicKey),
                                              size: 25),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              dropdownColor: darkPrimaryColor,
                                              focusColor: darkDarkColor,
                                              iconEnabledColor: darkDarkColor,
                                              alignment: Alignment.centerLeft,
                                              onChanged: (walletIndex) async {
                                                await sharedPreferences!
                                                    .setString(
                                                        "selectedWalletIndex",
                                                        walletIndex.toString());
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
                                                    color: darkDarkColor,
                                                    fontSize: 25,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              items: [
                                                for (Map wallet in wallets)
                                                  DropdownMenuItem<int>(
                                                    value: wallets
                                                            .indexOf(wallet) +
                                                        1,
                                                    child: Row(
                                                      children: [
                                                        Jazzicon.getIconWidget(
                                                            Jazzicon.getJazziconData(
                                                                160,
                                                                address: wallet[
                                                                    'publicKey']),
                                                            size: 15),
                                                        SizedBox(
                                                          width: 10,
                                                        ),
                                                        Text(
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
                                                              color:
                                                                  secondaryColor,
                                                              fontSize: 25,
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
                                        ],
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
                                                color: darkDarkColor,
                                                fontSize: 30,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 100,
                                          child: Text(
                                            "UZSO",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: darkDarkColor,
                                                fontSize: 25,
                                                fontWeight: FontWeight.w700,
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
                                                color: darkDarkColor,
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
                                              color: darkDarkColor,
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
                                              color: darkDarkColor,
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
                                          onPressed: () async {
                                            setState(() {
                                              loading = true;
                                            });
                                            final response =
                                                await httpClient.get(Uri.parse(
                                                    "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=contract&action=getabi&address=${uzsoFirebase!.id}&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));

                                            if (int.parse(jsonDecode(
                                                        response.body)['status']
                                                    .toString()) ==
                                                1) {
                                              final contract = DeployedContract(
                                                  ContractAbi.fromJson(
                                                      jsonDecode(response.body)[
                                                          'result'],
                                                      "UZSOImplementation"),
                                                  EthereumAddress.fromHex(
                                                      uzsoFirebase!.id));
                                              Navigator.push(
                                                context,
                                                SlideRightRoute(
                                                  page: SendOzodScreen(
                                                    web3client: web3client,
                                                    walletIndex:
                                                        selectedWalletIndex,
                                                    networkId:
                                                        selectedNetworkId,
                                                    coin: {
                                                      'id': uzsoFirebase!.id,
                                                      'contract':contract,
                                                      'symbol': uzsoFirebase!
                                                          .get('symbol'),
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
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
                                                                      child:
                                                                          Text(
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
                                                        tx['from'] ==
                                                                    publicKey &&
                                                                !selectedWalletAssetsData
                                                                    .keys
                                                                    .contains(
                                                                        tx['to'])
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
                                                          !selectedWalletAssetsData
                                                                  .keys
                                                                  .contains(
                                                                      tx['to'])
                                                              ? EtherAmount.fromUnitAndValue(
                                                                      EtherUnit
                                                                          .wei,
                                                                      tx[
                                                                          'value'])
                                                                  .getValueInUnit(
                                                                      selectedEtherUnit)
                                                                  .toString()
                                                              : "N/A",
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
                                                          !selectedWalletAssetsData
                                                                  .keys
                                                                  .contains(
                                                                      tx['to'])
                                                              ? "UZSO"
                                                                  .toString()
                                                              : selectedWalletAssetsData[
                                                                  tx['to']],
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
