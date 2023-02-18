import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class SendOzodScreen extends StatefulWidget {
  String error;
  String walletIndex;
  String networkId;
  Web3Client web3client;
  Map coin;

  SendOzodScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.walletIndex,
    required this.networkId,
    required this.web3client,
    required this.coin,
  }) : super(key: key);

  @override
  State<SendOzodScreen> createState() => _SendOzodScreenState();
}

class _SendOzodScreenState extends State<SendOzodScreen> {
  bool loading = true;
  String? loadingString;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  EtherUnit selectedEtherUnit = EtherUnit.ether;
  Timer? timer;

  String? receiverPublicAddress;
  String? amount;
  Map walletData = {};
  Map selectedCoin = {'symbol': 'UZSO'};
  EtherAmount? balance;
  Client httpClient = Client();
  firestore.DocumentSnapshot? walletFirebase;
  firestore.DocumentSnapshot? appData;
  firestore.DocumentSnapshot? appDataApi;
  TextEditingController textEditingController = TextEditingController();

  Future<void> prepare() async {
    walletFirebase = await firestore.FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletData['address'].toString())
        .get();
    walletData = await SafeStorageService().getWalletData(widget.walletIndex);
    selectedCoin = widget.coin;

    // get app data
    appData = await firestore.FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('data')
        .get();
    appDataApi = await firestore.FirebaseFirestore.instance
        .collection('wallet_app_data')
        .doc('api')
        .get();
    walletData = await SafeStorageService().getWalletData(widget.walletIndex);

