import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final Function()? press;
  final Color color, textColor;
  final double width, height, pw, ph;
  const RoundedButton(
      {Key? key,
      required this.text,
      required this.press,
      required this.color,
      required this.textColor,
      this.width = 0,
      this.height = 0,
      this.pw = 0,
      this.ph = 0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: pw == 0 ? size.width * width : pw,
      height: ph == 0 ? size.height * height : ph,
      decoration: BoxDecoration(
        color: color,
        // boxShadow: [
        //   BoxShadow(
        //     color: color.withOpacity(0.5),
        //     spreadRadius: 5,
        //     blurRadius: 7,
        //     offset: const Offset(0, 3), // changes position of shadow
        //   ),
        // ],
        borderRadius: BorderRadius.circular(29),
        shape: BoxShape.rectangle,
      ),
      child: Container(
        // padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: press,
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              textStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700
              ),
            ),
          ),
        ),
      ),
    );
  }
}
