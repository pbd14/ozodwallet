import 'package:ozodwallet/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key }) : super(key: key);
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Container(
          color: primaryColor,
          child: const Center(
            child: SpinKitWave(
              color: secondaryColor,
              size: 50.0,
            ),
          ),
        ),
      ),
    );
  }
}
