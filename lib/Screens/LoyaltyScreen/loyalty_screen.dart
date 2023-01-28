import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jazzicon/jazzicon.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: must_be_immutable
class LoyaltyScreen extends StatefulWidget {
  String error;
  LoyaltyScreen({
    Key? key,
    this.error = 'Something Went Wrong',
  }) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  bool loading = true;
  ScrollController _scrollController = ScrollController();
  Client httpClient = Client();
  late Web3Client web3client;

  QuerySnapshot? loyaltyPrograms;
  List<DocumentSnapshot> walletLoyaltyPrograms = [];
  List<String> walletLoyaltyProgramsIds = [];
  List wallets = [];
  String selectedWalletIndex = "1";
  Map selectedWalletData = {};

  Future<void> _refresh() async {
    setState(() {
      loading = true;
    });
    wallets = [];
    walletLoyaltyPrograms = [];
    walletLoyaltyProgramsIds = [];
    prepare();
    Completer<void> completer = Completer<void>();
    completer.complete();
    return completer.future;
  }

  Future<void> prepare() async {
    await dotenv.load(fileName: ".env");
    web3client =
        Web3Client(dotenv.env['WEB3_QUICKNODE_GOERLI_URL']!, httpClient);
    wallets = await SafeStorageService().getAllWallets();
    selectedWalletData =
        await SafeStorageService().getWalletData(selectedWalletIndex);

    loyaltyPrograms = await FirebaseFirestore.instance
        .collection('loyalty_programs')
        .limit(20)
        .get();
    DocumentSnapshot walletFirebase = await FirebaseFirestore.instance
        .collection('wallets')
        .doc(selectedWalletData['address'].toString())
        .get();
    if (walletFirebase.exists) {
      for (String programId in walletFirebase.get('loyalty_programs')) {
        walletLoyaltyProgramsIds.add(programId);
        walletLoyaltyPrograms.add(await FirebaseFirestore.instance
            .collection('loyalty_programs')
            .doc(programId)
            .get());
      }
    }
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
                        Container(
                          margin: EdgeInsets.all(20),
                          child: Center(
                            child: Column(
                              children: [
                                SizedBox(height: size.height * 0.1),
                                Text(
                                  "Loyalty Programs",
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
                                  height: 30,
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
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      borderRadius: BorderRadius.circular(20.0),
                                      dropdownColor: darkPrimaryColor,
                                      focusColor: whiteColor,
                                      iconEnabledColor: secondaryColor,
                                      alignment: Alignment.centerLeft,
                                      onChanged: (walletIndex) {
                                        setState(() {
                                          selectedWalletIndex =
                                              walletIndex.toString();
                                          loading = true;
                                        });
                                        _refresh();
                                      },
                                      hint: Row(
                                        children: [
                                          Jazzicon.getIconWidget(
                                              Jazzicon.getJazziconData(160,
                                                  address: selectedWalletData[
                                                      'publicKey']),
                                              size: 25),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            selectedWalletData['name'],
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
                                        ],
                                      ),
                                      items: [
                                        for (Map wallet in wallets)
                                          DropdownMenuItem<int>(
                                            value: wallets.indexOf(wallet) + 1,
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
                                                      wallets.indexOf(wallet) +
                                                          1],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.montserrat(
                                                    textStyle: const TextStyle(
                                                      color: secondaryColor,
                                                      fontSize: 25,
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
                                  ),
                                ),
                                const SizedBox(
                                  height: 50,
                                ),
                                walletLoyaltyPrograms.isNotEmpty
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          "Joined",
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
                                      )
                                    : Container(),
                                const SizedBox(
                                  height: 30,
                                ),
                                for (DocumentSnapshot program
                                    in walletLoyaltyPrograms)
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color.fromARGB(255, 255, 190, 99),
                                          Color.fromARGB(255, 255, 81, 83)
                                        ],
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Container(
                                            width: 80,
                                            child: Text(
                                              program.get('token_symbol'),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: whiteColor,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width:
                                                size.width * 0.8 - 70 - 15 - 20,
                                            child: Text(
                                              program.get('name'),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.start,
                                              style: GoogleFonts.montserrat(
                                                textStyle: const TextStyle(
                                                  color: whiteColor,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(
                                  height: 50,
                                ),
                                for (DocumentSnapshot program
                                    in loyaltyPrograms!.docs)
                                  if (!walletLoyaltyProgramsIds
                                      .contains(program.id))
                                    Card(
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                      ),
                                      // margin: EdgeInsets.only(bottom: 10),
                                      color: darkPrimaryColor,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                              width: 50,
                                              child: Text(
                                                program.get('token_symbol'),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                textAlign: TextAlign.start,
                                                style: GoogleFonts.montserrat(
                                                  textStyle: const TextStyle(
                                                    color: secondaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: size.width * 0.7 -
                                                  20 -
                                                  50 -
                                                  70,
                                              child: Text(
                                                program.get('name'),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
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
                                              width: 70,
                                              child: RoundedButton(
                                                pw: 70,
                                                ph: 25,
                                                color: secondaryColor,
                                                text: 'Join',
                                                textColor: darkPrimaryColor,
                                                press: () async {
                                                  setState(() {
                                                    loading = true;
                                                  });
                                                  DocumentSnapshot
                                                      walletFromFirebase =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection('wallets')
                                                          .doc(
                                                              selectedWalletData[
                                                                      'address']
                                                                  .toString())
                                                          .get();

                                                  if (walletFromFirebase
                                                      .exists) {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('wallets')
                                                        .doc(selectedWalletData[
                                                                'address']
                                                            .toString())
                                                        .update({
                                                      "loyalty_programs":
                                                          FieldValue.arrayUnion(
                                                              [program.id]),
                                                      "assets": FieldValue
                                                          .arrayUnion([
                                                        {
                                                          'address': program
                                                              .get('token'),
                                                          'symbol': program.get(
                                                              'token_symbol'),
                                                          'network': 'goerli',
                                                          'decimals': 18,
                                                        }
                                                      ]),
                                                    }).onError(
                                                      (error, stackTrace) {
                                                        showNotification('Failed','Error',Colors.red);  
                                                        
                                                      },
                                                    );
                                                  } else {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('wallets')
                                                        .doc(selectedWalletData[
                                                                'address']
                                                            .toString())
                                                        .set({
                                                      "loyalty_programs":
                                                          FieldValue.arrayUnion(
                                                              [program.id]),
                                                      "assets": FieldValue
                                                          .arrayUnion([
                                                        {
                                                          'address': program
                                                              .get('token'),
                                                          'symbol': program.get(
                                                              'token_symbol'),
                                                              'network':'goerli',
                                                          'decimals': 18,
                                                        }
                                                      ]),
                                                    }).onError(
                                                      (error, stackTrace) {
                                                        showNotification('Failed','Error',Colors.red);  
                                                      },
                                                    );
                                                  }
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection(
                                                          'loyalty_programs')
                                                      .doc(program.id)
                                                      .update({
                                                    "members":
                                                        FieldValue.arrayUnion([
                                                      selectedWalletData[
                                                          'address']
                                                    ])
                                                  }).onError(
                                                    (error, stackTrace) {
                                                      showNotification('Failed','Error',Colors.red);  
                                                    },
                                                  );
                                                  _refresh();
                                                },
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                SizedBox(
                                  height: size.height * 0.5,
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
