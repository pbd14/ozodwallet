import 'dart:math';
import 'dart:typed_data';
import 'package:bip39/bip39.dart';
import 'package:blur/blur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hex/hex.dart';
import 'package:ozodwallet/Models/Web3Wallet.dart';
import 'package:ozodwallet/Services/auth/auth_service.dart';
import 'package:ozodwallet/Services/notification_service.dart';
import 'package:ozodwallet/Services/safe_storage_service.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';
import 'package:ozodwallet/Widgets/rounded_button.dart';
import 'package:ozodwallet/constants.dart';
import 'package:web3dart/web3dart.dart';

class EmailSignUpScreen extends StatefulWidget {
  final String errors;
  const EmailSignUpScreen({Key? key, this.errors = ''}) : super(key: key);
  @override
  _EmailSignUpScreenState createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
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
                      height: 50,
                    ),
                    Image.asset(
                      "assets/icons/logoAuth300.png",
                      width: size.width * 0.9,
                    ).frosted(
                      frostColor: ozodIdColor1,
                      blur: 5,
                      borderRadius: BorderRadius.circular(20),
                      padding: EdgeInsets.all(0),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What is Ozod ID?',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: ozodIdColor1,
                            fontSize: 45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Managing you web3 Wallet can be hard. If you lose your private key, you will lose your web3 wallet FOREVER. Fortunately, with Ozod Auth you can forget about private keys. Just create an ordinary account and we will keep your keys safe.',
                        textAlign: TextAlign.start,
                        style: GoogleFonts.montserrat(
                          textStyle: const TextStyle(
                            color: ozodIdColor1,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      // width: size.width * 0.8,
                      // height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 70, 213, 196),
                            ozodIdColor1
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'One account, many wallets',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'You can add multiple wallets to one account. Everytime you log into your accout, you will get access to all wallets',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      // width: size.width * 0.8,
                      // height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 70, 213, 196),
                            ozodIdColor1
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Risk free',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'With Ozod ID, you do not need to manage your keys. All private keys will be managed by us. And if you forget your private key or lose access to your wallet, we will help you to regain it',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      // width: size.width * 0.8,
                      // height: 200,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 70, 213, 196),
                            ozodIdColor1
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Easy and fast',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Save your time with fast authentication. Email and password is all you need',
                            textAlign: TextAlign.start,
                            style: GoogleFonts.montserrat(
                              textStyle: const TextStyle(
                                color: ozodIdColor2,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Text(
                      "Email Sign Up",
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
                                    color: ozodIdColor1.withOpacity(0.7)),
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
                                  password2 = val;
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
                                hintText: 'Confirm password',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: ozodIdColor1, width: 1.0),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            RoundedButton(
                              width: 0.4,
                              ph: 45,
                              text: 'GO',
                              press: () async {
                                if (_formKey.currentState!.validate()) {
                                  if (password == password2) {
                                    setState(() {
                                      loading = true;
                                    });
                                    String? res = await AuthService()
                                        .signUpWithEmail(email, password);
                                    if (res == 'Success') {
                                      try {
                                        await FirebaseAuth.instance.currentUser!
                                            .sendEmailVerification();

                                        // Create Web3 Wallet
                                        String mnemonicPhrase =
                                            generateMnemonic();
                                        Uint8List seed =
                                            mnemonicToSeed(mnemonicPhrase);
                                        final master = await ED25519_HD_KEY
                                            .getMasterKeyFromSeed(seed);
                                        final privateKey =
                                            HEX.encode(master.key);
                                        final publicKey =
                                            EthPrivateKey.fromHex(privateKey)
                                                .address;
                                        String lastWalletIndex = await SafeStorageService().storage
                                                .read(key: "lastWalletIndex") ??
                                            "1";
                                        Web3Wallet web3wallet = Web3Wallet(
                                            privateKey: privateKey,
                                            publicKey: publicKey.toString(),
                                            name: "Wallet Name",
                                            localIndex: lastWalletIndex);
                                        await SafeStorageService()
                                            .addNewWallet(web3wallet);
                                        // ignore: unused_local_variable
                                        Wallet wallet = Wallet.createNew(
                                            EthPrivateKey.fromHex(privateKey),
                                            "Password",
                                            Random());
                                        await FirebaseFirestore.instance
                                            .collection('wallets')
                                            .doc(publicKey.toString())
                                            .set({
                                          'loyalty_programs': [],
                                          'publicKey': publicKey.toString(),
                                          'assets': [],
                                          'privateKey':
                                              web3wallet.encPrivateKey(
                                                  web3wallet.privateKey),
                                          'ozodIdConnected': true,
                                          'ozodIdAccount': FirebaseAuth
                                              .instance.currentUser!.uid,
                                        });

                                        await FirebaseFirestore.instance
                                            .collection('ozod_id_accounts')
                                            .doc(FirebaseAuth
                                                .instance.currentUser!.uid)
                                            .set({
                                          'id': FirebaseAuth
                                              .instance.currentUser!.uid,
                                          'email': FirebaseAuth
                                              .instance.currentUser!.email,
                                          'wallets': [web3wallet.publicKey],
                                        });
                                        showNotification(
                                            'Success',
                                            'Account has been created',
                                            greenColor);
                                      } catch (e) {
                                        showNotification('Failed',
                                            'Try again later', greenColor);
                                      }

                                      Navigator.pop(context);
                                      Navigator.pop(context);

                                      setState(() {
                                        loading = false;
                                      });
                                    } else {
                                      setState(() {
                                        loading = false;
                                        error = res ?? "Error";
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      error = 'Passwords should match';
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
