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
  DocumentSnapshot? walletFirebase;
  DocumentSnapshot? appDataNodes;
  DocumentSnapshot? appDataApi;
  DocumentSnapshot? appData;

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

    web3client = Web3Client(
        EncryptionService().dec(appDataNodes!.get(appData!
            .get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['node'])),
        httpClient);

    // Wallet
    Map walletData =
        await SafeStorageService().getWalletData(selectedWalletIndex);
    EtherAmount valueBalance =
        await web3client.getBalance(walletData['address']);

    walletFirebase = await FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletData['address'].toString())
        .get();

    // get assets
    if (walletFirebase!.exists) {
      for (Map asset in walletFirebase!.get('assets')) {
        if (asset['network'] == selectedNetworkId) {
          final response = await httpClient.get(Uri.parse(
              "${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['etherscan_url']}/api?module=contract&action=getabi&address=${asset['address']}&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));

          if (int.parse(jsonDecode(response.body)['status'].toString()) == 1) {
            
            final contract = DeployedContract(
                ContractAbi.fromJson(
                    jsonDecode(response.body)['result'], "LoyaltyToken"),
                EthereumAddress.fromHex(asset['address']));
            final balance = await web3client.call(
                contract: contract,
                function: contract.function('balanceOf'),
                params: [walletData['address']]);
            selectedWalletAssets.add({
              'symbol': asset['symbol'],
              'balance': balance[0],
              'address': asset['address'],
              'decimals': asset['decimal'],
              'contract': contract,
            });
            selectedWalletAssetsData[asset['address'].toLowerCase()] =
                asset['symbol'];
          }
        }
      }
    }

    // get txs
    final response = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['etherscan_url']}//api?module=account&action=txlist&address=${walletData['address']}&startblock=0&endblock=99999999&page=1&offset=5&sort=desc&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));
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
          ? selectedWalletTxs = valueTxs.toList()
          : selectedWalletTxs = [];
      // if (appData != null) {
      //   selectedNetworkId = appData!.get('AVAILABLE_ETHER_NETWORKS')[0];
      //   selectedNetworkName =
      //       appData!.get('AVAILABLE_ETHER_NETWORKS')[0]['name'];
      // }

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
                                    focusColor: whiteColor,
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                // Image + symbol
                                                Row(
                                                  children: [
                                                    Text(
                                                      appData!.get(
                                                              'AVAILABLE_ETHER_NETWORKS')[
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
                                              focusColor: whiteColor,
                                              iconEnabledColor: whiteColor,
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
                                                    color: whiteColor,
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
                                                  networkId: selectedNetworkId,
                                                  walletAssets:
                                                      selectedWalletAssets,
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
                                    SizedBox(
                                      height: 30,
                                    ),
                                    if (selectedWalletAssets.isNotEmpty)
                                      for (dynamic asset
                                          in selectedWalletAssets)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 30),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Jazzicon.getIconWidget(
                                                  Jazzicon.getJazziconData(160,
                                                      address:
                                                          asset['address']),
                                                  size: 25),
                                              Container(
                                                width: 100,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    // Image.network('')
                                                    Text(
                                                      (asset['balance'] /
                                                              BigInt.from(
                                                                  pow(10, 18)))
                                                          .toString(),
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                                width: 100,
                                                child: Text(
                                                  asset['symbol'],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.start,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: whiteColor,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    RoundedButton(
                                      pw: 150,
                                      ph: 45,
                                      text: 'Import',
                                      press: () {
                                        final _formKey = GlobalKey<FormState>();
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
                                                      'Import assets',
                                                      style: TextStyle(
                                                          color:
                                                              secondaryColor),
                                                    ),
                                                    content:
                                                        SingleChildScrollView(
                                                      child: Container(
                                                        margin:
                                                            EdgeInsets.all(10),
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
                                                                  setState(() {
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
                                                                          .withOpacity(
                                                                              0.7)),
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
                                                                  setState(() {
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
                                                                          .withOpacity(
                                                                              0.7)),
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
                                                                          await httpClient
                                                                              .get(Uri.parse("${appData!.get('AVAILABLE_ETHER_NETWORKS')[selectedNetworkId]['etherscan_url']}/api?module=contract&action=getabi&address=${importingAssetContractAddress}&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));
                                                                      if (int.parse(
                                                                              jsonDecode(response.body)['status'].toString()) ==
                                                                          1) {
                                                                        await FirebaseFirestore
                                                                            .instance
                                                                            .collection('wallets')
                                                                            .doc(publicKey.toString())
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
                                                                        PushNotificationMessage
                                                                            notification =
                                                                            PushNotificationMessage(
                                                                          title:
                                                                              'Failed',
                                                                          body:
                                                                              'Wrong contract',
                                                                        );
                                                                        showSimpleNotification(
                                                                          Text(notification
                                                                              .body),
                                                                          position:
                                                                              NotificationPosition.top,
                                                                          background:
                                                                              Colors.red,
                                                                        );
                                                                      }
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(
                                                                              true);
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
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 50,
                              ),

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
                                                              ? cryptoUnits[
                                                                      selectedEtherUnit]
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
