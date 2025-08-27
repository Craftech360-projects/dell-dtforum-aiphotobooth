import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Runpod Configuration
  static String get runpodApiKey => dotenv.env['RUNPOD_API_KEY'] ?? '';
  static String get runpodEndpointUrl => dotenv.env['RUNPOD_SWAPLAB_URL'] ?? '';
  static String get comfyUIEndpointUrl => dotenv.env['RUNPOD_COMFYUI_URL'] ?? '';
  
  // Gemini API Configuration
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // You can add environment-specific configurations here
  static const bool isProduction = false;
  
  // Initialize dotenv
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }
}