import 'package:flutter/material.dart';

class Constants {
//Heights & Widths
  static const w4 = SizedBox(
    width: 04,
  );
  static const w8 = SizedBox(
    width: 8,
  );
  static const w16 = SizedBox(
    width: 16,
  );
  static const w24 = SizedBox(
    width: 24,
  );
  static const w32 = SizedBox(
    width: 32,
  );
  static const h1 = SizedBox(
    height: 01,
  );
  static const h4 = SizedBox(
    height: 4,
  );
  static const h8 = SizedBox(
    height: 8,
  );
  static const h16 = SizedBox(
    height: 16,
  );
  static const h20 = SizedBox(
    height: 20,
  );
  static const h24 = SizedBox(
    height: 24,
  );
  static const h32 = SizedBox(
    height: 32,
  );

//Paddings
  static const pV8H8 =
      Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0));
  static const pV10H16 =
      Padding(padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0));
  static const pV12H12 =
      Padding(padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0));
  static const pV12H16 =
      Padding(padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0));
  static const pV16H16 =
      Padding(padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0));
  static const pV16H22 =
      Padding(padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 22.0));

// Border Radiuses
  static BorderRadius br2 = BorderRadius.circular(02);
  static BorderRadius br4 = BorderRadius.circular(04);
  static BorderRadius br8 = BorderRadius.circular(08);
  static BorderRadius br10 = BorderRadius.circular(10);
  static BorderRadius br12 = BorderRadius.circular(12);
  static BorderRadius br16 = BorderRadius.circular(16);
  static BorderRadius br24 = BorderRadius.circular(24);
  static BorderRadius br32 = BorderRadius.circular(32);
  static BorderRadius br40 = BorderRadius.circular(40);
  

// Input Border Constants
  static final inputBorder = OutlineInputBorder(
    borderRadius: br8,
    borderSide: BorderSide.none,
  );

  static final inputBorderFocused = OutlineInputBorder(
    borderRadius: br8,
    borderSide: const BorderSide(color: Colors.blue, width: 1.5),
  );
}
