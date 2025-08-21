import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class SupabaseService {
  static const String supabaseUrl = 'https://qwcxcdcponxctenncila.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Y3hjZGNwb254Y3Rlbm5jaWxhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Nzk2OTYsImV4cCI6MjA3MTM1NTY5Nn0.CW24DqG4MyD0XzNxflLSXOreHPQ7zHE5AuLV0y0iY3A';
  
  static late SupabaseClient _client;
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    _client = Supabase.instance.client;
    _initialized = true;
    debugPrint('Supabase initialized successfully');
  }
  
  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client;
  }
  
  /// Get a random character image from Supabase based on gender
  static Future<Uint8List?> getRandomCharacterImage(String gender) async {
    try {
      // Available themes - matching exact folder names in Supabase
      final themes = [
        'sustainability_champions',
        'space_explorer',
        'cyberpunk_future',
        'futuristic_workspace',
        'extreme_sports',
        'fantasy_kingdom',
      ];
      
      // Pick a random theme
      final random = Random();
      final randomTheme = themes[random.nextInt(themes.length)];
      
      // Pick a random image number (1-7)
      final imageNumber = random.nextInt(7) + 1;
      final imageNumberStr = imageNumber.toString().padLeft(2, '0');
      
      // Construct the file path based on the actual Supabase structure
      // Structure: {gender}/{theme}/Male 01.png
      final genderFolder = gender.toLowerCase(); // 'male' or 'female'
      final filePrefix = gender == 'female' ? 'Female' : 'Male';
      final fileName = '$filePrefix $imageNumberStr.png';
      final filePath = '$genderFolder/$randomTheme/$fileName';
      
      debugPrint('Fetching character image: $filePath');
      
      // Download the image from Supabase storage - using 'themes' bucket
      final response = await client.storage
          .from('themes')
          .download(filePath);
      
      debugPrint('Character image downloaded successfully: ${response.length} bytes');
      return response;
      
    } on Exception catch (e) {
      debugPrint('Error fetching character image: $e');
      
      // Try alternative approach with direct URL
      try {
        final themes = [
          'sustainability_champions',
          'space_explorer',
          'cyberpunk_future',
          'futuristic_workspace',
          'extreme_sports',
          'fantasy_kingdom',
        ];
        
        final random = Random();
        final randomTheme = themes[random.nextInt(themes.length)];
        final imageNumber = random.nextInt(7) + 1;
        final imageNumberStr = imageNumber.toString().padLeft(2, '0');
        final genderFolder = gender.toLowerCase();
        final filePrefix = gender == 'female' ? 'Female' : 'Male';
        final fileName = '$filePrefix $imageNumberStr.png';
        final filePath = '$genderFolder/$randomTheme/$fileName';
        
        // Get public URL from 'themes' bucket
        final publicUrl = client.storage
            .from('themes')
            .getPublicUrl(filePath);
        
        debugPrint('Trying public URL: $publicUrl');
        
        // Download using HTTP
        final response = await http.get(Uri.parse(publicUrl));
        if (response.statusCode == 200) {
          debugPrint('Character image downloaded via HTTP: ${response.bodyBytes.length} bytes');
          return response.bodyBytes;
        }
      } on Exception catch (e2) {
        debugPrint('Alternative download also failed: $e2');
      }
      
      return null;
    }
  }
  
  /// Upload an image to Supabase storage
  static Future<String?> uploadImage(Uint8List imageBytes, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';
      final filePath = '$folder/$fileName';
      
      await client.storage
          .from('photobooth-images')
          .uploadBinary(filePath, imageBytes);
      
      final publicUrl = client.storage
          .from('photobooth-images')
          .getPublicUrl(filePath);
      
      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
      
    } on Exception catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}