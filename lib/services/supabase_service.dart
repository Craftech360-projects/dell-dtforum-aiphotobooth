import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://qwcxcdcponxctenncila.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF3Y3hjZGNwb254Y3Rlbm5jaWxhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU3Nzk2OTYsImV4cCI6MjA3MTM1NTY5Nn0.CW24DqG4MyD0XzNxflLSXOreHPQ7zHE5AuLV0y0iY3A';

  static late SupabaseClient _client;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

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
      final response = await client.storage.from('themes').download(filePath);

      debugPrint(
        'Character image downloaded successfully: ${response.length} bytes',
      );
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
        final publicUrl = client.storage.from('themes').getPublicUrl(filePath);

        debugPrint('Trying public URL: $publicUrl');

        // Download using HTTP
        final response = await http.get(Uri.parse(publicUrl));
        if (response.statusCode == 200) {
          debugPrint(
            'Character image downloaded via HTTP: ${response.bodyBytes.length} bytes',
          );
          return response.bodyBytes;
        }
      } on Exception catch (e2) {
        debugPrint('Alternative download also failed: $e2');
      }

      return null;
    }
  }

  /// Upload an image to Supabase storage
  static Future<String?> uploadImage(
    Uint8List imageBytes,
    String folder,
  ) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}.jpg';
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

  /// Store participant details in the event_output_images table
  Future<String?> storeParticipantDetails({
    required String name,
    required String email,
    required String gender,
    required String imageUrl,
  }) async {
    if (!_initialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      // Generate a unique ID
      final uniqueId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

      // Insert the participant details into the table
      await _client.from('event_output_images').insert({
        'unique_id': uniqueId,
        'name': name,
        'email': email,
        'gender': gender,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Participant details stored with unique_id: $uniqueId');
      return uniqueId;
    } on Exception catch (e) {
      debugPrint('Error storing participant details: $e');
      return null;
    }
  }

  /// NEW FUNCTIONS COPIED FROM PREVIOUS PROJECT

  // Upload face image to Supabase storage
  Future<String?> uploadImageBytes(
    Uint8List imageBytes,
    String? userId, {
    String bucket = 'outputimages',
    String prefix = 'face_',
    String extension = '.jpg',
  }) async {
    if (!_initialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final fileName =
          '$prefix${userId ?? DateTime.now().millisecondsSinceEpoch.toString()}_${DateTime.now().millisecondsSinceEpoch}$extension';

      await _client.storage
          .from(bucket)
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final imageUrl = _client.storage.from(bucket).getPublicUrl(fileName);
      return imageUrl;
    } on StorageException catch (e) {
      // debugPrint(
      //     'Storage Exception uploading image: ${e.message}, Status: ${e.statusCode}');
      if (e.statusCode == 403 &&
          e.message.contains('row-level security policy')) {
        debugPrint(
          'This is a Row Level Security (RLS) policy error. Check your Supabase bucket permissions.',
        );
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadUserFaceImageFromPath(String imagePath) async {
    try {
      // For web, imagePath is a blob URL or data URL from camera
      // We need to fetch the data from this URL
      final response = await http.get(Uri.parse(imagePath));
      if (response.statusCode == 200) {
        final result = await uploadImageBytes(
          response.bodyBytes,
          null,
          bucket: 'inputimages',
          prefix: 'face_',
        );
        return result;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error uploading user face image: $e');
      return null;
    }
  }

  /// NEW: Selects a random character image from Supabase and updates the table.
  Future<void> selectAndUpdateRandomCharacterImage({
    required String uniqueId,
    required String gender,
    required String themeName,
  }) async {
    if (!_initialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final themeFolderName = themeName.toLowerCase().replaceAll(' ', '_');
      final genderFolder = gender.toLowerCase();
      
      // Images are named like "Male 01.png", "Female 02.png", etc.
      final genderPrefix = gender.toLowerCase() == 'male' ? 'Male' : 'Female';
      
      // Select a random number from 1 to 7 (7 images per theme)
      final randomNumber = Random().nextInt(7) + 1;
      final imageNumber = randomNumber.toString().padLeft(2, '0'); // Ensures "01", "02", etc.
      final imageName = '$genderPrefix $imageNumber.png'; // Note the space between prefix and number

      final fullPathInBucket = '$genderFolder/$themeFolderName/$imageName';

      debugPrint(
          'Selecting character image from Supabase path: $fullPathInBucket');

      // Get the public URL of the random character image
      final publicUrl = _client.storage
          .from('themes')
          .getPublicUrl(fullPathInBucket);

      debugPrint('Character image URL: $publicUrl');

      // Update the 'characterimage' column in the table for the user's row
      await _client
          .from('event_output_images')
          .update({'characterimage': publicUrl})
          .eq('unique_id', uniqueId);
      
      debugPrint(
          'Successfully updated characterimage for unique_id: $uniqueId');

      // debugPrint(
      //     'Successfully updated characterimage for unique_id: $uniqueId');
    } on Exception catch (e) {
      debugPrint('Error updating character image in Supabase: $e');
      rethrow;
    }
  }

  Future<String?> getLatestOutputImage(
    String participantId, {
    DateTime? afterTime,
  }) async {
    if (!_initialized) {
      throw Exception('Supabase not initialized');
    }

    try {
      final response = await _client
          .from('event_output_images')
          .select('output')
          .eq('unique_id', participantId)
          .single();

      if (response.isNotEmpty && response['output'] != null) {
        return response['output'] as String;
      }

      return null;
    } on Exception catch (e) {
      debugPrint('Error getting latest output image: $e');
      return null;
    }
  }
}
