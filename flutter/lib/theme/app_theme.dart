import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryLight = Color(0xFF4DB6AC);  // Teal 300
  static const Color primaryDark = Color(0xFF26A69A);   // Teal 400
  static const Color tabBackground = Color(0xFFE0F2F1); // Teal 50
  static const Color tabText = Color(0xFF00695C);       // Teal 800

  // Text Styles
  static TextStyle get appBarTitle => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get tabTextStyle => GoogleFonts.inter(
    fontSize: 16,
    color: tabText,
  );

  // Gradients
  static BoxDecoration get appBarGradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryLight, primaryDark],
    ),
  );

  // Button Styles
  static ButtonStyle tabButtonStyle = TextButton.styleFrom(
    backgroundColor: tabBackground,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    overlayColor: primaryLight.withOpacity(0.2),
  );
} 