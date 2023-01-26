import 'dart:convert';

import 'package:http/http.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Services/encryption_service.dart';
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
  String error = '';
  final _formKey = GlobalKey<FormState>();
  EtherUnit selectedEtherUnit = EtherUnit.ether;

  String? receiverPublicAddress;
  String? amount;
  Map walletData = {};
  Map selectedCoin = {'symbol': 'UZSO'};
  EtherAmount? balance;
  Client httpClient = Client();
  firestore.DocumentSnapshot? walletFirebase;
  firestore.DocumentSnapshot? appData;
  firestore.DocumentSnapshot? appDataApi;

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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
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
                              child: Text(
                                widget.coin['symbol'],
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
                              print("GRGRG");
                              print(amount!);
                              print(double.parse(amount!));
                              print(BigInt.from((double.parse(amount!) *
                                  BigInt.from(pow(10, 18)).toDouble())));
                              Transaction transaction =
                                  await Transaction.callContract(
                                contract: widget.coin['contract'],
                                function: widget.coin['contract']
                                    .function('transfer'),
                                parameters: [
                                  EthereumAddress.fromHex(
                                      receiverPublicAddress!),
                                  BigInt.from((double.parse(amount!) *
                                      BigInt.from(pow(10, 18)).toDouble())),
                                ],
                              );
                              String notifTitle = "Success";
                              String notifBody = "Transaction made";
                              Color notifColor = Colors.green;

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

                              setState(() {
                                loading = false;
                              });
                              Navigator.pop(context);
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
