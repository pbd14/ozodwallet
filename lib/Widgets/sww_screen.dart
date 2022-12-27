import 'package:ozodwallet/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: must_be_immutable
class SomethingWentWrongScreen extends StatelessWidget {
  String error;
  SomethingWentWrongScreen({Key? key, this.error = 'Something Went Wrong'}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(
          color: secondaryColor,
        ),
        title: Text(
          'Error',
          textScaleFactor: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            textStyle: const TextStyle(
                color: secondaryColor, fontSize: 20, fontWeight: FontWeight.w300),
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(

              textStyle: const TextStyle(
                color: secondaryColor,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
