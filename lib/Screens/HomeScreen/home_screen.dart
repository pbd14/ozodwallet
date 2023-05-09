import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:glass/glass.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_login_screen.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_signup_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/BuyOzodScreen/buy_ozod_octo_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/BuyOzodScreen/buy_ozod_payme_screen.dart';
import 'package:blur/blur.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_ozod_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/create_wallet_screen.dart';
import 'package:ozodwallet/Screens/WalletScreen/import_wallet_screen.dart';
import 'package:ozodwallet/Services/auth/auth_service.dart';
import 'package:ozodwallet/Services/coingecko_api_service.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/Widgets/expansion_tile.dart' as custom;
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class HomeScreen extends StatefulWidget {
  String error;
  Function mainScreenRefreshFunction;
  HomeScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.mainScreenRefreshFunction,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool loading = true;
  String? loadingString;
  Timer? timer;
  ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  SharedPreferences? sharedPreference;

  // Tutorial
  late TutorialCoachMark tutorialCoachMark;
  GlobalKey keyButton1 = GlobalKey();
  GlobalKey keyButton2 = GlobalKey();
  GlobalKey keyButton3 = GlobalKey();
  void createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: lightPrimaryColor,
      textStyleSkip: TextStyle(color: darkPrimaryColor),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () async {
        sharedPreference = await SharedPreferences.getInstance();
        sharedPreference!.setBool("isHomeTutorial", true);
      },
      onClickTarget: (target) {
        if (target.keyTarget == keyButton2) {
          _scrollController.animateTo(200,
              duration: Duration(milliseconds: 500), curve: Curves.ease);
        }
        // if (target.keyTarget == keyButton3) {
        //   _scrollController.animateTo(MediaQuery.of(context).size.height * 0.5,
        //       duration: Duration(milliseconds: 500), curve: Curves.ease);
        // }
      },
      onClickTargetWithTapPosition: (target, tapDetails) {},
      onClickOverlay: (target) {},
      onSkip: () {},
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "Target 0",
        keyTarget: keyButton1,
        shape: ShapeLightFocus.RRect,
        radius: 5,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Blockchain network",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: darkPrimaryColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        "There are many blockchain networks, which work separately. Think of them as Visa and MasterCard in traditional finance. We recommend POLYGON, because of its low fees",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: darkPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Target 1",
        keyTarget: keyButton2,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Wallet",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: darkPrimaryColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Text(
                        "This is your wallet on selected blockchain network. Here you can see you balance of UZSO. Remember: 1 UZSO = 1000 UZS. At the bottom is your public key",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: darkPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Target 3",
        keyTarget: keyButton3,
        shape: ShapeLightFocus.RRect,
        radius: 5,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Gas Indicator",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: darkPrimaryColor,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        "Gas indicator shows how much gas is left. To get more gas, you need to buy cryptocurrency of selected blockchain network. Remember that gas price may vary",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 10,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: darkPrimaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    return targets;
  }

  void showTutorial() {
    tutorialCoachMark.show(context: context);
  }

  // Local data

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
    'aurora_testnet': {
      'image': "assets/images/card_aurora.png",
      'color': whiteColor,
    },
  };

  // Ozod ID
  User? ozodIdUser;
  firestore.DocumentSnapshot? ozodIdFirestoreUser;
  StreamSubscription<User?>? authStream;
  List ozodIdWallets = [];

  // Wallet
  Web3Wallet wallet = Web3Wallet(
      privateKey: "Loading",
      publicKey: "Loading",
      name: "Loading",
      localIndex: "1");
  String selectedWalletIndex = "1";
  String importingAssetContractAddress = "";
  String importingAssetContractSymbol = "";
  String selectedNetworkId = "goerli";
  String selectedNetworkName = "Goerli Testnet";
  double selectedNetworkVsUsd = 0;

  // Settings
  bool showSeed = false;
  String editedName = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  // Blockchain data
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

  // Firebase Firestore
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
    wallet = Web3Wallet(
        privateKey: "Loading",
        publicKey: "Loading",
        name: "Loading",
        localIndex: "1");
    loadingString = null;
    showSeed = false;
    importingAssetContractAddress = "";
    importingAssetContractSymbol = "";
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
    ozodIdWallets = [];

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

  Future<double> getSelectedNetworkVsUsd() async {
    double result;
    switch (selectedNetworkId) {
      case 'goerli':
        result = await CoingeckoApiService().getEthVsUsd();
        break;
      case 'mainnet':
        result = await CoingeckoApiService().getEthVsUsd();
        break;
      case 'polygon':
        result = await CoingeckoApiService().getMaticVsUsd();
        break;
      case 'polygon_mumbai':
        result = await CoingeckoApiService().getMaticVsUsd();
        break;
      default:
        result = await CoingeckoApiService().getEthVsUsd();
    }
    return result;
  }

  Future<void> manageTutorial() async {
    sharedPreference = await SharedPreferences.getInstance();
    bool? isTutorial = await sharedPreference!.getBool("isHomeTutorial");
    if (isTutorial == null) {
      createTutorial();
      Future.delayed(Duration(seconds: 7), showTutorial);
    } else if (!isTutorial) {
      createTutorial();
      Future.delayed(Duration(seconds: 7), showTutorial);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> manageFirebaseFirestore() async {
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
    walletFirebase = await firestore.FirebaseFirestore.instance
        .collection('wallets')
        .doc(wallet.valueAddress.toString())
        .get();
  }

  Future<void> manageOzodId() async {
    if (ozodIdUser != null) {
      ozodIdFirestoreUser = await firestore.FirebaseFirestore.instance
          .collection('ozod_id_accounts')
          .doc(ozodIdUser!.uid)
          .get();
      ozodIdWallets = ozodIdFirestoreUser!.get('wallets') ?? [];
    }
  }

  Future<Map> manageBlockchainNetworkData() async {
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

    web3client = Web3Client(
        EncryptionService().dec(appDataNodes!.get(appData!
            .get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['node'])),
        httpClient);

    if (jsonDecode(uzsoFirebase!.get('contract_abi')) != null) {
      uzsoContract = DeployedContract(
          ContractAbi.fromJson(
              jsonEncode(jsonDecode(uzsoFirebase!.get('contract_abi'))),
              "UZSOImplementation"),
          EthereumAddress.fromHex(uzsoFirebase!.id));
    }

    // get balance
    final responseBalance = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=account&action=tokenbalance&contractaddress=${uzsoFirebase!.id}&address=${wallet.publicKey}&tag=latest&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_api']))}"));
    dynamic jsonBodyBalance = jsonDecode(responseBalance.body);
    EtherAmount valueBalance =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, jsonBodyBalance['result']);

    // get txs
    final response = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=account&action=tokentx&contractaddress=${uzsoFirebase!.id}&address=${wallet.publicKey}&page=1&offset=10&startblock=0&endblock=99999999&sort=desc&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_OZOD_NETWORKS')[selectedNetworkId]['scan_api']))}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = jsonBody['result'];

    // remove duplicates
    final jsonList = valueTxs.map((item) => jsonEncode(item)).toList();
    final uniqueJsonList = jsonList.toSet().toList();
    valueTxs = uniqueJsonList.map((item) => jsonDecode(item)).toList();

    // Get gas indicator data
    estimateGasPrice = await web3client!.getGasPrice();
    estimateGasAmount = await web3client!.estimateGas(
      sender: wallet.valueAddress,
    );

    // Get selected network vs usd
    selectedNetworkVsUsd = await getSelectedNetworkVsUsd();
    gasBalance = await web3client!.getBalance(wallet.valueAddress);

    return {
      'valueBalance': valueBalance,
      'valueTxs': valueTxs,
    };
  }

  Future<void> prepare() async {
    try {
      // Tutorial
      await manageTutorial();

      // Wallets
      wallets = await SafeStorageService().getAllWallets();
      wallet = await SafeStorageService().getWallet(selectedWalletIndex);
      await getDataFromSP();

      // Firebase app data
      await manageFirebaseFirestore();

      // Ozod ID
      await manageOzodId();

      // Blockchain data
      Map blockchainData = await manageBlockchainNetworkData();

      setState(() {
        blockchainData['valueBalance'] != null
            ? selectedWalletBalance = blockchainData['valueBalance']
            : selectedWalletBalance = EtherAmount.zero();
        blockchainData['valueTxs'] != null
            ? selectedWalletTxs = blockchainData['valueTxs'].toSet().toList()
            : selectedWalletTxs = [];
        gasTxsLeft = (gasBalance!.getValueInUnit(EtherUnit.gwei) /
                (estimateGasPrice.getValueInUnit(EtherUnit.gwei) *
                    estimateGasAmount.toDouble()))
            .toDouble();
        loading = false;
      });
    } catch (e) {
      showNotification('Error', 'Error. Try again later', Colors.red);
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    // Ozod ID Auth state listener
    authStream = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          ozodIdUser = user;
        });
      } else {
        ozodIdUser = user;
      }
    });
    prepare();
    super.initState();
  }

  @override
  void dispose() {
    if (authStream != null) {
      authStream!.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
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
                                          address: wallet.publicKey),
                                      size: 20),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      wallet.name,
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
                                                        wallet.privateKey,
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
                                                ClipboardData(
                                                    text: wallet.privateKey),
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
                                              initialValue: wallet.name,
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
                    tileColor: ozodIdColor2,
                    leading: Image.asset(
                      'assets/icons/logoAuth300.png',
                      width: 30,
                      height: 30,
                      // scale: 10,
                    ).frosted(
                      frostColor: ozodIdColor1,
                      blur: 10,
                      borderRadius: BorderRadius.circular(5),
                      padding: EdgeInsets.all(0),
                    ),
                    title: Text(
                      "Ozod ID",
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                      maxLines: 2,
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return AlertDialog(
                                  backgroundColor: ozodIdColor2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  // title: const Text(
                                  //   'Delete all data',
                                  //   style: TextStyle(color: secondaryColor),
                                  // ),
                                  content: SingleChildScrollView(
                                    child: Center(
                                      child: ozodIdUser != null
                                          ? Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/logoAuth300.png',
                                                      width: 30,
                                                      height: 30,
                                                      // scale: 10,
                                                    ).frosted(
                                                      frostColor: ozodIdColor1,
                                                      blur: 10,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      padding:
                                                          EdgeInsets.all(0),
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Text(
                                                      'Ozod ID',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: whiteColor,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Center(
                                                  child: Container(
                                                    padding: EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: ozodIdColor1,
                                                          width: 1.0),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(
                                                          height: 20,
                                                        ),
                                                        Text(
                                                          "ID: ${ozodIdUser!.uid}",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 4,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  ozodIdColor1,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        Divider(
                                                          color: ozodIdColor1,
                                                        ),
                                                        Text(
                                                          "Session: ${ozodIdUser!.email}",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 4,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  ozodIdColor1,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 5,
                                                        ),
                                                        Text(
                                                          "Email Verified: ${ozodIdUser!.emailVerified ? 'Yes' : 'No'}",
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.start,
                                                          maxLines: 4,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  ozodIdColor1,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 20,
                                                        ),
                                                        !ozodIdUser!
                                                                .emailVerified
                                                            ? Center(
                                                                child:
                                                                    RoundedButton(
                                                                  pw: 200,
                                                                  ph: 40,
                                                                  text:
                                                                      'Resend verification',
                                                                  press:
                                                                      () async {
                                                                    bool
                                                                        isError =
                                                                        false;
                                                                    FirebaseAuth
                                                                        .instance
                                                                        .currentUser!
                                                                        .sendEmailVerification()
                                                                        .catchError(
                                                                            (error) {
                                                                      isError =
                                                                          true;
                                                                      showNotification(
                                                                          'Failed',
                                                                          'Failed to send email',
                                                                          Colors
                                                                              .red);
                                                                    }).whenComplete(
                                                                            () {
                                                                      if (!isError) {
                                                                        showNotification(
                                                                            'Success',
                                                                            'Email sent',
                                                                            greenColor);
                                                                      }
                                                                    });
                                                                  },
                                                                  color:
                                                                      ozodIdColor1,
                                                                  textColor:
                                                                      ozodIdColor2,
                                                                ),
                                                              )
                                                            : Container(),
                                                        SizedBox(
                                                          height: !ozodIdUser!
                                                                  .emailVerified
                                                              ? 20
                                                              : 0,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20),
                                                  child: RoundedButton(
                                                    pw: 250,
                                                    ph: 45,
                                                    text: 'Sign Out',
                                                    press: () {
                                                      showDialog(
                                                        barrierDismissible:
                                                            false,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            backgroundColor:
                                                                ozodIdColor2,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20.0),
                                                            ),
                                                            // title: Text(
                                                            //     Languages.of(context).profileScreenSignOut),
                                                            // content: Text(
                                                            //     Languages.of(context)!.profileScreenWantToLeave),
                                                            title: const Text(
                                                              'Sign Out?',
                                                              style: TextStyle(
                                                                  color:
                                                                      ozodIdColor1),
                                                            ),
                                                            content: const Text(
                                                              'Sure?',
                                                              style: TextStyle(
                                                                  color:
                                                                      ozodIdColor1),
                                                            ),
                                                            actions: <Widget>[
                                                              TextButton(
                                                                onPressed: () {
                                                                  // prefs.setBool('local_auth', false);
                                                                  // prefs.setString('local_password', '');
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          true);
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          true);
                                                                  AuthService()
                                                                      .signOut(
                                                                          context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                  'Yes',
                                                                  style: TextStyle(
                                                                      color:
                                                                          ozodIdColor1),
                                                                ),
                                                              ),
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(
                                                                            false),
                                                                child:
                                                                    const Text(
                                                                  'No',
                                                                  style: TextStyle(
                                                                      color: Colors
                                                                          .red),
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    },
                                                    color: Colors.red,
                                                    textColor: whiteColor,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Image.asset(
                                                      'assets/icons/logoAuth300.png',
                                                      width: 40,
                                                      height: 40,
                                                      // scale: 10,
                                                    ),
                                                    Text(
                                                      'Ozod ID',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: whiteColor,
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 30,
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20),
                                                  child: RoundedButton(
                                                    pw: 250,
                                                    ph: 45,
                                                    text: 'Log In',
                                                    press: () {
                                                      setState(() {
                                                        loading = true;
                                                      });
                                                      Navigator.of(context)
                                                          .pop(true);
                                                      Navigator.push(
                                                        context,
                                                        SlideRightRoute(
                                                          page:
                                                              EmailLoginScreen(),
                                                        ),
                                                      );
                                                      setState(() {
                                                        loading = false;
                                                      });
                                                    },
                                                    color: ozodIdColor1,
                                                    textColor: darkPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 20),
                                                  child: RoundedButton(
                                                    pw: 250,
                                                    ph: 45,
                                                    text: 'Sign Up',
                                                    press: () {
                                                      setState(() {
                                                        loading = true;
                                                      });
                                                      Navigator.of(context)
                                                          .pop(true);
                                                      Navigator.push(
                                                        context,
                                                        SlideRightRoute(
                                                          page:
                                                              EmailSignUpScreen(),
                                                        ),
                                                      );

                                                      setState(() {
                                                        loading = false;
                                                      });
                                                    },
                                                    color: ozodIdColor2,
                                                    textColor: whiteColor,
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
                                        'Cancel',
                                        style: TextStyle(color: ozodIdColor1),
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
                                                    AuthService()
                                                        .signOut(context);
                                                    widget
                                                        .mainScreenRefreshFunction();
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
              child: Stack(
                children: [
                  CustomScrollView(
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
                                      key: keyButton1,
                                      margin:
                                          EdgeInsets.symmetric(horizontal: 40),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(
                                            errorBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(40.0),
                                              borderSide: BorderSide(
                                                  color: Colors.red,
                                                  width: 1.0),
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
                                          borderRadius:
                                              BorderRadius.circular(30.0),
                                          dropdownColor: lightPrimaryColor,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: secondaryColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            vertical: 10),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
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
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 2,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            textStyle:
                                                                const TextStyle(
                                                              color:
                                                                  darkPrimaryColor,
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
                                                ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20),

                                    // Alerts
                                    if (appData!
                                            .get('AVAILABLE_ETHER_NETWORKS')[
                                        selectedNetworkId]['is_testnet'])
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 40),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.red, width: 1.0),
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
                                                "This is a test blockchain network. Assets in this chain do not have real value",
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 5,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                "You ran out of gas. Buy more coins",
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 5,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    overflow:
                                                        TextOverflow.ellipsis,
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

                                    // Ozod ID
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      width: size.width * 0.8,
                                      // height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color.fromARGB(255, 70, 213, 196),
                                            Color.fromARGB(255, 19, 51, 77),
                                          ],
                                        ),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        child: ozodIdUser != null
                                            ? Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            'assets/icons/logoAuth300.png',
                                                            width: 40,
                                                            height: 40,
                                                            // scale: 10,
                                                          ),
                                                          Text(
                                                            'Ozod ID',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                              textStyle:
                                                                  const TextStyle(
                                                                color:
                                                                    whiteColor,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      ozodIdWallets.contains(
                                                              wallet.publicKey)
                                                          ? CupertinoButton(
                                                              padding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              onPressed: () {
                                                                showDialog(
                                                                  barrierDismissible:
                                                                      false,
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      backgroundColor:
                                                                          ozodIdColor2,
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(20.0),
                                                                      ),
                                                                      // title: Text(
                                                                      //     Languages.of(context).profileScreenSignOut),
                                                                      // content: Text(
                                                                      //     Languages.of(context)!.profileScreenWantToLeave),
                                                                      title:
                                                                          const Text(
                                                                        'Disconnect this wallet from Ozod ID?',
                                                                        style: TextStyle(
                                                                            color:
                                                                                ozodIdColor1),
                                                                      ),
                                                                      content:
                                                                          const Text(
                                                                        'Sure?',
                                                                        style: TextStyle(
                                                                            color:
                                                                                ozodIdColor1),
                                                                      ),
                                                                      actions: <
                                                                          Widget>[
                                                                        TextButton(
                                                                          onPressed:
                                                                              () async {
                                                                            Navigator.of(context).pop(true);
                                                                            setState(() {
                                                                              loading = true;
                                                                            });
                                                                            try {
                                                                              await firestore.FirebaseFirestore.instance.collection('wallets').doc(wallet.valueAddress.toString()).update({
                                                                                'privateKey': '',
                                                                                'ozodIdConnected': false,
                                                                                'ozodIdAccount': '',
                                                                              });
                                                                              await firestore.FirebaseFirestore.instance.collection('ozod_id_accounts').doc(ozodIdUser!.uid).update({
                                                                                'wallets': firestore.FieldValue.arrayRemove([
                                                                                  wallet.publicKey
                                                                                ])
                                                                              });
                                                                              showNotification("Success", "Wallet Disconnected", greenColor);
                                                                            } catch (e) {
                                                                              showNotification("Failed", "Failed. Try again", Colors.red);
                                                                            }

                                                                            _refresh();
                                                                          },
                                                                          child:
                                                                              const Text(
                                                                            'Yes',
                                                                            style:
                                                                                TextStyle(color: ozodIdColor1),
                                                                          ),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () =>
                                                                              Navigator.of(context).pop(false),
                                                                          child:
                                                                              const Text(
                                                                            'No',
                                                                            style:
                                                                                TextStyle(color: Colors.red),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                );
                                                              },
                                                              child: Container(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(5),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color:
                                                                          ozodIdColor1,
                                                                      width:
                                                                          1.0),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              20),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    CircleAvatar(
                                                                      radius: 5,
                                                                      backgroundColor:
                                                                          lightPrimaryColor,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    Text(
                                                                      'Connected',
                                                                      style: GoogleFonts
                                                                          .montserrat(
                                                                        textStyle:
                                                                            const TextStyle(
                                                                          color:
                                                                              whiteColor,
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
                                                            )
                                                          : Container(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(5),
                                                              decoration:
                                                                  BoxDecoration(
                                                                border: Border.all(
                                                                    color:
                                                                        ozodIdColor1,
                                                                    width: 1.0),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            20),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  CircleAvatar(
                                                                    radius: 5,
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 5,
                                                                  ),
                                                                  Text(
                                                                    'Not Connected',
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        color:
                                                                            whiteColor,
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
                                                    ],
                                                  ),
                                                  Text(
                                                    ozodIdUser!.email!,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    maxLines: 4,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: whiteColor,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: !ozodIdWallets
                                                            .contains(wallet
                                                                .publicKey)
                                                        ? 15
                                                        : 0,
                                                  ),
                                                  !ozodIdWallets.contains(
                                                          wallet.publicKey)
                                                      ? Center(
                                                          child: Container(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        20),
                                                            child:
                                                                RoundedButton(
                                                              pw: 150,
                                                              ph: 35,
                                                              text: 'Connect',
                                                              press: () async {
                                                                setState(() {
                                                                  loading =
                                                                      true;
                                                                });

                                                                // Check if wallet already linked
                                                                bool
                                                                    alreadyLinked =
                                                                    false;
                                                                firestore
                                                                        .DocumentSnapshot
                                                                    firestoreWallet =
                                                                    await firestore
                                                                        .FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'wallets')
                                                                        .doc(wallet
                                                                            .valueAddress
                                                                            .toString())
                                                                        .get();
                                                                try {
                                                                  if (firestoreWallet
                                                                      .get(
                                                                          'ozodIdConnected')) {
                                                                    alreadyLinked =
                                                                        true;
                                                                  }
                                                                } catch (e) {}

                                                                if (!alreadyLinked) {
                                                                  try {
                                                                    await firestore
                                                                        .FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'wallets')
                                                                        .doc(wallet
                                                                            .valueAddress
                                                                            .toString())
                                                                        .update({
                                                                      'privateKey':
                                                                          wallet
                                                                              .encPrivateKey(wallet.privateKey),
                                                                      'ozodIdConnected':
                                                                          true,
                                                                      'ozodIdAccount':
                                                                          ozodIdUser!
                                                                              .uid,
                                                                    });
                                                                    await firestore
                                                                        .FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'ozod_id_accounts')
                                                                        .doc(ozodIdUser!
                                                                            .uid)
                                                                        .update({
                                                                      'wallets':
                                                                          firestore.FieldValue
                                                                              .arrayUnion([
                                                                        wallet
                                                                            .publicKey
                                                                      ])
                                                                    });
                                                                    showNotification(
                                                                        "Success",
                                                                        "Wallet Connected",
                                                                        greenColor);
                                                                  } catch (e) {
                                                                    showNotification(
                                                                        "Failed",
                                                                        "Failed. Try again",
                                                                        Colors
                                                                            .red);
                                                                  }
                                                                } else {
                                                                  showNotification(
                                                                      "Failed",
                                                                      "Wallet is already linked to other account",
                                                                      Colors
                                                                          .red);
                                                                }
                                                                _refresh();
                                                              },
                                                              color: whiteColor,
                                                              textColor:
                                                                  ozodIdColor2,
                                                            ),
                                                          ),
                                                        )
                                                      : Container(),
                                                ],
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                            'assets/icons/logoAuth300.png',
                                                            width: 40,
                                                            height: 40,
                                                            // scale: 10,
                                                          ),
                                                          Text(
                                                            'Ozod ID',
                                                            style: GoogleFonts
                                                                .montserrat(
                                                              textStyle:
                                                                  const TextStyle(
                                                                color:
                                                                    whiteColor,
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        padding:
                                                            EdgeInsets.all(5),
                                                        decoration:
                                                            BoxDecoration(
                                                          border: Border.all(
                                                              color:
                                                                  ozodIdColor1,
                                                              width: 1.0),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(20),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 5,
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                            SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              'Not Connected',
                                                              style: GoogleFonts
                                                                  .montserrat(
                                                                textStyle:
                                                                    const TextStyle(
                                                                  color:
                                                                      whiteColor,
                                                                  fontSize: 10,
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
                                                  SizedBox(
                                                    height: 30,
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20),
                                                    child: RoundedButton(
                                                      pw: 250,
                                                      ph: 45,
                                                      text: 'Log In',
                                                      press: () {
                                                        setState(() {
                                                          loading = true;
                                                        });
                                                        Navigator.push(
                                                          context,
                                                          SlideRightRoute(
                                                            page:
                                                                EmailLoginScreen(),
                                                          ),
                                                        );
                                                        setState(() {
                                                          loading = false;
                                                        });
                                                      },
                                                      color: ozodIdColor1,
                                                      textColor:
                                                          darkPrimaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20),
                                                    child: RoundedButton(
                                                      pw: 250,
                                                      ph: 45,
                                                      text: 'Sign Up',
                                                      press: () {
                                                        setState(() {
                                                          loading = true;
                                                        });
                                                        Navigator.push(
                                                          context,
                                                          SlideRightRoute(
                                                            page:
                                                                EmailSignUpScreen(),
                                                          ),
                                                        );
                                                        setState(() {
                                                          loading = false;
                                                        });
                                                      },
                                                      color: ozodIdColor2,
                                                      textColor: whiteColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ).asGlass(
                                        blurX: 20,
                                        blurY: 20,
                                        clipBorderRadius:
                                            BorderRadius.circular(20.0),
                                        tintColor: darkDarkColor,
                                      ),
                                    ),

                                    // Wallet
                                    kIsWeb
                                        ? Container(
                                            key: keyButton2,
                                            margin: EdgeInsets.fromLTRB(
                                                10, 0, 10, 10),
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
                                                        selectedNetworkId]![
                                                    'image']),
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
                                                        Jazzicon
                                                            .getJazziconData(
                                                                160,
                                                                address: wallet
                                                                    .publicKey),
                                                        size: 20),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Container(
                                                      width: 160,
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child:
                                                            DropdownButton<int>(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      20.0),
                                                          dropdownColor:
                                                              darkPrimaryColor,
                                                          focusColor: cardsData[
                                                                  selectedNetworkId]![
                                                              'color'],
                                                          iconEnabledColor:
                                                              cardsData[
                                                                      selectedNetworkId]![
                                                                  'color'],
                                                          alignment: Alignment
                                                              .centerLeft,
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
                                                              wallet.name,
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
                                                              DropdownMenuItem<
                                                                  int>(
                                                                value: wallets
                                                                        .indexOf(
                                                                            wallet) +
                                                                    1,
                                                                child: Row(
                                                                  children: [
                                                                    Jazzicon.getIconWidget(
                                                                        Jazzicon.getJazziconData(
                                                                            160,
                                                                            address: wallet[
                                                                                'publicKey']),
                                                                        size:
                                                                            15),
                                                                    SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    Container(
                                                                      width:
                                                                          100,
                                                                      child:
                                                                          Text(
                                                                        wallet[wallets.indexOf(wallet) +
                                                                            1],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: TextStyle(
                                                      color: cardsData[
                                                              selectedNetworkId]![
                                                          'color'],
                                                      fontSize: 30,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                                        wallet.publicKey,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
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
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () async {
                                                          await Clipboard.setData(
                                                              ClipboardData(
                                                                  text: wallet
                                                                      .publicKey));
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
                                                        padding:
                                                            EdgeInsets.zero,
                                                        onPressed: () {
                                                          _scaffoldKey
                                                              .currentState!
                                                              .openDrawer();
                                                        },
                                                        icon: Icon(
                                                          CupertinoIcons
                                                              .settings,
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
                                            key: keyButton2,
                                            options: CarouselOptions(
                                              enableInfiniteScroll: false,
                                              initialPage: appData!
                                                  .get(
                                                      'AVAILABLE_OZOD_NETWORKS')
                                                  .keys
                                                  .toList()
                                                  .indexOf(selectedNetworkId),
                                              height: 210.0,
                                              onPageChanged:
                                                  (index, reason) async {
                                                List networkIds = [];
                                                for (String id in appData!
                                                    .get(
                                                        'AVAILABLE_OZOD_NETWORKS')
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
                                                  selectedNetworkName = appData!
                                                          .get(
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
                                                  .get(
                                                      'AVAILABLE_OZOD_NETWORKS')
                                                  .keys)
                                                if (appData!.get(
                                                        'AVAILABLE_OZOD_NETWORKS')[
                                                    networkId]['active'])
                                                  Builder(
                                                    builder:
                                                        (BuildContext context) {
                                                      return Container(
                                                        margin:
                                                            EdgeInsets.fromLTRB(
                                                                10, 0, 10, 10),
                                                        width: 270,
                                                        height: 200,
                                                        padding:
                                                            const EdgeInsets
                                                                    .fromLTRB(
                                                                18, 10, 18, 10),
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          // gradient: const LinearGradient(
                                                          //   begin: Alignment.topLeft,
                                                          //   end: Alignment.bottomRight,
                                                          //   colors: [
                                                          //     Colors.blue,
                                                          //     Colors.green,
                                                          //   ],
                                                          // ),
                                                          image:
                                                              DecorationImage(
                                                            image: AssetImage(
                                                              cardsData[networkId] !=
                                                                      null
                                                                  ? cardsData[
                                                                          networkId]![
                                                                      'image']
                                                                  : "assets/images/card.png",
                                                            ),
                                                            fit: BoxFit
                                                                .fitHeight,
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
                                                                            wallet.publicKey),
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
                                                                          BorderRadius.circular(
                                                                              20.0),
                                                                      dropdownColor:
                                                                          darkPrimaryColor,
                                                                      focusColor:
                                                                          cardsData[networkId]![
                                                                              'color'],
                                                                      iconEnabledColor:
                                                                          cardsData[networkId]![
                                                                              'color'],
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      onChanged:
                                                                          (walletIndex) async {
                                                                        await sharedPreferences!.setString(
                                                                            "selectedWalletIndex",
                                                                            walletIndex.toString());
                                                                        setState(
                                                                            () {
                                                                          selectedWalletIndex =
                                                                              walletIndex.toString();
                                                                          loading =
                                                                              true;
                                                                        });
                                                                        _refresh();
                                                                      },
                                                                      hint:
                                                                          Container(
                                                                        width:
                                                                            130,
                                                                        child:
                                                                            Text(
                                                                          wallet
                                                                              .name,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          style:
                                                                              GoogleFonts.montserrat(
                                                                            textStyle:
                                                                                TextStyle(
                                                                              color: cardsData[networkId]!['color'],
                                                                              fontSize: 20,
                                                                              fontWeight: FontWeight.w700,
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
                                                                                wallets.indexOf(wallet) + 1,
                                                                            child:
                                                                                Row(
                                                                              children: [
                                                                                Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: wallet['publicKey']), size: 15),
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
                                                                    wallet
                                                                        .publicKey,
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
                                                                        color: cardsData[networkId]![
                                                                            'color'],
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight.w400,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: 30,
                                                                  child:
                                                                      IconButton(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    onPressed:
                                                                        () async {
                                                                      await Clipboard.setData(
                                                                          ClipboardData(
                                                                              text: wallet.publicKey));
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
                                                                  child:
                                                                      IconButton(
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
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 70,
                                                        minHeight: 60),
                                                fillColor: secondaryColor,
                                                shape: CircleBorder(),
                                                onPressed: () {
                                                  // QR Scanner
                                                  showDialog(
                                                      barrierDismissible: false,
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
                                                                'QR Code',
                                                                style: TextStyle(
                                                                    color:
                                                                        secondaryColor),
                                                              ),
                                                              content:
                                                                  SingleChildScrollView(
                                                                child:
                                                                    Container(
                                                                  width:
                                                                      size.width *
                                                                          0.9,
                                                                  height: 350,
                                                                  margin:
                                                                      EdgeInsets
                                                                          .all(
                                                                              0),
                                                                  child: Column(
                                                                    children: [
                                                                      Container(
                                                                        height:
                                                                            300,
                                                                        padding:
                                                                            const EdgeInsets.all(10),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          borderRadius:
                                                                              BorderRadius.circular(20.0),
                                                                          gradient:
                                                                              const LinearGradient(
                                                                            begin:
                                                                                Alignment.topLeft,
                                                                            end:
                                                                                Alignment.bottomRight,
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
                                                                              (barcode, args) async {
                                                                            if (barcode.rawValue ==
                                                                                null) {
                                                                              showNotification('Failed', 'Failed to find code', Colors.red);
                                                                            } else {
                                                                              try {
                                                                                firestore.DocumentSnapshot invoice = await firestore.FirebaseFirestore.instance.collection('invoices').doc(barcode.rawValue).get();
                                                                                if (invoice.exists) {
                                                                                  if (invoice.get('networkId') == selectedNetworkId) {
                                                                                    if (invoice.get('status') != '10') {
                                                                                      EtherAmount etherGas = await web3client!.getGasPrice();
                                                                                      BigInt estimateGas = await web3client!.estimateGas(
                                                                                        sender: EthereumAddress.fromHex(wallet.publicKey),
                                                                                        // to: EthereumAddress.fromHex(invoice.get('to')),
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
                                                                                                                    Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: wallet.publicKey), size: 25),
                                                                                                                    SizedBox(
                                                                                                                      width: 10,
                                                                                                                    ),
                                                                                                                    Expanded(
                                                                                                                      child: Text(
                                                                                                                        wallet.name,
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
                                                                                                                // Row(
                                                                                                                //   children: [
                                                                                                                //     Icon(
                                                                                                                //       CupertinoIcons.exclamationmark_circle,
                                                                                                                //       color: secondaryColor,
                                                                                                                //     ),
                                                                                                                //     SizedBox(
                                                                                                                //       width: 5,
                                                                                                                //     ),
                                                                                                                //     Expanded(
                                                                                                                //       child: Text(
                                                                                                                //         "Estimate gas price might be significantly higher that the actual price",
                                                                                                                //         overflow: TextOverflow.ellipsis,
                                                                                                                //         maxLines: 5,
                                                                                                                //         textAlign: TextAlign.start,
                                                                                                                //         style: GoogleFonts.montserrat(
                                                                                                                //           textStyle: const TextStyle(
                                                                                                                //             overflow: TextOverflow.ellipsis,
                                                                                                                //             color: secondaryColor,
                                                                                                                //             fontSize: 10,
                                                                                                                //             fontWeight: FontWeight.w300,
                                                                                                                //           ),
                                                                                                                //         ),
                                                                                                                //       ),
                                                                                                                //     ),
                                                                                                                //   ],
                                                                                                                // ),
                                                                                                                // const SizedBox(
                                                                                                                //   height: 10,
                                                                                                                // ),
//

                                                                                                                // Total
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

                                                                                                                // Total in usd
                                                                                                                // if (!appData!.get(
                                                                                                                //             'AVAILABLE_ETHER_NETWORKS')[
                                                                                                                //         selectedNetworkId]
                                                                                                                //     ['is_testnet'])
                                                                                                                Divider(
                                                                                                                  color: secondaryColor,
                                                                                                                ),
                                                                                                                // if (!appData!.get(
                                                                                                                //             'AVAILABLE_ETHER_NETWORKS')[
                                                                                                                //         selectedNetworkId]
                                                                                                                //     ['is_testnet'])
                                                                                                                Row(
                                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                  children: [
                                                                                                                    Container(
                                                                                                                      width: size.width * 0.2,
                                                                                                                      child: Text(
                                                                                                                        "Transaction cost",
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
                                                                                                                        "${(etherGas.getValueInUnit(EtherUnit.ether) * selectedNetworkVsUsd * estimateGas.toDouble()).toStringAsFixed(6)}\$",
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
                                                                                                                SizedBox(
                                                                                                                  height: 20,
                                                                                                                ),
                                                                                                                Center(
                                                                                                                  child: Row(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                                                                    children: [
                                                                                                                      Text(
                                                                                                                        "Powered by   ",
                                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                                        textAlign: TextAlign.center,
                                                                                                                        maxLines: 4,
                                                                                                                        style: GoogleFonts.montserrat(
                                                                                                                          textStyle: const TextStyle(
                                                                                                                            color: secondaryColor,
                                                                                                                            fontSize: 15,
                                                                                                                            fontWeight: FontWeight.w400,
                                                                                                                          ),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      Image.asset(
                                                                                                                        "assets/images/coingecko.png",
                                                                                                                        scale: 70,
                                                                                                                      )
                                                                                                                    ],
                                                                                                                  ),
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
                                                                                                                'from': wallet.publicKey,
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
                                                                                                              Color notifColor = greenColor;

                                                                                                              // ignore: unused_local_variable
                                                                                                              bool txSuccess = true;
                                                                                                              String transactionResult = await web3client!
                                                                                                                  .sendTransaction(
                                                                                                                EthPrivateKey.fromHex(wallet.privateKey),
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
                                                                                showNotification('Failed', 'Something went wrong', Colors.red);
                                                                              }
                                                                            }
                                                                          },
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height:
                                                                            10,
                                                                      ),
                                                                      SizedBox(
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
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 70,
                                                        minHeight: 60),
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
                                                        wallet: wallet,
                                                        networkId:
                                                            selectedNetworkId,
                                                        coin: {
                                                          'id':
                                                              uzsoFirebase!.id,
                                                          'contract':
                                                              uzsoContract,
                                                          'symbol':
                                                              uzsoFirebase!.get(
                                                                  'symbol'),
                                                        },
                                                        isTestnet: appData!.get(
                                                                    'AVAILABLE_ETHER_NETWORKS')[
                                                                selectedNetworkId]
                                                            ['is_testnet'],
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
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 70,
                                                        minHeight: 60),
                                                fillColor: secondaryColor,
                                                shape: CircleBorder(),
                                                onPressed: () {
                                                  if (wallet.publicKey !=
                                                      'Loading')
                                                    showDialog(
                                                        barrierDismissible:
                                                            false,
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
                                                                title:
                                                                    const Text(
                                                                  'QR Code',
                                                                  style: TextStyle(
                                                                      color:
                                                                          secondaryColor),
                                                                ),
                                                                content:
                                                                    SingleChildScrollView(
                                                                  child:
                                                                      Container(
                                                                    width:
                                                                        size.width *
                                                                            0.9,
                                                                    height:
                                                                        size.height *
                                                                            0.4,
                                                                    margin: EdgeInsets
                                                                        .all(
                                                                            10),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        Container(
                                                                          padding:
                                                                              const EdgeInsets.all(20),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            borderRadius:
                                                                                BorderRadius.circular(20.0),
                                                                            gradient:
                                                                                const LinearGradient(
                                                                              begin: Alignment.topLeft,
                                                                              end: Alignment.bottomRight,
                                                                              colors: [
                                                                                darkPrimaryColor,
                                                                                primaryColor
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              QrImage(
                                                                            data:
                                                                                EthereumAddress.fromHex(wallet.publicKey).addressBytes.toString(),
                                                                            foregroundColor:
                                                                                secondaryColor,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Expanded(
                                                                              child: Text(
                                                                                wallet.publicKey,
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
                                                                                  await Clipboard.setData(ClipboardData(text: wallet.publicKey));
                                                                                  showNotification('Copied', 'Public key copied', greenColor);
                                                                                },
                                                                                icon: Icon(
                                                                                  CupertinoIcons.doc,
                                                                                  color: secondaryColor,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              20,
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                                actions: <
                                                                    Widget>[
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(false),
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
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 70,
                                                        minHeight: 60),
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
                                                        barrierDismissible:
                                                            false,
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
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
                                                                title:
                                                                    const Text(
                                                                  'Method',
                                                                  style: TextStyle(
                                                                      color:
                                                                          darkPrimaryColor),
                                                                ),
                                                                content:
                                                                    SingleChildScrollView(
                                                                  child:
                                                                      Container(
                                                                    margin: EdgeInsets
                                                                        .all(
                                                                            10),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        // PayMe
                                                                        Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceEvenly,
                                                                          children: [
                                                                            Image.asset(
                                                                              "assets/images/payme.png",
                                                                              width: 80,
                                                                            ),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: RoundedButton(
                                                                                pw: 250,
                                                                                ph: 45,
                                                                                text: 'PayMe',
                                                                                press: () {
                                                                                  Navigator.push(
                                                                                    context,
                                                                                    SlideRightRoute(
                                                                                      page: BuyOzodPaymeScreen(
                                                                                        wallet: wallet,
                                                                                        web3client: web3client!,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                color: secondaryColor,
                                                                                textColor: darkPrimaryColor,
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
                                                                              MainAxisAlignment.spaceEvenly,
                                                                          children: [
                                                                            Image.asset(
                                                                              "assets/images/octo.png",
                                                                              width: 80,
                                                                            ),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: RoundedButton(
                                                                                pw: 250,
                                                                                ph: 45,
                                                                                text: 'Octo',
                                                                                press: () {
                                                                                  Navigator.push(
                                                                                    context,
                                                                                    SlideRightRoute(
                                                                                      page: BuyOzodOctoScreen(
                                                                                        wallet: wallet,
                                                                                        web3client: web3client!,
                                                                                        selectedNetworkId: selectedNetworkId,
                                                                                        contract: uzsoContract!,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                                color: Colors.blue,
                                                                                textColor: whiteColor,
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
                                                                actions: <
                                                                    Widget>[
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(false),
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
                                      key: keyButton3,
                                      margin:
                                          EdgeInsets.fromLTRB(10, 0, 10, 10),
                                      width: size.width * 0.8,
                                      // height: 200,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
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
                                      child: custom.ExpansionTile(
                                        tilePadding: EdgeInsets.zero,
                                        childrenPadding: EdgeInsets.zero,
                                        expandedCrossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        expandedAlignment: Alignment.center,
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
                                            Center(
                                              child: Container(
                                                padding: EdgeInsets.all(20),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(50)),
                                                  border: Border.all(
                                                    width: 3,
                                                    color: whiteColor,
                                                    style: BorderStyle.solid,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "~${NumberFormat.compact().format(gasTxsLeft)}",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: whiteColor,
                                                          fontSize: 50,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      "Txs left",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: whiteColor,
                                                          fontSize: 17,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                          ],
                                        ),
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: whiteColor,
                                                  width: 1.0),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Text(
                                                  "Balance: ${gasBalance != null ? gasBalance!.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2) : "0"} GWEI",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 4,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400,
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 4,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "Estimate gas amount: $estimateGasAmount",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 4,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                                Text(
                                                  "Total gas: ${(estimateGasPrice.getValueInUnit(EtherUnit.gwei) * estimateGasAmount.toDouble()).toStringAsFixed(2)} GWEI",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 4,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Divider(
                                                  color: whiteColor,
                                                ),
                                                // if (!appData!.get(
                                                //             'AVAILABLE_ETHER_NETWORKS')[
                                                //         selectedNetworkId]
                                                //     ['is_testnet'])
                                                Text(
                                                  "Transaction cost ${(estimateGasPrice.getValueInUnit(EtherUnit.ether) * selectedNetworkVsUsd * estimateGasAmount.toDouble()).toStringAsFixed(6)}\$",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  maxLines: 4,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Center(
                                                  child: RoundedButton(
                                                    pw: 150,
                                                    ph: 35,
                                                    text: 'Top up gas',
                                                    press: () async {
                                                      if (kIsWeb) {
                                                        showNotification(
                                                            'Coming soon',
                                                            'Not supported for web',
                                                            Colors.orange);
                                                      } else {
                                                        showNotification(
                                                          'Coming soon',
                                                          'Coming soon',
                                                          Colors.orange,
                                                        );
                                                        // Navigator.push(
                                                        //   context,
                                                        //   SlideRightRoute(
                                                        //       page:
                                                        //           BuyCryptoScreen(
                                                        //     walletIndex:
                                                        //         selectedWalletIndex,
                                                        //     web3client:
                                                        //         web3client!,
                                                        //   )),
                                                        // );
                                                      }
                                                    },
                                                    color: whiteColor,
                                                    textColor: darkPrimaryColor,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 20,
                                                ),
                                                Center(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        "Powered by   ",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 4,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            color: whiteColor,
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w400,
                                                          ),
                                                        ),
                                                      ),
                                                      Image.asset(
                                                        "assets/images/coingecko.png",
                                                        scale: 70,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 50,
                                    ),

                                    // Txs
                                    selectedWalletTxs.length != 0
                                        ? Container(
                                            width: size.width * 0.9,
                                            child: Column(
                                              children: [
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    "Activity",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: secondaryColor,
                                                        fontSize: 40,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 30,
                                                ),
                                                for (Map tx in selectedWalletTxs
                                                    .take(5))
                                                  CupertinoButton(
                                                    padding: EdgeInsets.zero,
                                                    onPressed: () {
                                                      showDialog(
                                                          barrierDismissible:
                                                              true,
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
                                                                        BorderRadius.circular(
                                                                            20.0),
                                                                  ),
                                                                  title:
                                                                      const Text(
                                                                    'Transaction',
                                                                    style: TextStyle(
                                                                        color:
                                                                            secondaryColor),
                                                                  ),
                                                                  content:
                                                                      SingleChildScrollView(
                                                                    child:
                                                                        Container(
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                            "Amount",
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                3,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style:
                                                                                GoogleFonts.montserrat(
                                                                              textStyle: const TextStyle(
                                                                                color: secondaryColor,
                                                                                fontSize: 25,
                                                                                fontWeight: FontWeight.w700,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Text(
                                                                            NumberFormat.compact().format(BigInt.parse(tx['value']) /
                                                                                BigInt.from(pow(10, int.parse(tx['tokenDecimal'])))),
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                            maxLines:
                                                                                3,
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            style:
                                                                                GoogleFonts.montserrat(
                                                                              textStyle: const TextStyle(
                                                                                overflow: TextOverflow.ellipsis,
                                                                                color: secondaryColor,
                                                                                fontSize: 60,
                                                                                fontWeight: FontWeight.w700,
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
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                Jazzicon.getIconWidget(Jazzicon.getJazziconData(160, address: tx['contractAddress']), size: 25),
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
                                                                              border: Border.all(color: secondaryColor, width: 1.0),
                                                                              borderRadius: BorderRadius.circular(20),
                                                                            ),
                                                                            padding:
                                                                                EdgeInsets.all(15),
                                                                            child:
                                                                                Column(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                                                                        ClipboardData(text: tx['hash']),
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
                                                                                        ClipboardData(text: tx['from']),
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
                                                                                        ClipboardData(text: tx['to']),
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
                                                                  actions: <
                                                                      Widget>[
                                                                    TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop(false);
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
                                                            color:
                                                                secondaryColor,
                                                            width: 1.0),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      margin: EdgeInsets.only(
                                                          bottom: 10),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          // Icons + Date
                                                          Container(
                                                            width: size.width *
                                                                0.1,
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                tx['from'] ==
                                                                        wallet
                                                                            .publicKey
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
                                                                      fontSize:
                                                                          9,
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
                                                            width: size.width *
                                                                0.4,
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                tx['from'] ==
                                                                        wallet
                                                                            .publicKey
                                                                    ? Text(
                                                                        "Sent",
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        textAlign:
                                                                            TextAlign.start,
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
                                                                            TextOverflow.ellipsis,
                                                                        textAlign:
                                                                            TextAlign.start,
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
                                                                            wallet
                                                                                .publicKey &&
                                                                        !selectedWalletAssetsData
                                                                            .keys
                                                                            .contains(tx['to'])
                                                                    ? Text(
                                                                        "To ${tx['to']}",
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        textAlign:
                                                                            TextAlign.start,
                                                                        maxLines:
                                                                            2,
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
                                                                            TextOverflow.ellipsis,
                                                                        maxLines:
                                                                            2,
                                                                        textAlign:
                                                                            TextAlign.start,
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
                                                            width: size.width *
                                                                0.2,
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
                                                                              EtherUnit.wei,
                                                                              tx['value'])
                                                                          .getValueInUnit(selectedEtherUnit))
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
                                                                      fontSize:
                                                                          15,
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
                                                                      fontSize:
                                                                          20,
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
    try {
      var timeCounter = 0;
      timer = Timer.periodic(Duration(seconds: 10), (Timer t) async {
        timeCounter++;
        TransactionReceipt? txReceipt =
            await web3client!.getTransactionReceipt(tx);
        timeCounter++;
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
              'from': wallet.publicKey,
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
