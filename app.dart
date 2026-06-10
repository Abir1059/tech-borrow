import 'package:flutter/material.dart';
import 'package:tech_borrow/ui/screens/splash_screen.dart';
import 'package:tech_borrow/ui/screens/utility/app_colors.dart';

class TechborrowApp extends StatelessWidget {
  const TechborrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tech Borrow',
      home: const SplashScreen(),
      theme: _lightThemeData(),
    );
  }

  ThemeData _lightThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Appcolors.primary,
        primary: Appcolors.primary,
        secondary: Appcolors.secondary,
        surface: Appcolors.surface,
        error: Appcolors.error,
        onPrimary: Appcolors.textOnPrimary,
        onSurface: Appcolors.textPrimary,
      ),
      scaffoldBackgroundColor: Appcolors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Appcolors.textPrimary),
        titleTextStyle: TextStyle(
          color: Appcolors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.white,
        filled: true,
        hintStyle: const TextStyle(
          color: Appcolors.textSecondary,
          fontSize: 14,
        ),
        prefixIconColor: Appcolors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Appcolors.primary, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Appcolors.textPrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Appcolors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Appcolors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Appcolors.textSecondary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Appcolors.primary,
          foregroundColor: Appcolors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          fixedSize: const Size.fromWidth(double.maxFinite),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Appcolors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        color: Colors.white,
      ),
    );
  }
}
