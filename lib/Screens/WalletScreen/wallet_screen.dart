import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:blur/blur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:glass/glass.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_login_screen.dart';
import 'package:ozodwallet/Screens/OzodAuthScreen/email_signup_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/buy_crypto_screen.dart';
import 'package:ozodwallet/Screens/TransactionScreen/send_tx_screen.dart';
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
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:ozodwallet/Widgets/expansion_tile.dart' as custom;

// ignore: must_be_immutable
class WalletScreen extends StatefulWidget {
  String error;
  Function mainScreenRefreshFunction;
  WalletScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.mainScreenRefreshFunction,
  }) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool loading = true;
  ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  SharedPreferences? sharedPreferences;

  // Settings
  bool showSeed = false;
  String editedName = "Wallet1";
  final _formKey = GlobalKey<FormState>();

  // Wallet
  Web3Wallet wallet = Web3Wallet(
      privateKey: "Loading",
      publicKey: "Loading",
      name: "Loading",
      localIndex: "1");
  String selectedWalletIndex = "1";
  String importingAssetContractAddress = "";
  String importingAssetContractSymbol = "";
  String selectedNetworkId = "mainnet";
  String selectedNetworkName = "Ethereum Mainnet";
  double selectedNetworkVsUsd = 0;

  // Blockchain data
  EtherAmount selectedWalletBalance = EtherAmount.zero();
  List selectedWalletTxs = [];
  List selectedWalletAssets = [];
  Map selectedWalletAssetsData = {};
  List wallets = [];
  Map<EtherUnit, String> cryptoUnits = {
    EtherUnit.ether: 'ETH',
    EtherUnit.wei: 'WEI',
    EtherUnit.gwei: 'GWEI',
  };
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  EtherAmount estimateGasPrice = EtherAmount.zero();
  BigInt estimateGasAmount = BigInt.from(1);
  EtherAmount? gasBalance;
  double gasTxsLeft = 0;

  // Firebase Firestore
  DocumentSnapshot? walletFirebase;
  DocumentSnapshot? appDataNodes;
  DocumentSnapshot? appDataApi;
  DocumentSnapshot? appData;

  List pendingTxs = [];

  // Ozod ID
  User? ozodIdUser;
  StreamSubscription<User?>? authStream;

  Client httpClient = Client();
  late Web3Client web3client;

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    wallet = Web3Wallet(
        privateKey: "Loading",
        publicKey: "Loading",
        name: "Loading",
        localIndex: "1");
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
    pendingTxs = [];

    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> manageFirebaseFirestore() async {
    appDataNodes = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('nodes')
        .get();
    appDataApi = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('api')
        .get();
    appData = await FirebaseFirestore.instance
        .collection('app_data')
        .doc('data')
        .get();
    walletFirebase = await FirebaseFirestore.instance
        .collection('wallets')
        .doc(wallet.valueAddress.toString())
        .get();
  }

  Future<Map> manageBlockchainNetworkData() async {
    // Check network availability
    if (appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId] == null) {
      selectedNetworkId = "mainnet";
      selectedNetworkName = "Ethereum Mainnet";
    } else {
      if (!appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]
          ['active']) {
        selectedNetworkId = "mainnet";
        selectedNetworkName = "Ethereum Mainnet";
      }
    }

    // Get coin unit
    cryptoUnits[EtherUnit.ether] =
        appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['unit'];

    // Web3 client
    web3client = Web3Client(
        EncryptionService().dec(appDataNodes!.get(appData!
            .get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['node'])),
        httpClient);

    EtherAmount valueBalance = await web3client.getBalance(wallet.valueAddress);

    // get assets
    if (walletFirebase!.exists) {
      for (Map asset in walletFirebase!.get('assets')) {
        if (asset['network'] == selectedNetworkId) {
          final response = await httpClient.get(Uri.parse(
              "${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=contract&action=getabi&address=${asset['address']}&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_api']))}"));

          if (int.parse(jsonDecode(response.body)['status'].toString()) == 1) {
            final contract = DeployedContract(
                ContractAbi.fromJson(
                    jsonDecode(response.body)['result'], "LoyaltyToken"),
                EthereumAddress.fromHex(asset['address']));
            final balance = await web3client.call(
                contract: contract,
                function: contract.function('balanceOf'),
                params: [wallet.valueAddress]);
            selectedWalletAssets.add({
              'symbol': asset['symbol'],
              'balance': balance[0],
              'address': asset['address'],
              'decimals': asset['decimal'],
              'contract': contract,
              'asset': asset,
            });
            selectedWalletAssetsData[asset['address'].toLowerCase()] =
                asset['symbol'];
          }
        }
      }
    }

    // get txs
    final response = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=account&action=txlist&address=${wallet.publicKey}&startblock=0&endblock=99999999&page=1&offset=5&sort=desc&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_api']))}"));
    dynamic jsonBody = jsonDecode(response.body);
    List valueTxs = [];
    if (jsonBody['result'] != null) {
      valueTxs = jsonBody['result'];
    }

    // Gas indicator
    estimateGasPrice = await web3client.getGasPrice();
    estimateGasAmount = await web3client.estimateGas(
      sender: wallet.valueAddress,
    );

    // Get selected network vs usd
    selectedNetworkVsUsd = await getSelectedNetworkVsUsd();
    gasBalance = await web3client.getBalance(wallet.valueAddress);

    return {
      'valueBalance': valueBalance,
      'valueTxs': valueTxs,
    };
  }

  Future<void> getDataFromSP() async {
    sharedPreferences = await SharedPreferences.getInstance();
    String? valueSelectedWalletIndex =
        await sharedPreferences!.getString("selectedWalletIndex");
    String? valueselectedNetworkId =
        await sharedPreferences!.getString("selectedNetworkId");
    String? valueselectedNetworkName =
        await sharedPreferences!.getString("selectedNetworkName");
    String? valueselectedEtherUnit =
        await sharedPreferences!.getString("selectedEtherUnit");
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
        if (valueselectedEtherUnit != null) {
          if (valueselectedEtherUnit == 'ETH') {
            selectedEtherUnit = EtherUnit.ether;
          }
          if (valueselectedEtherUnit == 'WEI') {
            selectedEtherUnit = EtherUnit.wei;
          }
          if (valueselectedEtherUnit == 'GWEI') {
            selectedEtherUnit = EtherUnit.gwei;
          }
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
      if (valueselectedEtherUnit != null) {
        if (valueselectedEtherUnit == 'ETH') {
          selectedEtherUnit = EtherUnit.ether;
        }
        if (valueselectedEtherUnit == 'WEI') {
          selectedEtherUnit = EtherUnit.wei;
        }
        if (valueselectedEtherUnit == 'GWEI') {
          selectedEtherUnit = EtherUnit.gwei;
        }
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

  Future<void> prepare() async {
    try {
      // Firebase app data
      await manageFirebaseFirestore();

      // Wallet
      wallets = await SafeStorageService().getAllWallets();
      wallet = await SafeStorageService().getWallet(selectedWalletIndex);
      await getDataFromSP();

      // Blockchain Data
      Map blockchainData = await manageBlockchainNetworkData();

      setState(() {
        blockchainData['valueBalance'] != null
            ? selectedWalletBalance = blockchainData['valueBalance']
            : selectedWalletBalance = EtherAmount.zero();
        blockchainData['valueTxs'] != null
            ? selectedWalletTxs = blockchainData['valueTxs'].toList()
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
        ? LoadingScreen()
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
                                            const SizedBox(height: 100),
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
                                      borderRadius: BorderRadius.circular(30.0),
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
                                                .get('AVAILABLE_ETHER_NETWORKS')[
                                                    networkId]['id']
                                                .toString());
                                        await sharedPreferences!.setString(
                                            "selectedNetworkName",
                                            appData!
                                                .get('AVAILABLE_ETHER_NETWORKS')[
                                                    networkId]['name']
                                                .toString());
                                        setState(() {
                                          selectedNetworkId = appData!.get(
                                                  'AVAILABLE_ETHER_NETWORKS')[
                                              networkId]['id'];
                                          selectedNetworkName = appData!.get(
                                                  'AVAILABLE_ETHER_NETWORKS')[
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
                                                    'AVAILABLE_ETHER_NETWORKS')[
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
                                            .get('AVAILABLE_ETHER_NETWORKS')
                                            .keys)
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
                                                            'AVAILABLE_ETHER_NETWORKS')[
                                                        networkId]['image'],
                                                    width: 30,
                                                  ),
                                                  SizedBox(
                                                    width: 5,
                                                  ),
                                                  // Image + symbol
                                                  Text(
                                                    appData!.get(
                                                            'AVAILABLE_ETHER_NETWORKS')[
                                                        networkId]['name'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: darkPrimaryColor,
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
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 1.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.all(15),
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 40),
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
                                SizedBox(height: 20),

                                // Wallet
                                Container(
                                  width: 300,
                                  height: 200,
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color.fromRGBO(177, 255, 232, 1),
                                        Color.fromRGBO(238, 238, 255, 1),
                                        Color.fromRGBO(255, 173, 239, 1),
                                      ],
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
                                              Jazzicon.getJazziconData(160,
                                                  address: wallet.publicKey),
                                              size: 20),
                                          SizedBox(
                                            width: 5,
                                          ),
                                          Container(
                                            width: 240,
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                borderRadius:
                                                    BorderRadius.circular(20.0),
                                                dropdownColor: darkPrimaryColor,
                                                focusColor: darkColor,
                                                iconEnabledColor: darkColor,
                                                alignment: Alignment.centerLeft,
                                                onChanged: (walletIndex) async {
                                                  await sharedPreferences!
                                                      .setString(
                                                          "selectedWalletIndex",
                                                          walletIndex
                                                              .toString());
                                                  setState(() {
                                                    selectedWalletIndex =
                                                        walletIndex.toString();
                                                    loading = true;
                                                  });
                                                  _refresh();
                                                },
                                                hint: Container(
                                                  width: 200,
                                                  child: Text(
                                                    wallet.name,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: darkColor,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
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
                                                          Container(
                                                            width: 180,
                                                            child: Text(
                                                              wallet[wallets
                                                                      .indexOf(
                                                                          wallet) +
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
                                                                  fontSize: 25,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
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
                                                  color: darkColor,
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
                                                alignment:
                                                    Alignment.centerRight,
                                                child:
                                                    DropdownButton<EtherUnit>(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          20.0),
                                                  dropdownColor:
                                                      darkPrimaryColor,
                                                  focusColor: darkColor,
                                                  iconEnabledColor: darkColor,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  onChanged: (unit) async {
                                                    await sharedPreferences!
                                                        .setString(
                                                            "selectedEtherUnit",
                                                            cryptoUnits[unit]
                                                                .toString());
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
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: darkColor,
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  items: [
                                                    for (EtherUnit unit
                                                        in cryptoUnits.keys)
                                                      DropdownMenuItem<
                                                          EtherUnit>(
                                                        value: unit,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                              cryptoUnits[
                                                                  unit]!,
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
                                              wallet.publicKey,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: darkColor,
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
                                                        text:
                                                            wallet.publicKey));

                                                showNotification(
                                                    'Copied',
                                                    'Public key copied',
                                                    greenColor);
                                              },
                                              icon: Icon(
                                                CupertinoIcons.doc,
                                                color: darkColor,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 30,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                _scaffoldKey.currentState!
                                                    .openDrawer();
                                              },
                                              icon: Icon(
                                                CupertinoIcons.settings,
                                                color: darkColor,
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
                                                    wallet: wallet,
                                                    networkId:
                                                        selectedNetworkId,
                                                    walletAssets:
                                                        selectedWalletAssets,
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
                                                                              wallet.publicKey)
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
                                                                          wallet
                                                                              .publicKey,
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
                                                                            await Clipboard.setData(ClipboardData(text: wallet.publicKey));
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

                                // Pending Txs
                                pendingTxs.length != 0
                                    ? Container(
                                        width: size.width * 0.8,
                                        padding: const EdgeInsets.all(10),
                                        margin: EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.purpleAccent,
                                              Colors.deepPurple
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                "Pending",
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
                                            for (dynamic tx in pendingTxs)
                                              Container(
                                                margin:
                                                    EdgeInsets.only(bottom: 30),
                                                child: Text(
                                                  tx,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: darkDarkColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      )
                                    : Container(),

                                // Gas Indicator
                                Container(
                                  // key: keyButton3,
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
                                              borderRadius: BorderRadius.all(
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
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
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
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
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
                                              color: whiteColor, width: 1.0),
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
                                              "Balance: ${gasBalance!.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
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
                                              height: 5,
                                            ),
                                            Text(
                                              "Total gas: ${(estimateGasPrice.getValueInUnit(EtherUnit.gwei) * estimateGasAmount.toDouble()).toStringAsFixed(2)} GWEI",
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
                                            // if (!appData!.get(
                                            //         'AVAILABLE_ETHER_NETWORKS')[
                                            //     selectedNetworkId]['is_testnet'])
                                            Text(
                                              "Transaction cost ${(estimateGasPrice.getValueInUnit(EtherUnit.ether) * selectedNetworkVsUsd * estimateGasAmount.toDouble()).toStringAsFixed(6)}\$",
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.start,
                                              maxLines: 4,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: whiteColor,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
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
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "Powered by  ",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
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
                                const SizedBox(height: 50),

                                // Assets
                                Container(
                                  width: size.width * 0.8,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color.fromRGBO(9, 32, 63, 1.0),
                                        Color.fromRGBO(83, 120, 149, 1.0),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Assets",
                                          overflow: TextOverflow.ellipsis,
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
                                      if (selectedWalletAssets.isNotEmpty)
                                        for (dynamic asset
                                            in selectedWalletAssets)
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                                vertical: 30),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Jazzicon.getIconWidget(
                                                    Jazzicon.getJazziconData(
                                                        160,
                                                        address:
                                                            asset['address']),
                                                    size: 25),
                                                Container(
                                                  width: 90,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      // Image.network('')
                                                      Text(
                                                        (asset['balance'] /
                                                                BigInt.from(pow(
                                                                    10, 18)))
                                                            .toString(),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 3,
                                                        textAlign:
                                                            TextAlign.start,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                          textStyle:
                                                              const TextStyle(
                                                            color: whiteColor,
                                                            fontSize: 20,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  width: 90,
                                                  child: Text(
                                                    asset['symbol'],
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.start,
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      textStyle:
                                                          const TextStyle(
                                                        color: whiteColor,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    showDialog(
                                                      barrierDismissible: false,
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
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
                                                          // title: Text(
                                                          //     Languages.of(context).profileScreenSignOut),
                                                          // content: Text(
                                                          //     Languages.of(context)!.profileScreenWantToLeave),
                                                          title: Text(
                                                            'Remove asset?',
                                                            style: TextStyle(
                                                                color:
                                                                    secondaryColor),
                                                          ),
                                                          content: Text(
                                                            'Your asset will still exist on blockchain',
                                                            style: TextStyle(
                                                                color:
                                                                    secondaryColor),
                                                          ),
                                                          actions: <Widget>[
                                                            TextButton(
                                                              onPressed:
                                                                  () async {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(true);
                                                                setState(() {
                                                                  loading =
                                                                      true;
                                                                });
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'wallets')
                                                                    .doc(wallet
                                                                        .publicKey)
                                                                    .update({
                                                                  'assets':
                                                                      FieldValue
                                                                          .arrayRemove([
                                                                    asset[
                                                                        'asset']
                                                                  ])
                                                                });
                                                                _refresh();
                                                              },
                                                              child: const Text(
                                                                'Yes',
                                                                style: TextStyle(
                                                                    color:
                                                                        secondaryColor),
                                                              ),
                                                            ),
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          false),
                                                              child: const Text(
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
                                                  icon: Icon(
                                                    CupertinoIcons.trash,
                                                    color: Colors.red,
                                                    // size: 5,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      RoundedButton(
                                        pw: 150,
                                        ph: 35,
                                        text: 'Import',
                                        press: () {
                                          final _formKey =
                                              GlobalKey<FormState>();
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
                                                            BorderRadius
                                                                .circular(20.0),
                                                      ),
                                                      title: const Text(
                                                        'Import assets',
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
                                                          child: Form(
                                                            key: _formKey,
                                                            child: Column(
                                                              children: [
                                                                TextFormField(
                                                                  style: const TextStyle(
                                                                      color:
                                                                          secondaryColor),
                                                                  validator:
                                                                      (val) {
                                                                    if (val!
                                                                        .isEmpty) {
                                                                      return 'Enter contract address';
                                                                    } else {
                                                                      return null;
                                                                    }
                                                                  },
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .name,
                                                                  onChanged:
                                                                      (val) {
                                                                    setState(
                                                                        () {
                                                                      importingAssetContractAddress =
                                                                          val;
                                                                    });
                                                                  },
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        "Contract address",
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
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                    enabledBorder:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                    hintStyle: TextStyle(
                                                                        color: darkPrimaryColor
                                                                            .withOpacity(0.7)),
                                                                    hintText:
                                                                        'Contract address',
                                                                    border:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                ),
                                                                TextFormField(
                                                                  style: const TextStyle(
                                                                      color:
                                                                          secondaryColor),
                                                                  validator:
                                                                      (val) {
                                                                    if (val!
                                                                        .isEmpty) {
                                                                      return 'Enter symbol';
                                                                    } else if (val
                                                                            .length >
                                                                        10) {
                                                                      return 'Maximum 10 symbols';
                                                                    } else {
                                                                      return null;
                                                                    }
                                                                  },
                                                                  keyboardType:
                                                                      TextInputType
                                                                          .name,
                                                                  onChanged:
                                                                      (val) {
                                                                    setState(
                                                                        () {
                                                                      importingAssetContractSymbol =
                                                                          val;
                                                                    });
                                                                  },
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        "Symbol",
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
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                    enabledBorder:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                    hintStyle: TextStyle(
                                                                        color: darkPrimaryColor
                                                                            .withOpacity(0.7)),
                                                                    hintText:
                                                                        'Symbol',
                                                                    border:
                                                                        const OutlineInputBorder(
                                                                      borderSide: BorderSide(
                                                                          color:
                                                                              secondaryColor,
                                                                          width:
                                                                              1.0),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                ),
                                                                Center(
                                                                  child:
                                                                      RoundedButton(
                                                                    pw: 250,
                                                                    ph: 45,
                                                                    text:
                                                                        'CONTINUE',
                                                                    press:
                                                                        () async {
                                                                      setState(
                                                                          () {
                                                                        loading =
                                                                            true;
                                                                      });
                                                                      if (_formKey
                                                                          .currentState!
                                                                          .validate()) {
                                                                        ;
                                                                        final response =
                                                                            await httpClient.get(Uri.parse("${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_url']}/api?module=contract&action=getabi&address=${importingAssetContractAddress}&apikey=${EncryptionService().dec(appDataApi!.get(appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['scan_api']))}"));
                                                                        if (int.parse(jsonDecode(response.body)['status'].toString()) ==
                                                                            1) {
                                                                          await FirebaseFirestore
                                                                              .instance
                                                                              .collection('wallets')
                                                                              .doc(wallet.publicKey)
                                                                              .update({
                                                                            'assets':
                                                                                FieldValue.arrayUnion([
                                                                              {
                                                                                "address": importingAssetContractAddress,
                                                                                "symbol": importingAssetContractSymbol,
                                                                                "network": selectedNetworkId,
                                                                                "decimals": 18,
                                                                              }
                                                                            ])
                                                                          });
                                                                        } else {
                                                                          showNotification(
                                                                              'Failed',
                                                                              'Wrong contract',
                                                                              Colors.red);
                                                                        }
                                                                        Navigator.of(context)
                                                                            .pop(true);
                                                                      } else {
                                                                        setState(
                                                                            () {
                                                                          loading =
                                                                              false;
                                                                        });
                                                                      }
                                                                      _refresh();
                                                                    },
                                                                    color:
                                                                        secondaryColor,
                                                                    textColor:
                                                                        darkPrimaryColor,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  height: 20,
                                                                ),
                                                              ],
                                                            ),
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
                                                            'Cancel',
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
                                        color: secondaryColor,
                                        textColor: darkPrimaryColor,
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

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
                                            for (dynamic tx
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
                                                                        NumberFormat.compact().format(EtherAmount.fromUnitAndValue(EtherUnit.wei,
                                                                                tx['value'])
                                                                            .getValueInUnit(selectedEtherUnit)),
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
                                                                      Center(
                                                                        child:
                                                                            Text(
                                                                          cryptoUnits[
                                                                              selectedEtherUnit]!,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                          textAlign:
                                                                              TextAlign.start,
                                                                          style:
                                                                              GoogleFonts.montserrat(
                                                                            textStyle:
                                                                                const TextStyle(
                                                                              color: secondaryColor,
                                                                              fontSize: 25,
                                                                              fontWeight: FontWeight.w700,
                                                                            ),
                                                                          ),
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
                                                                    wallet
                                                                        .publicKey
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
                                                                        wallet
                                                                            .publicKey &&
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
                                                                  ? NumberFormat
                                                                          .compact()
                                                                      .format(EtherAmount.fromUnitAndValue(
                                                                              EtherUnit.wei,
                                                                              tx['value'])
                                                                          .getValueInUnit(selectedEtherUnit))
                                                                      .toString()
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
                                                                  ? cryptoUnits[
                                                                          selectedEtherUnit]
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
}
