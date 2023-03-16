import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ozodwallet/Screens/TransactionScreen/BuyOzodScreen/buy_ozod_octo_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/BuyOzodScreen/buy_ozod_payme_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/buy_crypto_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_ozod_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
import 'package:ozodwallet/Services/notification_service.dart';
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
  Function refreshFunction;
  HomeScreen(
      {Key? key,
      this.error = 'Something Went Wrong',
      required this.refreshFunction})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = true;
  String? loadingString;
  Timer? timer;
  ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  SharedPreferences? sharedPreferences;
  Map<String, Map> cardsData = {
    'goerli': {
      'image': "assets/images/card_ethereum.png",
      'color': whiteColor,
    },
    'mainnet': {
      'image': "assets/images/card_ethereum.png",
      'color': whiteColor,
    },
    'polygon_mumbai': {
      'image': "assets/images/card_polygon.png",
      'color': whiteColor,
    },
  };

  String publicKey = 'Loading';
  String privateKey = 'Loading';
  String selectedWalletIndex = "1";
  String selectedWalletName = "Wallet1";
  String importingAssetContractAddress = "";
  String importingAssetContractSymbol = "";
  String selectedNetworkId = "goerli";
  String selectedNetworkName = "Goerli Testnet";

  // Settings
  bool showSeed = false;
  String editedName = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  EtherAmount selectedWalletBalance = EtherAmount.zero();
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  DeployedContract? uzsoContract;
  List selectedWalletTxs = [];
  List selectedWalletAssets = [];
  Map selectedWalletAssetsData = {};
  List wallets = [];
  EtherAmount estimateGasPrice = EtherAmount.zero();
  BigInt estimateGasAmount = BigInt.from(1);
  EtherAmount? gasBalance;
  double gasTxsLeft = 0;

  firestore.DocumentSnapshot? walletFirebase;
  firestore.DocumentSnapshot? appDataNodes;
  firestore.DocumentSnapshot? appDataApi;
  firestore.DocumentSnapshot? appData;
  firestore.DocumentSnapshot? appStablecoins;
  firestore.DocumentSnapshot? uzsoFirebase;

  Client httpClient = Client();
  Web3Client? web3client;

  Future<void> _refresh({bool isLoading = true}) async {
    if (isLoading) {
      setState(() {
        loading = true;
      });
    }
    loadingString = null;
    showSeed = false;
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
    estimateGasPrice = EtherAmount.zero();
    estimateGasAmount = BigInt.from(1);
    gasBalance = EtherAmount.zero();
    gasTxsLeft = 0;
    web3client = null;

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
    appDataNodes = await firestore.FirebaseFirestore.instance
        .collection('app_data')
        .doc('nodes')
        .get();
    appDataApi = await firestore.FirebaseFirestore.instance
        .collection('app_data')
        .doc('api')
        .get();
    appData = await firestore.FirebaseFirestore.instance
        .collection('app_data')
        .doc('data')
        .get();
    // Check network availability
    if (appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId] == null) {
      selectedNetworkId = "goerli";
      selectedNetworkName = "Goerli Testnet";
    } else {
      if (!appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]
          ['active']) {
        selectedNetworkId = "goerli";
        selectedNetworkName = "Goerli Testnet";
      }
    }

    appStablecoins = await firestore.FirebaseFirestore.instance
        .collection('stablecoins')
        .doc('all_stablecoins')
        .get();

    // Get stablecoin data
    uzsoFirebase = await firestore.FirebaseFirestore.instance
        .collection('stablecoins')
        .doc(appStablecoins![
            appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['coin']])
        .get();

    web3client = Web3Client(
        EncryptionService().dec(appDataNodes!.get(appData!
            .get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['node'])),
        httpClient);

    // Wallet
    Map walletData =
        await SafeStorageService().getWalletData(selectedWalletIndex);

    // ENC CODE
    // print("CODERGREGRE");
    // EncryptionService encryptionService = EncryptionService();
    // print(encryptionService.enc(
    //     "https://rpc.ankr.com/premium-http/tron/e84adb6a22d3cb13dfeccf850187e9682510541afb194bd9232c8d2cd95bb328"));

    if (jsonDecode(uzsoFirebase!.get('contract_abi')) != null) {
      uzsoContract = DeployedContract(
          ContractAbi.fromJson(
              jsonEncode(jsonDecode(uzsoFirebase!.get('contract_abi'))),
              "UZSOImplementation"),
          EthereumAddress.fromHex(uzsoFirebase!.id));
    }

    // get balance
    final responseBalance = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}//api?module=account&action=tokenbalance&contractaddress=${uzsoFirebase!.id}&address=${walletData['address']}&tag=latest&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_api']))}"));
    dynamic jsonBodyBalance = jsonDecode(responseBalance.body);
    EtherAmount valueBalance =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, jsonBodyBalance['result']);

    walletFirebase = await firestore.FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletData['address'].toString())
        .get();

    // get txs
    final response = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}//api?module=account&action=tokentx&contractaddress=${uzsoFirebase!.id}&address=${walletData['address']}&page=1&offset=10&startblock=0&endblock=99999999&sort=desc&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_api']))}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = jsonBody['result'];

    // remove duplicates
    final jsonList = valueTxs.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    valueTxs = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    // Get gas indicator data
    // print("GERGRE");
    // print(await web3client!.getChainId());
    // print(await web3client!.getGasPrice());
    // print(await web3client!.estimateGas(
    //   sender: EthereumAddress.fromHex(walletData['publicKey']),
    // ));
    estimateGasPrice = await web3client!.getGasPrice();
    estimateGasAmount = await web3client!.estimateGas(
      sender: walletData['address'],
    );

    gasBalance = await web3client!.getBalance(walletData['address']);

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
      gasTxsLeft = (gasBalance!.getValueInUnit(EtherUnit.gwei) /
              (estimateGasPrice.getValueInUnit(EtherUnit.gwei) *
                  estimateGasAmount.toDouble()))
          .toDouble();

      loading = false;
    });
  }

  @override
  void initState() {
    prepare();
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
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
        ? LoadingScreen(
            text: loadingString,
          )
        : Scaffold(
            key: _scaffoldKey,
            backgroundColor: darkPrimaryColor,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              // toolbarHeight: 30,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                color: secondaryColor,
                icon: const Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 30,
                ),
                onPressed: () {
                  _scaffoldKey.currentState!.openDrawer();
                },
              ),
            ),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              elevation: 10,
              backgroundColor: darkPrimaryColor,
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: lightPrimaryColor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Wallet Settings",
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: darkPrimaryColor,
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
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
                                darkPrimaryColor,
                                darkPrimaryColor,
                                primaryColor,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Jazzicon.getIconWidget(
                                      Jazzicon.getJazziconData(160,
                                          address: publicKey),
                                      size: 20),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      selectedWalletName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: secondaryColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.network(
                                    appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                        selectedNetworkId]['image'],
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                          selectedNetworkId]['name'],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 3,
                                      textAlign: TextAlign.start,
                                      style: GoogleFonts.montserrat(
                                        textStyle: const TextStyle(
                                          color: secondaryColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.plus_square,
                      color: secondaryColor,
                    ),
                    title: Text(
                      "Create wallet",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        loading = true;
                      });
                      Navigator.push(
                        context,
                        SlideRightRoute(
                          page: CreateWalletScreen(
                            isWelcomeScreen: false,
                          ),
                        ),
                      );
                      setState(() {
                        loading = false;
                      });
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.arrow_down_square,
                      color: secondaryColor,
                    ),
                    title: Text(
                      "Import wallet",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
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
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.key,
                      color: secondaryColor,
                    ),
                    title: Text(
                      "Export private key",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: darkPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text(
                                    'Private Key',
                                    style: TextStyle(color: secondaryColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: CupertinoButton(
                                              child: showSeed
                                                  ? Container(
                                                      width: size.width * 0.8,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        gradient:
                                                            const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromARGB(255,
                                                                255, 190, 99),
                                                            Color.fromARGB(255,
                                                                255, 81, 83)
                                                          ],
                                                        ),
                                                      ),
                                                      child: Text(
                                                        privateKey,
                                                        maxLines: 1000,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            color: whiteColor,
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              20),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                        gradient:
                                                            const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Color.fromARGB(255,
                                                                255, 190, 99),
                                                            Color.fromARGB(255,
                                                                255, 81, 83)
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
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () async {
                                              await Clipboard.setData(
                                                ClipboardData(text: privateKey),
                                              );
                                              showNotification(
                                                  'Copied',
                                                  'Private key copied',
                                                  greenColor);
                                            },
                                            icon: Icon(
                                              CupertinoIcons.doc,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Ok',
                                        style: TextStyle(color: secondaryColor),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });

                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.pencil_circle,
                      color: secondaryColor,
                    ),
                    title: Text(
                      "Edit name",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: secondaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: darkPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text(
                                    'Edit name',
                                    style: TextStyle(color: secondaryColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Form(
                                      key: _formKey,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            TextFormField(
                                              initialValue: selectedWalletName,
                                              style: const TextStyle(
                                                  color: secondaryColor),
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
                                                  editedName = val;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                errorBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.red,
                                                      width: 1.0),
                                                ),
                                                focusedBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                                enabledBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                                hintStyle: TextStyle(
                                                    color: darkPrimaryColor
                                                        .withOpacity(0.7)),
                                                hintText: 'Name',
                                                labelStyle: TextStyle(
                                                  color: secondaryColor,
                                                ),
                                                labelText: "Name",
                                                border:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Center(
                                              child: RoundedButton(
                                                pw: 250,
                                                ph: 45,
                                                text: 'Edit',
                                                press: () async {
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      editedName != null &&
                                                      editedName.isNotEmpty) {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    setState(() {
                                                      loading = true;
                                                    });
                                                    await SafeStorageService()
                                                        .editWalletName(
                                                            selectedWalletIndex,
                                                            editedName);
                                                    _refresh();
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
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Ok',
                                        style: TextStyle(color: secondaryColor),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });

                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      CupertinoIcons.trash,
                      color: Colors.red,
                    ),
                    title: Text(
                      "Delete all data",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: darkPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: const Text(
                                    'Delete all data',
                                    style: TextStyle(color: secondaryColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Form(
                                      key: _formKey,
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              "Enter word DELETE to continue",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 5,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  color: secondaryColor,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.red,
                                                    width: 1.0),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              padding: EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    CupertinoIcons
                                                        .exclamationmark_circle,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      "This action will delete all data from this phone. Your wallets and assets will still remain on blockchain, and you can restore them by your private key and secret phrase",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 5,
                                                      textAlign:
                                                          TextAlign.start,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color: Colors.red,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w300,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: 20,
                                            ),
                                            TextFormField(
                                              style: const TextStyle(
                                                  color: secondaryColor),
                                              validator: (val) {
                                                if (val!.isEmpty) {
                                                  return 'Enter DELETE';
                                                } else if (val != 'DELETE') {
                                                  return 'Enter DELETE';
                                                } else {
                                                  return null;
                                                }
                                              },
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                errorBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Colors.red,
                                                      width: 1.0),
                                                ),
                                                focusedBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                                enabledBorder:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                                hintStyle: TextStyle(
                                                    color: darkPrimaryColor
                                                        .withOpacity(0.7)),
                                                hintText: 'DELETE',
                                                border:
                                                    const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: secondaryColor,
                                                      width: 1.0),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Center(
                                              child: RoundedButton(
                                                pw: 250,
                                                ph: 45,
                                                text: 'Delete',
                                                press: () async {
                                                  if (_formKey.currentState!
                                                          .validate() &&
                                                      editedName != null &&
                                                      editedName.isNotEmpty) {
                                                    Navigator.of(context)
                                                        .pop(true);
                                                    setState(() {
                                                      loading = true;
                                                    });

                                                    await SafeStorageService()
                                                        .deleteAllData();
                                                    await sharedPreferences!
                                                        .clear();
                                                    widget.refreshFunction();
                                                  }
                                                },
                                                color: Colors.red,
                                                textColor: secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: secondaryColor),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          });

                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            body: RefreshIndicator(
              backgroundColor: lightPrimaryColor,
              color: darkPrimaryColor,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth: kIsWeb ? 600 : double.infinity),
                            child: Column(
                              children: [
                                SizedBox(height: 10),

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
                                              color: secondaryColor,
                                              width: 1.0),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: BorderSide(
                                              color: secondaryColor,
                                              width: 1.0),
                                        ),
                                        hintStyle: TextStyle(
                                            color: darkPrimaryColor
                                                .withOpacity(0.7)),
                                        hintText: 'Network',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                          borderSide: BorderSide(
                                              color: secondaryColor,
                                              width: 1.0),
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
                                          selectedNetworkId = appData!.get(
                                                  'AVAILABLE_OZOD_NETWORKS')[
                                              networkId]['id'];
                                          selectedNetworkName = appData!.get(
                                                  'AVAILABLE_OZOD_NETWORKS')[
                                              networkId]['name'];
                                        });
                                        _refresh();
                                      },
                                      hint: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Image.network(
                                            appData!.get(
                                                    'AVAILABLE_OZOD_NETWORKS')[
                                                selectedNetworkId]['image'],
                                            width: 30,
                                          ),
                                          SizedBox(
                                            width: 5,
                                          ),
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
                                          if (appData!.get(
                                                  'AVAILABLE_OZOD_NETWORKS')[
                                              networkId]['active'])
                                            DropdownMenuItem<String>(
                                              value: networkId,
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 10),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Image.network(
                                                      appData!.get(
                                                              'AVAILABLE_OZOD_NETWORKS')[
                                                          networkId]['image'],
                                                      width: 30,
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    // Image + symbol
                                                    Text(
                                                      appData!.get(
                                                              'AVAILABLE_OZOD_NETWORKS')[
                                                          networkId]['name'],
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: secondaryColor,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w700,
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
                                ),
                                SizedBox(height: 20),

                                // Alerts
                                if (appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                    selectedNetworkId]['is_testnet'])
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 40),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.exclamationmark_circle,
                                          color: Colors.red,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text(
                                            "This is a test blockchain network. Assets in this chain do not have real value",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 5,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                color: Colors.red,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (gasTxsLeft < 0)
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.all(15),
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.exclamationmark_circle,
                                          color: Colors.red,
                                        ),
                                        SizedBox(
                                          width: 5,
                                        ),
                                        Expanded(
                                          child: Text(
                                            "You ran out of gas. Buy more coins",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 5,
                                            textAlign: TextAlign.start,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                overflow: TextOverflow.ellipsis,
                                                color: secondaryColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w300,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 20),

                                // Wallet
                                kIsWeb
                                    ? Container(
                                        margin:
                                            EdgeInsets.fromLTRB(10, 0, 10, 10),
                                        width: 270,
                                        height: 200,
                                        padding: const EdgeInsets.fromLTRB(
                                            18, 10, 18, 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          // gradient: const LinearGradient(
                                          //   begin: Alignment.topLeft,
                                          //   end: Alignment.bottomRight,
                                          //   colors: [
                                          //     Colors.blue,
                                          //     Colors.green,
                                          //   ],
                                          // ),
                                          image: DecorationImage(
                                            image: AssetImage(cardsData[
                                                selectedNetworkId]!['image']),
                                            fit: BoxFit.fitHeight,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Jazzicon.getIconWidget(
                                                    Jazzicon.getJazziconData(
                                                        160,
                                                        address: publicKey),
                                                    size: 20),
                                                SizedBox(
                                                  width: 5,
                                                ),
                                                Container(
                                                  width: 160,
                                                  child:
                                                      DropdownButtonHideUnderline(
                                                    child: DropdownButton<int>(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20.0),
                                                      dropdownColor:
                                                          darkPrimaryColor,
                                                      focusColor: cardsData[
                                                              selectedNetworkId]![
                                                          'color'],
                                                      iconEnabledColor: cardsData[
                                                              selectedNetworkId]![
                                                          'color'],
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      onChanged:
                                                          (walletIndex) async {
                                                        await sharedPreferences!
                                                            .setString(
                                                                "selectedWalletIndex",
                                                                walletIndex
                                                                    .toString());
                                                        setState(() {
                                                          selectedWalletIndex =
                                                              walletIndex
                                                                  .toString();
                                                          loading = true;
                                                        });
                                                        _refresh();
                                                      },
                                                      hint: Container(
                                                        width: 130,
                                                        child: Text(
                                                          selectedWalletName,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                TextStyle(
                                                              color: cardsData[
                                                                      selectedNetworkId]![
                                                                  'color'],
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      items: [
                                                        for (Map wallet
                                                            in wallets)
                                                          DropdownMenuItem<int>(
                                                            value:
                                                                wallets.indexOf(
                                                                        wallet) +
                                                                    1,
                                                            child: Row(
                                                              children: [
                                                                Jazzicon.getIconWidget(
                                                                    Jazzicon.getJazziconData(
                                                                        160,
                                                                        address:
                                                                            wallet['publicKey']),
                                                                    size: 15),
                                                                SizedBox(
                                                                  width: 10,
                                                                ),
                                                                Container(
                                                                  width: 100,
                                                                  child: Text(
                                                                    wallet[wallets
                                                                            .indexOf(wallet) +
                                                                        1],
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            20,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
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
                                              ],
                                            ),
                                            Text(
                                              selectedWalletBalance
                                                      .getValueInUnit(
                                                          selectedEtherUnit)
                                                      .toString() +
                                                  "  " +
                                                  "UZSO",
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: TextStyle(
                                                  color: cardsData[
                                                          selectedNetworkId]![
                                                      'color'],
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    publicKey,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle: TextStyle(
                                                        color: cardsData[
                                                                selectedNetworkId]![
                                                            'color'],
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
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
                                                      showNotification(
                                                          'Copied',
                                                          'Public key copied',
                                                          greenColor);
                                                    },
                                                    icon: Icon(
                                                      CupertinoIcons.doc,
                                                      color: cardsData[
                                                              selectedNetworkId]![
                                                          'color'],
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 30,
                                                  child: IconButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      _scaffoldKey.currentState!
                                                          .openDrawer();
                                                    },
                                                    icon: Icon(
                                                      CupertinoIcons.settings,
                                                      color: cardsData[
                                                              selectedNetworkId]![
                                                          'color'],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    : CarouselSlider(
                                        options: CarouselOptions(
                                          enableInfiniteScroll: false,
                                          initialPage: appData!
                                              .get('AVAILABLE_OZOD_NETWORKS')
                                              .keys
                                              .toList()
                                              .indexOf(selectedNetworkId),
                                          height: 210.0,
                                          onPageChanged: (index, reason) async {
                                            List networkIds = [];
                                            for (String id in appData!
                                                .get('AVAILABLE_OZOD_NETWORKS')
                                                .keys) {
                                              if (appData!.get(
                                                      'AVAILABLE_OZOD_NETWORKS')[
                                                  id]['active']) {
                                                networkIds.add(id);
                                              }
                                            }
                                            String networkId =
                                                networkIds[index];
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
                                              selectedNetworkId = appData!.get(
                                                      'AVAILABLE_OZOD_NETWORKS')[
                                                  networkId]['id'];
                                              selectedNetworkName = appData!.get(
                                                      'AVAILABLE_OZOD_NETWORKS')[
                                                  networkId]['name'];
                                            });
                                            _refresh(
                                              isLoading: false,
                                            );
                                          },
                                        ),
                                        items: [
                                          for (String networkId in appData!
                                              .get('AVAILABLE_OZOD_NETWORKS')
                                              .keys)
                                            if (appData!.get(
                                                    'AVAILABLE_OZOD_NETWORKS')[
                                                networkId]['active'])
                                              Builder(
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                        10, 0, 10, 10),
                                                    width: 270,
                                                    height: 200,
                                                    padding: const EdgeInsets
                                                            .fromLTRB(
                                                        18, 10, 18, 10),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10.0),
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
                                                            cardsData[
                                                                    networkId]![
                                                                'image']),
                                                        fit: BoxFit.fitHeight,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Jazzicon.getIconWidget(
                                                                Jazzicon.getJazziconData(
                                                                    160,
                                                                    address:
                                                                        publicKey),
                                                                size: 20),
                                                            SizedBox(
                                                              width: 5,
                                                            ),
                                                            Container(
                                                              width: 160,
                                                              child:
                                                                  DropdownButtonHideUnderline(
                                                                child:
                                                                    DropdownButton<
                                                                        int>(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20.0),
                                                                  dropdownColor:
                                                                      darkPrimaryColor,
                                                                  focusColor:
                                                                      cardsData[
                                                                              networkId]![
                                                                          'color'],
                                                                  iconEnabledColor:
                                                                      cardsData[
                                                                              networkId]![
                                                                          'color'],
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  onChanged:
                                                                      (walletIndex) async {
                                                                    await sharedPreferences!.setString(
                                                                        "selectedWalletIndex",
                                                                        walletIndex
                                                                            .toString());
                                                                    setState(
                                                                        () {
                                                                      selectedWalletIndex =
                                                                          walletIndex
                                                                              .toString();
                                                                      loading =
                                                                          true;
                                                                    });
                                                                    _refresh();
                                                                  },
                                                                  hint:
                                                                      Container(
                                                                    width: 130,
                                                                    child: Text(
                                                                      selectedWalletName,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .start,
                                                                      style: GoogleFonts
                                                                          .montserrat(
                                                                        textStyle:
                                                                            TextStyle(
                                                                          color:
                                                                              cardsData[networkId]!['color'],
                                                                          fontSize:
                                                                              20,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  items: [
                                                                    for (Map wallet
                                                                        in wallets)
                                                                      DropdownMenuItem<
                                                                          int>(
                                                                        value:
                                                                            wallets.indexOf(wallet) +
                                                                                1,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: wallet['publicKey']),
                                                                                size: 15),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Container(
                                                                              width: 100,
                                                                              child: Text(
                                                                                wallet[wallets.indexOf(wallet) + 1],
                                                                                overflow: TextOverflow.ellipsis,
                                                                                style: GoogleFonts.montserrat(
                                                                                  textStyle: const TextStyle(
                                                                                    color: secondaryColor,
                                                                                    fontSize: 20,
                                                                                    fontWeight: FontWeight.w700,
                                                                                  ),
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
                                                          ],
                                                        ),
                                                        Text(
                                                          selectedWalletBalance
                                                                  .getValueInUnit(
                                                                      selectedEtherUnit)
                                                                  .toString() +
                                                              "  " +
                                                              "UZSO",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                          textAlign:
                                                              TextAlign.start,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                TextStyle(
                                                              color: cardsData[
                                                                      networkId]![
                                                                  'color'],
                                                              fontSize: 30,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                        Spacer(),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                publicKey,
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textAlign:
                                                                    TextAlign
                                                                        .start,
                                                                style: GoogleFonts
                                                                    .montserrat(
                                                                  textStyle:
                                                                      TextStyle(
                                                                    color: cardsData[
                                                                            networkId]![
                                                                        'color'],
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 30,
                                                              child: IconButton(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                onPressed:
                                                                    () async {
                                                                  await Clipboard.setData(
                                                                      ClipboardData(
                                                                          text:
                                                                              publicKey));
                                                                  showNotification(
                                                                      'Copied',
                                                                      'Public key copied',
                                                                      greenColor);
                                                                },
                                                                icon: Icon(
                                                                  CupertinoIcons
                                                                      .doc,
                                                                  color: cardsData[
                                                                          networkId]![
                                                                      'color'],
                                                                ),
                                                              ),
                                                            ),
                                                            Container(
                                                              width: 30,
                                                              child: IconButton(
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                onPressed:
                                                                    () async {
                                                                  _scaffoldKey
                                                                      .currentState!
                                                                      .openDrawer();
                                                                },
                                                                icon: Icon(
                                                                  CupertinoIcons
                                                                      .settings,
                                                                  color: cardsData[
                                                                          networkId]![
                                                                      'color'],
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                        ],
                                      ),
                                SizedBox(height: 20),

                                // Buttons
                                Container(
                                  width: size.width * 0.9,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Invoice button
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
                                              // QR Scanner
                                              showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return StatefulBuilder(
                                                      builder: (context,
                                                          StateSetter
                                                              setState) {
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
                                                              width:
                                                                  size.width *
                                                                      0.9,
                                                              height:
                                                                  size.height *
                                                                      0.4,
                                                              margin: EdgeInsets
                                                                  .all(0),
                                                              child: Column(
                                                                children: [
                                                                  Container(
                                                                    height: 300,
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            10),
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
                                                                        MobileScanner(
                                                                      allowDuplicates:
                                                                          false,
                                                                      onDetect:
                                                                          (barcode,
                                                                              args) async {
                                                                        if (barcode.rawValue ==
                                                                            null) {
                                                                          showNotification(
                                                                              'Failed',
                                                                              'Failed to find code',
                                                                              Colors.red);
                                                                        } else {
                                                                          try {
                                                                            firestore.DocumentSnapshot
                                                                                invoice =
                                                                                await firestore.FirebaseFirestore.instance.collection('invoices').doc(barcode.rawValue).get();
                                                                            if (invoice.exists) {
                                                                              if (invoice.get('networkId') == selectedNetworkId) {
                                                                                if (invoice.get('status') != '10') {
                                                                                  EtherAmount etherGas = await web3client!.getGasPrice();
                                                                                  BigInt estimateGas = await web3client!.estimateGas(
                                                                                    sender: EthereumAddress.fromHex(publicKey),
                                                                                    to: EthereumAddress.fromHex(invoice.get('to')),
                                                                                  );
                                                                                  // Confirmation
                                                                                  showDialog(
                                                                                      barrierDismissible: false,
                                                                                      context: context,
                                                                                      builder: (BuildContext context) {
                                                                                        return StatefulBuilder(
                                                                                          builder: (context, StateSetter setState) {
                                                                                            return AlertDialog(
                                                                                              backgroundColor: darkPrimaryColor,
                                                                                              shape: RoundedRectangleBorder(
                                                                                                borderRadius: BorderRadius.circular(20.0),
                                                                                              ),
                                                                                              title: const Text(
                                                                                                'Cofirmation',
                                                                                                style: TextStyle(color: secondaryColor),
                                                                                              ),
                                                                                              content: SingleChildScrollView(
                                                                                                child: Container(
                                                                                                  child: Column(
                                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                                    children: [
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
                                                                                                        child: Column(
                                                                                                          children: [
                                                                                                            Row(
                                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                              children: [
                                                                                                                Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: publicKey), size: 25),
                                                                                                                SizedBox(
                                                                                                                  width: 10,
                                                                                                                ),
                                                                                                                Expanded(
                                                                                                                  child: Text(
                                                                                                                    selectedWalletName,
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
                                                                                                            SizedBox(
                                                                                                              height: 20,
                                                                                                            ),
                                                                                                            Row(
                                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                              children: [
                                                                                                                Image.network(
                                                                                                                  appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['image'],
                                                                                                                  width: 20,
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: 10,
                                                                                                                ),
                                                                                                                Expanded(
                                                                                                                  child: Text(
                                                                                                                    appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['name'],
                                                                                                                    overflow: TextOverflow.ellipsis,
                                                                                                                    maxLines: 3,
                                                                                                                    textAlign: TextAlign.start,
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
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                      const SizedBox(
                                                                                                        height: 20,
                                                                                                      ),
                                                                                                      Text(
                                                                                                        "Amount",
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                        maxLines: 3,
                                                                                                        textAlign: TextAlign.center,
                                                                                                        style: GoogleFonts.montserrat(
                                                                                                          textStyle: const TextStyle(
                                                                                                            color: secondaryColor,
                                                                                                            fontSize: 25,
                                                                                                            fontWeight: FontWeight.w700,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      const SizedBox(
                                                                                                        height: 10,
                                                                                                      ),
                                                                                                      Text(
                                                                                                        NumberFormat.compact().format(double.parse(invoice.get('amount'))),
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                        maxLines: 3,
                                                                                                        textAlign: TextAlign.center,
                                                                                                        style: GoogleFonts.montserrat(
                                                                                                          textStyle: const TextStyle(
                                                                                                            overflow: TextOverflow.ellipsis,
                                                                                                            color: secondaryColor,
                                                                                                            fontSize: 60,
                                                                                                            fontWeight: FontWeight.w700,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ),
                                                                                                      const SizedBox(
                                                                                                        height: 10,
                                                                                                      ),
                                                                                                      Container(
                                                                                                        child: Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                                          children: [
                                                                                                            Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: invoice.get('coinId')), size: 25),
                                                                                                            SizedBox(
                                                                                                              width: 10,
                                                                                                            ),
                                                                                                            Container(
                                                                                                              width: 100,
                                                                                                              child: Text(
                                                                                                                invoice.get('coinSymbol'),
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
                                                                                                      ),
                                                                                                      SizedBox(
                                                                                                        height: 20,
                                                                                                      ),
                                                                                                      Container(
                                                                                                        decoration: BoxDecoration(
                                                                                                          border: Border.all(color: secondaryColor, width: 1.0),
                                                                                                          borderRadius: BorderRadius.circular(20),
                                                                                                        ),
                                                                                                        padding: EdgeInsets.all(15),
                                                                                                        child: Column(
                                                                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                          children: [
                                                                                                            // Ether gas
                                                                                                            Container(
                                                                                                              child: Row(
                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                children: [
                                                                                                                  Container(
                                                                                                                    width: size.width * 0.2,
                                                                                                                    child: Text(
                                                                                                                      "Gas price",
                                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                                      maxLines: 3,
                                                                                                                      textAlign: TextAlign.start,
                                                                                                                      style: GoogleFonts.montserrat(
                                                                                                                        textStyle: const TextStyle(
                                                                                                                          overflow: TextOverflow.ellipsis,
                                                                                                                          color: secondaryColor,
                                                                                                                          fontSize: 15,
                                                                                                                          fontWeight: FontWeight.w300,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                  SizedBox(
                                                                                                                    width: 5,
                                                                                                                  ),
                                                                                                                  Container(
                                                                                                                    width: size.width * 0.2,
                                                                                                                    child: Text(
                                                                                                                      "${etherGas.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                                      maxLines: 3,
                                                                                                                      textAlign: TextAlign.end,
                                                                                                                      style: GoogleFonts.montserrat(
                                                                                                                        textStyle: const TextStyle(
                                                                                                                          overflow: TextOverflow.ellipsis,
                                                                                                                          color: secondaryColor,
                                                                                                                          fontSize: 15,
                                                                                                                          fontWeight: FontWeight.w300,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                            ),
                                                                                                            const SizedBox(
                                                                                                              height: 10,
                                                                                                            ),
                                                                                                            // Estimate gas amount
                                                                                                            Container(
                                                                                                              child: Row(
                                                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                children: [
                                                                                                                  Container(
                                                                                                                    width: size.width * 0.2,
                                                                                                                    child: Text(
                                                                                                                      "Estimate gas amount",
                                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                                      maxLines: 5,
                                                                                                                      textAlign: TextAlign.start,
                                                                                                                      style: GoogleFonts.montserrat(
                                                                                                                        textStyle: const TextStyle(
                                                                                                                          overflow: TextOverflow.ellipsis,
                                                                                                                          color: secondaryColor,
                                                                                                                          fontSize: 13,
                                                                                                                          fontWeight: FontWeight.w300,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                  SizedBox(
                                                                                                                    width: 5,
                                                                                                                  ),
                                                                                                                  Container(
                                                                                                                    width: size.width * 0.2,
                                                                                                                    child: Text(
                                                                                                                      "$estimateGas",
                                                                                                                      overflow: TextOverflow.ellipsis,
                                                                                                                      maxLines: 3,
                                                                                                                      textAlign: TextAlign.end,
                                                                                                                      style: GoogleFonts.montserrat(
                                                                                                                        textStyle: const TextStyle(
                                                                                                                          overflow: TextOverflow.ellipsis,
                                                                                                                          color: secondaryColor,
                                                                                                                          fontSize: 15,
                                                                                                                          fontWeight: FontWeight.w300,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ],
                                                                                                              ),
                                                                                                            ),
                                                                                                            const SizedBox(
                                                                                                              height: 10,
                                                                                                            ),
                                                                                                            Row(
                                                                                                              children: [
                                                                                                                Icon(
                                                                                                                  CupertinoIcons.exclamationmark_circle,
                                                                                                                  color: secondaryColor,
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: 5,
                                                                                                                ),
                                                                                                                Expanded(
                                                                                                                  child: Text(
                                                                                                                    "Estimate gas price might be significantly higher that the actual price",
                                                                                                                    overflow: TextOverflow.ellipsis,
                                                                                                                    maxLines: 5,
                                                                                                                    textAlign: TextAlign.start,
                                                                                                                    style: GoogleFonts.montserrat(
                                                                                                                      textStyle: const TextStyle(
                                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                                        color: secondaryColor,
                                                                                                                        fontSize: 10,
                                                                                                                        fontWeight: FontWeight.w300,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                            const SizedBox(
                                                                                                              height: 10,
                                                                                                            ),
                                                                                                            Divider(
                                                                                                              color: secondaryColor,
                                                                                                            ),
                                                                                                            Row(
                                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                              children: [
                                                                                                                Container(
                                                                                                                  width: size.width * 0.2,
                                                                                                                  child: Text(
                                                                                                                    "Total gas price",
                                                                                                                    overflow: TextOverflow.ellipsis,
                                                                                                                    maxLines: 3,
                                                                                                                    textAlign: TextAlign.start,
                                                                                                                    style: GoogleFonts.montserrat(
                                                                                                                      textStyle: const TextStyle(
                                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                                        color: secondaryColor,
                                                                                                                        fontSize: 15,
                                                                                                                        fontWeight: FontWeight.w600,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: 5,
                                                                                                                ),
                                                                                                                Container(
                                                                                                                  width: size.width * 0.2,
                                                                                                                  child: Text(
                                                                                                                    "${(etherGas.getValueInUnit(EtherUnit.gwei) * estimateGas.toDouble()).toStringAsFixed(2)} GWEI",
                                                                                                                    overflow: TextOverflow.ellipsis,
                                                                                                                    maxLines: 3,
                                                                                                                    textAlign: TextAlign.end,
                                                                                                                    style: GoogleFonts.montserrat(
                                                                                                                      textStyle: const TextStyle(
                                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                                        color: secondaryColor,
                                                                                                                        fontSize: 15,
                                                                                                                        fontWeight: FontWeight.w600,
                                                                                                                      ),
                                                                                                                    ),
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                      ),
                                                                                                      SizedBox(
                                                                                                        height: 20,
                                                                                                      ),
                                                                                                      RoundedButton(
                                                                                                        pw: 250,
                                                                                                        ph: 45,
                                                                                                        text: 'CONFIRM',
                                                                                                        press: () async {
                                                                                                          Navigator.of(context).pop(true);
                                                                                                          Navigator.of(context).pop(true);
                                                                                                          await firestore.FirebaseFirestore.instance.collection('invoices').doc(invoice.id).update({
                                                                                                            'status': '1',
                                                                                                            'from': publicKey,
                                                                                                          });
                                                                                                          BigInt chainId = await web3client!.getChainId();
                                                                                                          firestore.DocumentSnapshot invoiceCoin = await firestore.FirebaseFirestore.instance.collection('stablecoins').doc(invoice.get('coinId')).get();
                                                                                                          DeployedContract invoiceCoinContract = DeployedContract(ContractAbi.fromJson(jsonEncode(jsonDecode(invoiceCoin.get('contract_abi'))), "UZSOImplementation"), EthereumAddress.fromHex(invoiceCoin.id));

                                                                                                          Transaction transaction = await Transaction.callContract(
                                                                                                            contract: invoiceCoinContract,
                                                                                                            function: invoiceCoinContract.function('transfer'),
                                                                                                            parameters: [
                                                                                                              EthereumAddress.fromHex(invoice.get('to')),
                                                                                                              BigInt.from((double.parse(invoice.get('amount')) * BigInt.from(pow(10, 18)).toDouble())),
                                                                                                            ],
                                                                                                          );
                                                                                                          String notifTitle = "Success 2371617";
                                                                                                          String notifBody = "Transaction made";
                                                                                                          Color notifColor = Colors.green;

                                                                                                          // ignore: unused_local_variable
                                                                                                          bool txSuccess = true;
                                                                                                          String transactionResult = await web3client!
                                                                                                              .sendTransaction(
                                                                                                            EthPrivateKey.fromHex(privateKey),
                                                                                                            transaction,
                                                                                                            chainId: chainId.toInt(),
                                                                                                          )
                                                                                                              .onError((error, stackTrace) {
                                                                                                            notifTitle = "Error";
                                                                                                            notifBody = error.toString() == 'RPCError: got code -32000 with msg "gas required exceeds allowance (0)".' ? "Not enough gas. Buy ether" : error.toString();
                                                                                                            notifColor = Colors.red;
                                                                                                            txSuccess = false;
                                                                                                            showNotification(notifTitle, notifBody, notifColor);
                                                                                                            return error.toString();
                                                                                                          });
                                                                                                          if (txSuccess) {
                                                                                                            checkTx(transactionResult, invoice);
                                                                                                          }
                                                                                                        },
                                                                                                        color: secondaryColor,
                                                                                                        textColor: darkPrimaryColor,
                                                                                                      ),
                                                                                                      const SizedBox(
                                                                                                        height: 20,
                                                                                                      ),
                                                                                                    ],
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                              actions: <Widget>[
                                                                                                TextButton(
                                                                                                  onPressed: () {
                                                                                                    Navigator.of(context).pop(false);
                                                                                                    Navigator.of(context).pop(false);
                                                                                                  },
                                                                                                  child: const Text(
                                                                                                    'Cancel',
                                                                                                    style: TextStyle(color: Colors.red),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      });
                                                                                } else {
                                                                                  Navigator.of(context).pop(true);
                                                                                  showNotification('Failed', 'Invoice already paid', Colors.red);
                                                                                }
                                                                              } else {
                                                                                Navigator.of(context).pop(true);
                                                                                showNotification('Failed', 'Wrong network', Colors.red);
                                                                              }
                                                                            } else {
                                                                              Navigator.of(context).pop(true);
                                                                              showNotification('Failed', 'Invoice not found', Colors.red);
                                                                            }
                                                                          } catch (e) {
                                                                            Navigator.of(context).pop(true);
                                                                            showNotification(
                                                                                'Failed',
                                                                                'Something went wrong',
                                                                                Colors.red);
                                                                          }
                                                                        }
                                                                      },
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 10,
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
                                                                      .pop(
                                                                          false),
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
                                              CupertinoIcons.qrcode,
                                              color: darkPrimaryColor,
                                            ),
                                          ),
                                          Text(
                                            "Invoice",
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

                                      // Send button
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

                                              Navigator.push(
                                                context,
                                                SlideRightRoute(
                                                  page: SendOzodScreen(
                                                    web3client: web3client!,
                                                    walletIndex:
                                                        selectedWalletIndex,
                                                    networkId:
                                                        selectedNetworkId,
                                                    coin: {
                                                      'id': uzsoFirebase!.id,
                                                      'contract': uzsoContract,
                                                      'symbol': uzsoFirebase!
                                                          .get('symbol'),
                                                    },
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

                                      // Receive button
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
                                                          StateSetter
                                                              setState) {
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
                                                              width:
                                                                  size.width *
                                                                      0.9,
                                                              height:
                                                                  size.height *
                                                                      0.4,
                                                              margin: EdgeInsets
                                                                  .all(10),
                                                              child: Column(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                            20),
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
                                                                          style:
                                                                              GoogleFonts.montserrat(
                                                                            textStyle:
                                                                                const TextStyle(
                                                                              color: secondaryColor,
                                                                              fontSize: 15,
                                                                              fontWeight: FontWeight.w500,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width:
                                                                            30,
                                                                        child:
                                                                            IconButton(
                                                                          padding:
                                                                              EdgeInsets.zero,
                                                                          onPressed:
                                                                              () async {
                                                                            await Clipboard.setData(ClipboardData(text: publicKey));
                                                                            showNotification(
                                                                                'Copied',
                                                                                'Public key copied',
                                                                                greenColor);
                                                                          },
                                                                          icon:
                                                                              Icon(
                                                                            CupertinoIcons.doc,
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
                                                                      .pop(
                                                                          false),
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

                                      // Buy button
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
                                              if (kIsWeb) {
                                                showNotification(
                                                    'Coming soon',
                                                    'Not supported for web',
                                                    Colors.orange);
                                              } else {
                                                showDialog(
                                                    barrierDismissible: false,
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            StateSetter
                                                                setState) {
                                                          return AlertDialog(
                                                            backgroundColor:
                                                                lightPrimaryColor,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20.0),
                                                            ),
                                                            title: const Text(
                                                              'Method',
                                                              style: TextStyle(
                                                                  color:
                                                                      darkPrimaryColor),
                                                            ),
                                                            content:
                                                                SingleChildScrollView(
                                                              child: Container(
                                                                margin:
                                                                    EdgeInsets
                                                                        .all(
                                                                            10),
                                                                child: Column(
                                                                  children: [
                                                                    // PayMe
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceEvenly,
                                                                      children: [
                                                                        Image
                                                                            .asset(
                                                                          "assets/images/payme.png",
                                                                          width:
                                                                              80,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              RoundedButton(
                                                                            pw: 250,
                                                                            ph: 45,
                                                                            text:
                                                                                'PayMe',
                                                                            press:
                                                                                () {
                                                                              Navigator.push(
                                                                                context,
                                                                                SlideRightRoute(
                                                                                  page: BuyOzodPaymeScreen(
                                                                                    walletIndex: selectedWalletIndex,
                                                                                    web3client: web3client!,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                            color:
                                                                                secondaryColor,
                                                                            textColor:
                                                                                darkPrimaryColor,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          20,
                                                                    ),
                                                                    // Octo
                                                                    Row(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .spaceEvenly,
                                                                      children: [
                                                                        Image
                                                                            .asset(
                                                                          "assets/images/octo.png",
                                                                          width:
                                                                              80,
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              RoundedButton(
                                                                            pw: 250,
                                                                            ph: 45,
                                                                            text:
                                                                                'Octo',
                                                                            press:
                                                                                () {
                                                                              Navigator.push(
                                                                                context,
                                                                                SlideRightRoute(
                                                                                  page: BuyOzodOctoScreen(
                                                                                    walletIndex: selectedWalletIndex,
                                                                                    web3client: web3client!,
                                                                                    selectedNetworkId: selectedNetworkId,
                                                                                    contract: uzsoContract!,
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            },
                                                                            color:
                                                                                Colors.blue,
                                                                            textColor:
                                                                                whiteColor,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          20,
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
                                                                        .pop(
                                                                            false),
                                                                child:
                                                                    const Text(
                                                                  'Ok',
                                                                  style: TextStyle(
                                                                      color:
                                                                          darkPrimaryColor),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    });
                                              }
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
                                const SizedBox(height: 20),

                                // Gas Indicator
                                Container(
                                  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                                  width: size.width * 0.8,
                                  // height: 200,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gasTxsLeft < 1
                                          ? [
                                              Colors.red,
                                              Colors.orange,
                                            ]
                                          : [
                                              Colors.blue,
                                              Colors.green,
                                            ],
                                    ),
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    childrenPadding: EdgeInsets.zero,
                                    expandedCrossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    expandedAlignment: Alignment.center,
                                    trailing: SizedBox.shrink(),
                                    backgroundColor: Colors.transparent,
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Gas Indicator",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          maxLines: 2,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: whiteColor,
                                              fontSize: 25,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          "~ ${NumberFormat.compact().format(gasTxsLeft)} Txs left",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          maxLines: 2,
                                          style: GoogleFonts.montserrat(
                                            textStyle: const TextStyle(
                                              color: whiteColor,
                                              fontSize: 23,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Center(
                                          child: RoundedButton(
                                            pw: 150,
                                            ph: 35,
                                            text: 'Top up gas',
                                            press: () {
                                              if (kIsWeb) {
                                                showNotification(
                                                    'Coming soon',
                                                    'Not supported for web',
                                                    Colors.orange);
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  SlideRightRoute(
                                                      page: BuyCryptoScreen(
                                                    walletIndex:
                                                        selectedWalletIndex,
                                                    web3client: web3client!,
                                                  )),
                                                );
                                              }
                                            },
                                            color: whiteColor,
                                            textColor: darkPrimaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 20,
                                          ),
                                          Text(
                                            "${gasBalance!.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            maxLines: 4,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Divider(
                                            color: whiteColor,
                                          ),
                                          Text(
                                            "Gas price: ${estimateGasPrice.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            maxLines: 4,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            "Estimate gas amount: $estimateGasAmount",
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            maxLines: 4,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Text(
                                            "Total gas needed: ${(estimateGasPrice.getValueInUnit(EtherUnit.gwei) * estimateGasAmount.toDouble()).toStringAsFixed(2)} GWEI",
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            maxLines: 4,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: whiteColor,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 20,
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
                                        width: size.width * 0.9,
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
                                                    color: secondaryColor,
                                                    fontSize: 40,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 30,
                                            ),
                                            for (Map tx
                                                in selectedWalletTxs.take(5))
                                              CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () {
                                                  showDialog(
                                                      barrierDismissible: true,
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return StatefulBuilder(
                                                          builder: (context,
                                                              StateSetter
                                                                  setState) {
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
                                                                'Transaction',
                                                                style: TextStyle(
                                                                    color:
                                                                        secondaryColor),
                                                              ),
                                                              content:
                                                                  SingleChildScrollView(
                                                                child:
                                                                    Container(
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        "Amount",
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            3,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: GoogleFonts
                                                                            .montserrat(
                                                                          textStyle:
                                                                              const TextStyle(
                                                                            color:
                                                                                secondaryColor,
                                                                            fontSize:
                                                                                25,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      Text(
                                                                        NumberFormat.compact().format(BigInt.parse(tx['value']) /
                                                                            BigInt.from(pow(10,
                                                                                int.parse(tx['tokenDecimal'])))),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            3,
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        style: GoogleFonts
                                                                            .montserrat(
                                                                          textStyle:
                                                                              const TextStyle(
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            color:
                                                                                secondaryColor,
                                                                            fontSize:
                                                                                60,
                                                                            fontWeight:
                                                                                FontWeight.w700,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      Container(
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: tx['contractAddress']),
                                                                                size: 25),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Container(
                                                                              width: 100,
                                                                              child: Text(
                                                                                tx['tokenSymbol'],
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
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                      Container(
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border: Border.all(
                                                                              color: secondaryColor,
                                                                              width: 1.0),
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                        ),
                                                                        padding:
                                                                            EdgeInsets.all(15),
                                                                        child:
                                                                            Column(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            // Date
                                                                            Container(
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Container(
                                                                                    width: size.width * 0.2,
                                                                                    child: Text(
                                                                                      "Date",
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 3,
                                                                                      textAlign: TextAlign.start,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 5,
                                                                                  ),
                                                                                  Container(
                                                                                    width: size.width * 0.3,
                                                                                    child: Text(
                                                                                      DateFormat.yMMMd().format(DateTime.fromMillisecondsSinceEpoch(int.parse(tx['timeStamp']) * 1000)).toString() + " / " + DateFormat.Hm().format(DateTime.fromMillisecondsSinceEpoch(int.parse(tx['timeStamp']) * 1000)).toString(),
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 2,
                                                                                      textAlign: TextAlign.end,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            // Hash
                                                                            Container(
                                                                              child: CupertinoButton(
                                                                                onPressed: () async {
                                                                                  await Clipboard.setData(
                                                                                    ClipboardData(text: privateKey),
                                                                                  );
                                                                                  showNotification('Copied', 'Copied', greenColor);
                                                                                },
                                                                                padding: EdgeInsets.zero,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: size.width * 0.2,
                                                                                      child: Text(
                                                                                        "Tx Hash",
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 3,
                                                                                        textAlign: TextAlign.start,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: 5,
                                                                                    ),
                                                                                    Container(
                                                                                      width: size.width * 0.3,
                                                                                      child: Text(
                                                                                        tx['hash'],
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                        textAlign: TextAlign.end,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 0,
                                                                            ),
                                                                            // From
                                                                            Container(
                                                                              child: CupertinoButton(
                                                                                onPressed: () async {
                                                                                  await Clipboard.setData(
                                                                                    ClipboardData(text: privateKey),
                                                                                  );
                                                                                  showNotification('Copied', 'Copied', greenColor);
                                                                                },
                                                                                padding: EdgeInsets.zero,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: size.width * 0.2,
                                                                                      child: Text(
                                                                                        "From",
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 3,
                                                                                        textAlign: TextAlign.start,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: 5,
                                                                                    ),
                                                                                    Container(
                                                                                      width: size.width * 0.3,
                                                                                      child: Text(
                                                                                        tx['from'],
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                        textAlign: TextAlign.end,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 0,
                                                                            ),
                                                                            // To
                                                                            Container(
                                                                              child: CupertinoButton(
                                                                                onPressed: () async {
                                                                                  await Clipboard.setData(
                                                                                    ClipboardData(text: privateKey),
                                                                                  );
                                                                                  showNotification('Copied', 'Copied', greenColor);
                                                                                },
                                                                                padding: EdgeInsets.zero,
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Container(
                                                                                      width: size.width * 0.2,
                                                                                      child: Text(
                                                                                        "To",
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                        textAlign: TextAlign.start,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    SizedBox(
                                                                                      width: 5,
                                                                                    ),
                                                                                    Container(
                                                                                      width: size.width * 0.3,
                                                                                      child: Text(
                                                                                        tx['to'],
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        maxLines: 1,
                                                                                        textAlign: TextAlign.end,
                                                                                        style: GoogleFonts.montserrat(
                                                                                          textStyle: const TextStyle(
                                                                                            overflow: TextOverflow.ellipsis,
                                                                                            color: secondaryColor,
                                                                                            fontSize: 15,
                                                                                            fontWeight: FontWeight.w300,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ],
                                                                                ),
                                                                              ),
                                                                            ),

                                                                            const SizedBox(
                                                                              height: 30,
                                                                            ),
                                                                            Divider(
                                                                              color: secondaryColor,
                                                                            ),
                                                                            // Ether gas
                                                                            Container(
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Container(
                                                                                    width: size.width * 0.2,
                                                                                    child: Text(
                                                                                      "Gas price",
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 3,
                                                                                      textAlign: TextAlign.start,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 5,
                                                                                  ),
                                                                                  Container(
                                                                                    width: size.width * 0.2,
                                                                                    child: Text(
                                                                                      "${EtherAmount.fromUnitAndValue(EtherUnit.wei, tx['gasPrice']).getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 3,
                                                                                      textAlign: TextAlign.end,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            // Gas used
                                                                            Container(
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Container(
                                                                                    width: size.width * 0.2,
                                                                                    child: Text(
                                                                                      "Gas used",
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 5,
                                                                                      textAlign: TextAlign.start,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 13,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: 5,
                                                                                  ),
                                                                                  Container(
                                                                                    width: size.width * 0.2,
                                                                                    child: Text(
                                                                                      "${tx['gasUsed']}",
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      maxLines: 3,
                                                                                      textAlign: TextAlign.end,
                                                                                      style: GoogleFonts.montserrat(
                                                                                        textStyle: const TextStyle(
                                                                                          overflow: TextOverflow.ellipsis,
                                                                                          color: secondaryColor,
                                                                                          fontSize: 15,
                                                                                          fontWeight: FontWeight.w300,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height: 10,
                                                                            ),
                                                                            Divider(
                                                                              color: secondaryColor,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Container(
                                                                                  width: size.width * 0.2,
                                                                                  child: Text(
                                                                                    "Total gas",
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    maxLines: 3,
                                                                                    textAlign: TextAlign.start,
                                                                                    style: GoogleFonts.montserrat(
                                                                                      textStyle: const TextStyle(
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        color: secondaryColor,
                                                                                        fontSize: 15,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width: 5,
                                                                                ),
                                                                                Container(
                                                                                  width: size.width * 0.2,
                                                                                  child: Text(
                                                                                    "${(EtherAmount.fromUnitAndValue(EtherUnit.wei, tx['gasPrice']).getValueInUnit(EtherUnit.gwei) * double.parse(tx['gasUsed'])).toStringAsFixed(2)} GWEI",
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                    maxLines: 3,
                                                                                    textAlign: TextAlign.end,
                                                                                    style: GoogleFonts.montserrat(
                                                                                      textStyle: const TextStyle(
                                                                                        overflow: TextOverflow.ellipsis,
                                                                                        color: secondaryColor,
                                                                                        fontSize: 15,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            20,
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              actions: <Widget>[
                                                                TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false);
                                                                  },
                                                                  child:
                                                                      const Text(
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
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: secondaryColor,
                                                        width: 1.0),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  margin: EdgeInsets.only(
                                                      bottom: 10),
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
                                                                        secondaryColor,
                                                                  )
                                                                : Icon(
                                                                    CupertinoIcons
                                                                        .arrow_down_circle_fill,
                                                                    color: Colors
                                                                        .green,
                                                                  ),
                                                            Text(
                                                              "${DateFormat.MMMd().format(DateTime.fromMillisecondsSinceEpoch(int.parse(tx['timeStamp']) * 1000))}",
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
                                                                      secondaryColor,
                                                                  fontSize: 9,
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
                                                                            secondaryColor,
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
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            25,
                                                                        fontWeight:
                                                                            FontWeight.w700,
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
                                                                            secondaryColor,
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
                                                                            secondaryColor,
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
                                                              !selectedWalletAssetsData
                                                                      .keys
                                                                      .contains(tx[
                                                                          'to'])
                                                                  ? NumberFormat.compact().format(EtherAmount.fromUnitAndValue(
                                                                          EtherUnit
                                                                              .wei,
                                                                          tx[
                                                                              'value'])
                                                                      .getValueInUnit(
                                                                          selectedEtherUnit))
                                                                  : "N/A",
                                                              maxLines: 2,
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
                                                                      secondaryColor,
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
                                                                      .contains(tx[
                                                                          'to'])
                                                                  ? "UZSO"
                                                                      .toString()
                                                                  : selectedWalletAssetsData[
                                                                      tx['to']],
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
                                                                      secondaryColor,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  void checkTx(String tx, firestore.DocumentSnapshot invoice) async {
    setState(() {
      loadingString = "Pending transaction";
      loading = true;
    });
    print("RGERG");
    print(tx);
    try {
      var timeCounter = 0;
      timer = Timer.periodic(Duration(seconds: 10), (Timer t) async {
        timeCounter++;
        TransactionReceipt? txReceipt =
            await web3client!.getTransactionReceipt(tx);
        timeCounter++;
        print("TXREC");
        print(txReceipt);
        if (timeCounter >= 60) {
          showNotification('Timeout', 'Timeout. Transaction is still pending',
              Colors.orange);
          timer!.cancel();
          setState(() {
            loading = false;
          });
        }
        if (txReceipt != null) {
          timer!.cancel();
          if (txReceipt.status!) {
            await firestore.FirebaseFirestore.instance
                .collection('invoices')
                .doc(invoice.id)
                .update({
              'status': '10',
              'from': publicKey,
              'txReceipt': txReceipt.contractAddress,
            });
            showNotification('Success', 'Transaction made', Colors.green);
            _refresh();
          } else {
            showNotification('Not Verified',
                'Transaction was not verified. Check later', Colors.orange);
          }
          setState(() {
            loading = false;
          });
        }
      });
    } catch (e) {
      showNotification('Failed', e.toString(), Colors.red);
      setState(() {
        loading = false;
      });
    }
  }
}