    // get balance
    final responseBalance = await httpClient.get(Uri.parse(
        "${appData!.get('AVAILABLE_OZOD_NETWORKS')[widget.networkId]['scan_url']}//api?module=account&action=tokenbalance&contractaddress=${selectedCoin['id']}&address=${walletData['address']}&tag=latest&apikey=${EncryptionService().dec(appDataApi!.get('ETHERSCAN_API'))}"));
    dynamic jsonBodyBalance = jsonDecode(responseBalance.body);
    setState(() {
      loading = false;
    });
    balance =
        EtherAmount.fromUnitAndValue(EtherUnit.wei, jsonBodyBalance['result']);

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
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    if (kIsWeb && size.width >= 600) {
      size = Size(600, size.height);
    }
    return loading
        ? LoadingScreen(
            text: loadingString,
          )
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
                          "Send",
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
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Jazzicon.getIconWidget(
                                      Jazzicon.getJazziconData(160,
                                          address: walletData['publicKey']),
                                      size: 25),
                                  SizedBox(
                                    width: 10,
                                  ),
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
                              SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Image.network(
                                    appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                        widget.networkId]['image'],
                                    width: 20,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Text(
                                      appData!.get('AVAILABLE_ETHER_NETWORKS')[
                                          widget.networkId]['name'],
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
                          height: 30,
                        ),
                        Text(
                          "To",
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
                        Text(
                          "Public address (0x...)",
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1000,
                          textAlign: TextAlign.start,
                          style: GoogleFonts.montserrat(
                            textStyle: const TextStyle(
                              color: secondaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: textEditingController,
                                // initialValue: receiverPublicAddress,
                                style: const TextStyle(color: secondaryColor),
                                validator: (val) {
                                  if (val!.isEmpty) {
                                    return 'Enter receiver';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.visiblePassword,
                                onChanged: (val) {
                                  setState(() {
                                    receiverPublicAddress = val;
                                  });
                                },
                                decoration: InputDecoration(
                                  errorBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.red, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  hintStyle: TextStyle(
                                      color: darkPrimaryColor.withOpacity(0.7)),
                                  hintText: 'Receiver',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: secondaryColor, width: 1.0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (context, StateSetter setState) {
                                          return AlertDialog(
                                            backgroundColor: darkPrimaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            title: const Text(
                                              'QR Code',
                                              style: TextStyle(
                                                  color: secondaryColor),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Container(
                                                margin: EdgeInsets.all(0),
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      height: 300,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20.0),
                                                        gradient:
                                                            const LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            darkPrimaryColor,
                                                            primaryColor
                                                          ],
                                                        ),
                                                      ),
                                                      child: MobileScanner(
                                                          allowDuplicates: false,
                                                          onDetect:
                                                              (barcode, args) {
                                                            if (barcode
                                                                    .rawValue ==
                                                                null) {
                                                              showNotification(
                                                                  'Failed',
                                                                  'Failed to find code',
                                                                  Colors.red);
                                                            } else {
                                                              setState(() {
                                                                Iterable<int>
                                                                    bytes =
                                                                    barcode
                                                                        .rawValue!
                                                                        .runes;
                                                                utf8.decode(bytes
                                                                    .toList());

                                                                textEditingController
                                                                    .text = EthereumAddress(Uint8List.fromList(json
                                                                        .decode(utf8
                                                                            .decode(bytes
                                                                                .toList()))
                                                                        .cast<
                                                                            int>()
                                                                        .toList()))
                                                                    .toString();
                                                                receiverPublicAddress = EthereumAddress(Uint8List.fromList(json
                                                                        .decode(utf8
                                                                            .decode(bytes
                                                                                .toList()))
                                                                        .cast<
                                                                            int>()
                                                                        .toList()))
                                                                    .toString();
                                                              });
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(true);
                                                              showNotification(
                                                                  'Success',
                                                                  'Public key found',
                                                                  Colors.green);
                                                            }
                                                          }),
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
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text(
                                                  'Ok',
                                                  style: TextStyle(
                                                      color: secondaryColor),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    });
                              },
                              icon: Icon(
                                CupertinoIcons.qrcode,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
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
                                  } else if (widget.coin['symbol'] == 'ETH'
                                      ? double.parse(val) >=
                                          balance!
                                              .getValueInUnit(selectedEtherUnit)
                                      : double.parse(val) >=
                                          (balance!.getInWei /
                                              BigInt.from(pow(10, 18)))) {
                                    return 'Too big amount';
                                  } else {
                                    return null;
                                  }
                                },
                                keyboardType: TextInputType.number,
                                onChanged: (val) {
                                  setState(() {
                                    setState(() {
                                      amount = val;
                                    });
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
                              Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Jazzicon.getIconWidget(
                                        Jazzicon.getJazziconData(160,
                                            address: widget.coin['id']),
                                        size: 25),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      width: 100,
                                      child: Text(
                                        widget.coin['symbol'],
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
                                height: 10,
                              ),
                              Text(
                                "Balance: " +
                                    (balance!.getInWei / BigInt.from(pow(10, 18)))
                                        .toString() +
                                    " " +
                                    widget.coin['symbol'],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                                textAlign: TextAlign.start,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: secondaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Center(
                          child: RoundedButton(
                            pw: 250,
                            ph: 45,
                            text: 'SEND',
                            press: () async {
                              setState(() {
                                loading = true;
                              });
                              bool isValidAddress = false;
                              try {
                                EthereumAddress.fromHex(receiverPublicAddress!);
                                isValidAddress = true;
                              } catch (e) {
                                setState(() {
                                  loading = false;
                                  error = 'Wrong address';
                                });
                                false;
                              }

                              if (_formKey.currentState!.validate() &&
                                  receiverPublicAddress != null &&
                                  receiverPublicAddress!.isNotEmpty &&
                                  isValidAddress) {
                                EtherAmount etherGas =
                                    await widget.web3client.getGasPrice();
                                BigInt estimateGas =
                                    await widget.web3client.estimateGas(
                                  sender: walletData['address'],
                                  to: EthereumAddress.fromHex(
                                      receiverPublicAddress!),
                                );
                                setState(() {
                                  loading = false;
                                });
                                // Confirmation screen
                                showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return StatefulBuilder(
                                        builder: (context, StateSetter setState) {
                                          return AlertDialog(
                                            backgroundColor: darkPrimaryColor,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                            title: const Text(
                                              'Cofirmation',
                                              style: TextStyle(
                                                  color: secondaryColor),
                                            ),
                                            content: SingleChildScrollView(
                                              child: Container(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Amount",
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      textAlign: TextAlign.center,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          color: secondaryColor,
                                                          fontSize: 25,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                      NumberFormat.compact()
                                                          .format(double.parse(
                                                              amount!)),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      textAlign: TextAlign.center,
                                                      style:
                                                          GoogleFonts.montserrat(
                                                        textStyle:
                                                            const TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color: secondaryColor,
                                                          fontSize: 60,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Container(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Jazzicon.getIconWidget(
                                                              Jazzicon.getJazziconData(
                                                                  160,
                                                                  address:
                                                                      widget.coin[
                                                                          'id']),
                                                              size: 25),
                                                          SizedBox(
                                                            width: 10,
                                                          ),
                                                          Container(
                                                            width: 100,
                                                            child: Text(
                                                              widget
                                                                  .coin['symbol'],
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
                                                    SizedBox(
                                                      height: 20,
                                                    ),
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: secondaryColor,
                                                            width: 1.0),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                20),
                                                      ),
                                                      padding: EdgeInsets.all(15),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // Ether gas
                                                          Container(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Container(
                                                                  width:
                                                                      size.width *
                                                                          0.2,
                                                                  child: Text(
                                                                    "Gas price",
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 3,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 5,
                                                                ),
                                                                Container(
                                                                  width:
                                                                      size.width *
                                                                          0.2,
                                                                  child: Text(
                                                                    "${etherGas.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2)} GWEI",
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 3,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
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
                                                          // Estimate gas
                                                          Container(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Container(
                                                                  width:
                                                                      size.width *
                                                                          0.2,
                                                                  child: Text(
                                                                    "Estimate gas price for this transaction",
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 5,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .start,
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            13,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                  width: 5,
                                                                ),
                                                                Container(
                                                                  width:
                                                                      size.width *
                                                                          0.2,
                                                                  child: Text(
                                                                    "${NumberFormat.compact().format(EtherAmount.fromUnitAndValue(EtherUnit.gwei, estimateGas).getValueInUnit(EtherUnit.gwei))} GWEI",
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    maxLines: 3,
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style: GoogleFonts
                                                                        .montserrat(
                                                                      textStyle:
                                                                          const TextStyle(
                                                                        overflow:
                                                                            TextOverflow
                                                                                .ellipsis,
                                                                        color:
                                                                            secondaryColor,
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w300,
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
                                                                CupertinoIcons
                                                                    .exclamationmark_circle,
                                                                color:
                                                                    secondaryColor,
                                                              ),
                                                              SizedBox(
                                                                width: 5,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  "Estimate gas price might be significantly higher that the actual price",
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 5,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    textStyle:
                                                                        const TextStyle(
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      color:
                                                                          secondaryColor,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
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
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Container(
                                                                width:
                                                                    size.width *
                                                                        0.2,
                                                                child: Text(
                                                                  "Total",
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 3,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .start,
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    textStyle:
                                                                        const TextStyle(
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      color:
                                                                          secondaryColor,
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                width: 5,
                                                              ),
                                                              Container(
                                                                width:
                                                                    size.width *
                                                                        0.2,
                                                                child: Text(
                                                                  "${etherGas.getValueInUnit(EtherUnit.gwei)} GWEI",
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                  maxLines: 3,
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end,
                                                                  style: GoogleFonts
                                                                      .montserrat(
                                                                    textStyle:
                                                                        const TextStyle(
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      color:
                                                                          secondaryColor,
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
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
                                                        Navigator.of(context)
                                                            .pop(false);
                                                        setState(() {
                                                          loading = true;
                                                        });
                                                        BigInt chainId =
                                                            await widget
                                                                .web3client
                                                                .getChainId();

                                                        Transaction transaction =
                                                            await Transaction
                                                                .callContract(
                                                          contract: widget
                                                              .coin['contract'],
                                                          function: widget
                                                              .coin['contract']
                                                              .function(
                                                                  'transfer'),
                                                          parameters: [
                                                            EthereumAddress.fromHex(
                                                                receiverPublicAddress!),
                                                            BigInt.from((double
                                                                    .parse(
                                                                        amount!) *
                                                                BigInt.from(pow(
                                                                        10, 18))
                                                                    .toDouble())),
                                                          ],
                                                        );
                                                        String notifTitle =
                                                            "Success";
                                                        String notifBody =
                                                            "Transaction made";
                                                        Color notifColor =
                                                            Colors.green;

                                                        // ignore: unused_local_variable
                                                        bool txSuccess = true;
                                                        String transactionResult =
                                                            await widget
                                                                .web3client
                                                                .sendTransaction(
                                                          walletData[
                                                              'credentials'],
                                                          transaction,
                                                          chainId:
                                                              chainId.toInt(),
                                                        )
                                                                .onError((error,
                                                                    stackTrace) {
                                                          notifTitle = "Error";
                                                          notifBody = error
                                                                      .toString() ==
                                                                  'RPCError: got code -32000 with msg "gas required exceeds allowance (0)".'
                                                              ? "Not enough gas. Buy ether"
                                                              : error.toString();
                                                          notifColor = Colors.red;
                                                          txSuccess = false;
                                                          showNotification(
                                                              notifTitle,
                                                              notifBody,
                                                              notifColor);
                                                          return error.toString();
                                                        });
                                                        if (txSuccess) {
                                                          checkTx(
                                                              transactionResult);
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
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    });
                              } else {
                                setState(() {
                                  loading = false;
                                  error = 'Error2';
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
            ),
          );
  }

  void checkTx(String tx) async {
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
            await widget.web3client.getTransactionReceipt(tx);
        timeCounter++;
        print("GTEGTER");
        print(txReceipt);
        if (timeCounter >= 12) {
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
            showNotification('Success', 'Transaction made', Colors.green);
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
