import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Services/auth/auth_service.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';

class EmailLoginScreen extends StatefulWidget {
  Function? mainScreenRefreshFunction = null;
  final String errors;
  EmailLoginScreen({
    Key? key,
    this.errors = '',
    this.mainScreenRefreshFunction,
  }) : super(key: key);
  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late String email;
  late String password;
  late String password2;
  late String verificationId;
  String error = '';

  bool loading = false;

  // Future<void> checkVersion() async {
  //   RemoteConfig remoteConfig = RemoteConfig.instance;
  //   // ignore: unused_local_variable
  //   bool updated = await remoteConfig.fetchAndActivate();
  //   String requiredVersion = remoteConfig.getString(Platform.isAndroid
  //       ? 'footy_google_play_version'
  //       : 'footy_appstore_version');
  //   String appStoreLink = remoteConfig.getString('footy_appstore_link');
  //   String googlePlayLink = remoteConfig.getString('footy_google_play_link');

  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   if (packageInfo.version != requiredVersion) {
  //     NativeUpdater.displayUpdateAlert(
  //       context,
  //       forceUpdate: true,
  //       appStoreUrl: appStoreLink,
  //       playStoreUrl: googlePlayLink,
  //     );
  //   }
  // }

  @override
  void initState() {
    // checkVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? LoadingScreen()
        : Scaffold(
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: true,
              toolbarHeight: 30,
              backgroundColor: ozodIdColor2,
              foregroundColor: ozodIdColor1,
              centerTitle: true,
              actions: [],
            ),
            backgroundColor: ozodIdColor2,
            body: SingleChildScrollView(
              child: Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 70, 213, 196),
                            Color.fromARGB(255, 25, 66, 100),
                          ],
                        ),
                      ),
                      child: Container(
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/icons/logoAuth300.png',
                              width: 40,
                              height: 40,
                              // scale: 10,
                            ),
                            Text(
                              'Ozod ID',
                              style: GoogleFonts.montserrat(
                                textStyle: const TextStyle(
                                  color: whiteColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).asGlass(
                        blurX: 20,
                        blurY: 20,
                        clipBorderRadius: BorderRadius.circular(20.0),
                        tintColor: darkDarkColor,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                    ),
                    Text(
                      "Email Login",
                      style: GoogleFonts.montserrat(
                        textStyle: const TextStyle(
                          color: ozodIdColor1,
                          fontSize: 35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            TextFormField(
                              style: const TextStyle(color: whiteColor),
                              validator: (val) =>
                                  val!.isEmpty ? 'Enter your email' : null,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (val) {
                                setState(() {
                                  email = val;
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
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                hintStyle: TextStyle(
                                  color: ozodIdColor1.withOpacity(0.7),
                                ),
                                hintText: 'Email',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              obscureText: true,
                              enableSuggestions: false,
                              autocorrect: false,
                              style: const TextStyle(color: whiteColor),
                              validator: (val) => val!.length >= 5
                                  ? null
                                  : 'Minimum 5 characters',
                              keyboardType: TextInputType.visiblePassword,
                              onChanged: (val) {
                                setState(() {
                                  password = val;
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
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                hintStyle: TextStyle(
                                    color: ozodIdColor1.withOpacity(0.7)),
                                hintText: 'Password',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),

                            // RoundedPasswordField(
                            //   hintText: "Password",
                            //   onChanged: (value) {},
                            // ),
                            const SizedBox(height: 20),
                            RoundedButton(
                              width: 0.4,
                              ph: 45,
                              text: 'GO',
                              press: () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    loading = true;
                                  });
                                  String res = await AuthService()
                                      .signInWithEmail(email, password);
                                  if (res == 'Success') {
                                    try {
                                      DocumentSnapshot ozodIdUser =
                                          await FirebaseFirestore.instance
                                              .collection('ozod_id_accounts')
                                              .doc(FirebaseAuth
                                                  .instance.currentUser!.uid)
                                              .get();
                                      if (ozodIdUser.get('wallets') != null) {
                                        for (String publicKey
                                            in ozodIdUser.get('wallets')) {
                                          DocumentSnapshot firestoreWallet =
                                              await FirebaseFirestore.instance
                                                  .collection('wallets')
                                                  .doc(publicKey)
                                                  .get();
                                          List localWallets =
                                              await SafeStorageService()
                                                  .getAllWalletsPublicKeys();
                                          String lastWalletIndex =
                                              await SafeStorageService()
                                                      .storage
                                                      .read(
                                                          key:
                                                              "lastWalletIndex") ??
                                                  "1";

                                          if (!localWallets
                                              .contains(publicKey)) {
                                            await SafeStorageService()
                                                .addNewWallet(
                                              Web3Wallet(
                                                  privateKey: Web3Wallet()
                                                      .decPrivateKey(
                                                          firestoreWallet.get(
                                                              'privateKey')),
                                                  publicKey: publicKey,
                                                  name: "Wallet Name",
                                                  localIndex: lastWalletIndex),
                                            );
                                          }
                                        }
                                        if (widget.mainScreenRefreshFunction !=
                                            null) {
                                          Navigator.of(context).pop();
                                          widget.mainScreenRefreshFunction!();
                                        }
                                      }
                                    } catch (e) {
                                      print("ERROR: " + e.toString());
                                      showNotification(
                                        "Failed",
                                        "Failed to load wallets",
                                        Colors.red,
                                      );
                                    }
                                    Navigator.of(context).pop();
                                    setState(() {
                                      loading = false;
                                    });
                                  } else {
                                    setState(() {
                                      loading = false;
                                      error = res;
                                    });
                                  }
                                }
                              },
                              color: ozodIdColor1,
                              textColor: ozodIdColor2,
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                error,
                                style: GoogleFonts.montserrat(
                                  textStyle: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            // RoundedButton(
                            //   text: 'REGISTER',
                            //   press: () {
                            //     Navigator.push(
                            //         context, SlideRightRoute(page: RegisterScreen()));
                            //   },
                            //   color: lightPrimaryColor,
                            //   textColor: darkPrimaryColor,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
