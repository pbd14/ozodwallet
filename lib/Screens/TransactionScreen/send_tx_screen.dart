import 'package:http/http.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
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
                        height: 50,
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
                        height: 50,
                      ),
                      Text(
                        "To",
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
                        height: 20,
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
                      const SizedBox(height: 40),
                      Text(
                        "Amount",
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(color: secondaryColor),
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
                                  amount = val;
                                });
                              },
                              decoration: InputDecoration(
                                errorBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.red, width: 1.0),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: secondaryColor, width: 1.0),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: secondaryColor, width: 1.0),
                                ),
                                hintStyle: TextStyle(
                                    color: darkPrimaryColor.withOpacity(0.7)),
                                hintText: 'Amount',
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: secondaryColor, width: 1.0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 5,
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
                                                    style:
                                                        GoogleFonts.montserrat(
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
                        ],
                      ),
                      const SizedBox(
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
                      const SizedBox(height: 50),
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
                              BigInt chainId =
                                  await widget.web3client.getChainId();
                              // ETH
                              if (selectedAsset['symbol'] == 'ETH') {
                                widget.web3client
                                    .sendTransaction(
                                  walletData['credentials'],
                                  Transaction(
                                    to: EthereumAddress.fromHex(
                                        receiverPublicAddress!),
                                    // gasPrice: EtherAmount.inWei(BigInt.one),
                                    // maxGas: 100000,
                                    value: EtherAmount.fromUnitAndValue(
                                        selectedEtherUnit, amount),
                                  ),
                                  chainId: chainId.toInt(),
                                )
                                    .catchError((error, stackTrace) {
                                  PushNotificationMessage notification =
                                      PushNotificationMessage(
                                    title: 'Failed',
                                    body: 'Failed to make transaction',
                                  );
                                  showSimpleNotification(
                                    Text(notification.body),
                                    position: NotificationPosition.top,
                                    background: Colors.red,
                                  );
                                });
                                PushNotificationMessage notification =
                                    PushNotificationMessage(
                                  title: 'Success',
                                  body: 'Transaction made',
                                );
                                showSimpleNotification(
                                  Text(notification.body),
                                  position: NotificationPosition.top,
                                  background: Colors.green,
                                );
                                setState(() {
                                  loading = false;
                                });
                                Navigator.pop(context);
                              } else {
                                String notifTitle = "Success";
                                String notifBody = "Transaction made";
                                Color notifColor = Colors.green;
                                Transaction transaction =
                                    await Transaction.callContract(
                                  contract: selectedAsset['contract'],
                                  function: selectedAsset['contract']
                                      .function('transfer'),
                                  parameters: [
                                    EthereumAddress.fromHex(
                                        receiverPublicAddress!),
                                    BigInt.from((double.parse(amount!) *
                                        BigInt.from(pow(10, 18)).toDouble())),
                                  ],
                                );

                                final transfer = await widget.web3client
                                    .sendTransaction(
                                  walletData['credentials'],
                                  transaction,
                                  chainId: chainId.toInt(),
                                )
                                    .onError((error, stackTrace) {
                                  notifTitle = "Error";
                                  notifBody = error.toString() ==
                                          'RPCError: got code -32000 with msg "gas required exceeds allowance (0)".'
                                      ? "Not enough gas. Buy ether"
                                      : "Error";
                                  notifColor = Colors.red;

                                  return error.toString();
                                });
                                if (await transfer != null) {
                                  PushNotificationMessage notification =
                                      PushNotificationMessage(
                                    title: notifTitle,
                                    body: notifBody,
                                  );
                                  showSimpleNotification(
                                    Text(notification.body),
                                    position: NotificationPosition.top,
                                    background: notifColor,
                                  );
                                }
                                setState(() {
                                  loading = false;
                                });
                                Navigator.pop(context);
                              }
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
