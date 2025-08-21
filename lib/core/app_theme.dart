import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/core/constants.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    // Base Theme Configuration
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: "Roboto",
    primaryColor: AppColors.orange,
    scaffoldBackgroundColor: AppColors.white,

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: AppColors.orange,
      circularTrackColor: AppColors.orange.withValues(alpha: 0.2),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.orange,
      foregroundColor: AppColors.white,
      iconTheme: IconThemeData(color: AppColors.white),
      actionsIconTheme: IconThemeData(color: AppColors.white),
      titleTextStyle: TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: "Roboto",
      ),
      // This ensures the automatic back button uses the foregroundColor
      toolbarTextStyle: TextStyle(color: AppColors.white),
      systemOverlayStyle: null,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.white, // Dialog background
      titleTextStyle: TextStyle(
        color: AppColors.black,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: "Roboto",
      ),
      contentTextStyle: TextStyle(
        color: AppColors.darkGrey,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: "Roboto",
      ),
    ),

    // Icon Themes
    iconTheme: const IconThemeData(color: AppColors.white),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(iconColor: WidgetStatePropertyAll(AppColors.white)),
    ),

    // Button Themes
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(AppColors.black),
        iconColor: const WidgetStatePropertyAll(AppColors.black),
        textStyle: WidgetStateProperty.all(
          const TextStyle(color: AppColors.black, fontFamily: "Roboto"),
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        iconColor: AppColors.black,
        elevation: 0,
        foregroundColor: AppColors.black,
        backgroundColor: AppColors.white,
        shadowColor: Colors.transparent,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 48,
          fontFamily: "Roboto",
          color: AppColors.black,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    ),

    // Notification Theme
    snackBarTheme: const SnackBarThemeData(closeIconColor: AppColors.white),

    // Form Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: Constants.br8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.white,
        fontSize: 26,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: AppColors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: AppColors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      titleSmall: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: AppColors.white,
      ),
      bodyLarge: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: AppColors.white,
      ),
      bodyMedium: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 14.5,
        color: AppColors.white,
      ),
      bodySmall: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: AppColors.white,
      ),
    ),
  );
}
