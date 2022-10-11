import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color color, secondaryColor;
  const AppLogo({Key key, this.size, this.color, this.secondaryColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "zando ",
                style: GoogleFonts.bungeeInline(
                  color: color ?? Colors.pink,
                  fontWeight: FontWeight.w900,
                  fontSize: size != null ? size - 5 : 35.0,
                ),
              ),
              TextSpan(
                text: " Graphics",
                style: GoogleFonts.bungeeInline(
                  color: secondaryColor ?? Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: size != null ? size - 5 : 35.0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
