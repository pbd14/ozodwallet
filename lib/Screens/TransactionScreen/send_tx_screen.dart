import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class SendTxScreen extends StatefulWidget {
  String error;
  String walletIndex;
  String networkId;
  Web3Client web3client;
  List walletAssets;

  SendTxScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.walletIndex,
    required this.networkId,
    required this.web3client,
    required this.walletAssets,
  }) : super(key: key);

  @override
  State<SendTxScreen> createState() => _SendTxScreenState();
}

class _SendTxScreenState extends State<SendTxScreen> {
  bool loading = true;
  String error = '';
  final _formKey = GlobalKey<FormState>();
  Map<EtherUnit, String> cryptoUnits = {
    EtherUnit.ether: 'ETH',
    EtherUnit.wei: 'WEI',
    EtherUnit.gwei: 'GWEI',
  };
  EtherUnit selectedEtherUnit = EtherUnit.ether;

  String? receiverPublicAddress;
  String? amount;
  Map walletData = {};
  Map selectedAsset = {'symbol': 'ETH'};
  List walletAssets = [];
  EtherAmount? balance;
  Client httpClient = Client();
  firestore.DocumentSnapshot? walletFirebase;
  Future<void> prepare() async {
    walletFirebase = await firestore.FirebaseFirestore.instance
        .collection('wallets')
        .doc(walletData['address'].toString())
        .get();
    walletData = await SafeStorageService().getWalletData(widget.walletIndex);
    balance = await widget.web3client.getBalance(walletData['address']);
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
                        child: Row(
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
                      TextFormField(
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
                          errorBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.red, width: 1.0),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                          hintStyle: TextStyle(
                              color: darkPrimaryColor.withOpacity(0.7)),
                          hintText: 'Receiver',
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: secondaryColor, width: 1.0),
                          ),
                        ),
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
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<Map>(
                            decoration: InputDecoration(
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40.0),
                                borderSide:
                                    BorderSide(color: Colors.red, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40.0),
                                borderSide: BorderSide(
                                    color: secondaryColor, width: 1.0),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40.0),
                                borderSide: BorderSide(
                                    color: secondaryColor, width: 1.0),
                              ),
                              // hintStyle: TextStyle(
                              //     color: darkPrimaryColor.withOpacity(0.7)),
                              // hintText: 'Asset',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40.0),
                                borderSide: BorderSide(
                                    color: secondaryColor, width: 1.0),
                              ),
                            ),
                            isDense: false,
                            menuMaxHeight: 200,
                            borderRadius: BorderRadius.circular(40.0),
                            dropdownColor: darkPrimaryColor,
                            focusColor: secondaryColor,
                            iconEnabledColor: secondaryColor,
                            alignment: Alignment.centerLeft,
                            onChanged: (asset) {
                              setState(() {
                                loading = true;
                              });

                              if (asset!['symbol'] != 'ETH') {
                                setState(() {
                                  selectedAsset = asset;
                                  loading = false;
                                });
                              } else {
                                setState(() {
                                  selectedAsset = {'symbol': 'ETH'};
                                  loading = false;
                                });
                              }
                            },
                            hint: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Image.network(
                                  'https://assets.coingecko.com/coins/images/279/large/ethereum.png?1595348880',
                                  width: 30,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'ETH',
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
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
                              for (Map asset in widget.walletAssets)
                                DropdownMenuItem<Map>(
                                  value: asset,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Jazzicon.getIconWidget(
                                            Jazzicon.getJazziconData(160,
                                                address: asset['address']),
                                            size: 15),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        // Container(
                                        //   width: 100,
                                        //   child: Column(
                                        //     mainAxisAlignment:
                                        //         MainAxisAlignment.center,
                                        //     children: [
                                        //       // Image.network('')
                                        //       Text(
                                        //         (asset['balance'] /
                                        //                 BigInt.from(
                                        //                     pow(10, 18)))
                                        //             .toString(),
                                        //         overflow: TextOverflow.ellipsis,
                                        //         maxLines: 3,
                                        //         textAlign: TextAlign.start,
                                        //         style: GoogleFonts.montserrat(
                                        //           textStyle: const TextStyle(
                                        //             color: secondaryColor,
                                        //             fontSize: 15,
                                        //             fontWeight: FontWeight.w600,
                                        //           ),
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),

                                        Container(
                                          width: 100,
                                          child: Text(
                                            asset['symbol'],
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
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
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),

                      // B
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
                                } else if (selectedAsset['symbol'] == 'ETH'
                                    ? double.parse(val) >=
                                        balance!
                                            .getValueInUnit(selectedEtherUnit)
                                    : double.parse(val) >=
                                        (selectedAsset['balance'] /
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
                              width: 100,
                              child: Center(
                                child: selectedAsset['symbol'] == 'ETH'
                                    ? DropdownButtonHideUnderline(
                                        child: DropdownButton<EtherUnit>(
                                          borderRadius:
                                              BorderRadius.circular(20.0),
                                          dropdownColor: darkPrimaryColor,
                                          focusColor: secondaryColor,
                                          iconEnabledColor: secondaryColor,
                                          alignment: Alignment.centerLeft,
                                          onChanged: (unit) {
                                            setState(() {
                                              selectedEtherUnit = unit!;
                                            });
                                          },
                                          hint: Text(
                                            cryptoUnits[selectedEtherUnit]!,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.montserrat(
                                              textStyle: const TextStyle(
                                                color: secondaryColor,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
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
                                                      MainAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      cryptoUnits[unit]!,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
                                          ],
                                        ),
                                      )
                                    : Text(
                                        selectedAsset['symbol'],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.montserrat(
                                          textStyle: const TextStyle(
                                            color: secondaryColor,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              selectedAsset['symbol'] == 'ETH'
                                  ? "Balance: ${balance!.getValueInUnit(selectedEtherUnit).toString()}  ${cryptoUnits[selectedEtherUnit]}"
                                  : "Balance: " +
                                      (selectedAsset['balance'] /
                                              BigInt.from(pow(10, 18)))
                                          .toString(),
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
                              EtherAmount etherGas = await widget.web3client.getGasPrice();
                              BigInt estimateGas =
                                  await widget.web3client.estimateGas(
                                sender: walletData['address'],
                                to: EthereumAddress.fromHex(
                                    receiverPublicAddress!),
                                value: EtherAmount.fromUnitAndValue(
                                    selectedEtherUnit,
                                    selectedAsset['symbol'] == 'ETH'
                                        ? amount
                                        : 0),
                              );
                              BigInt total = selectedAsset['symbol'] == 'ETH'
                                  ? estimateGas +
                                      BigInt.from(EtherAmount.fromUnitAndValue(
                                              selectedEtherUnit, amount)
                                          .getValueInUnit(EtherUnit.gwei))
                                  : estimateGas;
                              
                              setState(() {
                                loading = false;
                              });
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
                                                    amount!,
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
                                                  selectedAsset['symbol'] ==
                                                          'ETH'
                                                      ? Text(
                                                          cryptoUnits[
                                                              selectedEtherUnit]!,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 3,
                                                          textAlign:
                                                              TextAlign.center,
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
                                                        )
                                                      : Text(
                                                          selectedAsset[
                                                              'symbol'],
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 3,
                                                          textAlign:
                                                              TextAlign.center,
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
                                                  SizedBox(
                                                    height: 20,
                                                  ),
                                                  if (estimateGas >=
                                                      BigInt.from(EtherAmount
                                                              .fromUnitAndValue(
                                                                  selectedEtherUnit,
                                                                  amount)
                                                          .getValueInUnit(
                                                              EtherUnit.gwei)))
                                                    Container(
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.red,
                                                            width: 1.0),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding:
                                                          EdgeInsets.all(15),
                                                      margin: EdgeInsets.only(
                                                          bottom: 10),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            CupertinoIcons
                                                                .exclamationmark_circle_fill,
                                                            color: Colors.red,
                                                          ),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              "Gap price for this transaction is higher than the amount to be sent",
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
                                                                  color: Colors
                                                                      .red,
                                                                  fontSize: 15,
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
                                                                  maxLines: 4,
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
                                                                  "${EtherAmount.fromUnitAndValue(EtherUnit.gwei, estimateGas).getValueInUnit(EtherUnit.ether)} ETH",
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
                                                            color: secondaryColor,
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
                                                                  color: secondaryColor,
                                                                  fontSize: 10,
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
                                                                "${EtherAmount.fromUnitAndValue(EtherUnit.gwei, total).getValueInUnit(EtherUnit.ether)} ETH",
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
                                                      // ETH
                                                      if (selectedAsset[
                                                              'symbol'] ==
                                                          'ETH') {
                                                        widget.web3client
                                                            .sendTransaction(
                                                          walletData[
                                                              'credentials'],
                                                          Transaction(
                                                            to: EthereumAddress
                                                                .fromHex(
                                                                    receiverPublicAddress!),
                                                            // gasPrice: EtherAmount.inWei(BigInt.one),
                                                            // maxGas: 100000,
                                                            value: EtherAmount
                                                                .fromUnitAndValue(
                                                                    selectedEtherUnit,
                                                                    amount),
                                                          ),
                                                          chainId:
                                                              chainId.toInt(),
                                                        )
                                                            .catchError((error,
                                                                stackTrace) {
                                                          
                                                          showNotification('Failed','Failed to make transaction',Colors.red); 
                                                        });
                                                        showNotification('Success','Transaction made',Colors.green); 
                                                        
                                                        setState(() {
                                                          loading = false;
                                                        });
                                                      } else {
                                                        String notifTitle =
                                                            "Success";
                                                        String notifBody =
                                                            "Transaction made";
                                                        Color notifColor =
                                                            Colors.green;
                                                        Transaction
                                                            transaction =
                                                            await Transaction
                                                                .callContract(
                                                          contract:
                                                              selectedAsset[
                                                                  'contract'],
                                                          function: selectedAsset[
                                                                  'contract']
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

                                                        final transfer =
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
                                                              : "Servers are overloaded. Try again later";
                                                          notifColor =
                                                              Colors.red;
                                                          return error
                                                              .toString();
                                                        });
                                                        if (await transfer !=
                                                            null) {
                                                          showNotification(notifTitle,notifBody,notifColor); 
                                                        }
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
