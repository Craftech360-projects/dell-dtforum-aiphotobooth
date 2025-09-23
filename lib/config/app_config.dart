import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Gemini API Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // You can add environment-specific configurations here
  static const bool isProduction = false;

  // Initialize dotenv
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
}