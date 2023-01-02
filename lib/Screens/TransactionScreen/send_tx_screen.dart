import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart';
import 'package:date_format/date_format.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:ozodwallet/Models/PushNotificationMessage.dart';
import 'package:ozodwallet/Screens/WalletScreen/check_seed_screen.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/Widgets/slide_right_route_animation.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/web3dart.dart';

// ignore: must_be_immutable
class SendTxScreen extends StatefulWidget {
  String error;
  String walletIndex;
  Web3Client web3client;
  SendTxScreen({
    Key? key,
    this.error = 'Something Went Wrong',
    required this.walletIndex,
    required this.web3client,
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
  EtherAmount? balance;

  Future<void> prepare() async {
    print("PRERER");
    print(widget.walletIndex);
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
                              primaryColor,
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
                            SizedBox(width: 10,),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextFormField(
                              style: const TextStyle(color: secondaryColor),
                              validator: (val) {
                                if (val!.isEmpty) {
                                  return 'Enter amount';
                                } else if (double.parse(val) >=
                                    balance!
                                        .getValueInUnit(selectedEtherUnit)) {
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
                          Container(
                            width: 100,
                            child: Center(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<EtherUnit>(
                                  borderRadius: BorderRadius.circular(20.0),
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
                                    for (EtherUnit unit in cryptoUnits.keys)
                                      DropdownMenuItem<EtherUnit>(
                                        value: unit,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              cryptoUnits[unit]!,
                                              overflow: TextOverflow.ellipsis,
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
                                      ),
                                  ],
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
                        "Balance: ${balance!.getValueInUnit(selectedEtherUnit).toString()}  ${cryptoUnits[selectedEtherUnit]}",
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
                              final ethereumAddress = EthereumAddress.fromHex(
                                  receiverPublicAddress!);
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
