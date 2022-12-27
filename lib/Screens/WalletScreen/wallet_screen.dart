import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ozodwallet/Widgets/loading_screen.dart';

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
  String publicKey = 'Loading';

  Future<void> prepare() async {
    AndroidOptions _getAndroidOptions() => const AndroidOptions(
          encryptedSharedPreferences: true,
        );
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    String? value = await storage.read(key: 'publicKey');
    setState(() {
      value != null ? publicKey = value : publicKey = 'Error';
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
            body: Center(
              child: Text(publicKey,),
            ),
          );
  }
}
