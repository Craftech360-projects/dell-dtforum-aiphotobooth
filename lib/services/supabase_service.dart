import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://ozkbnimjuhaweigscdby.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im96a2JuaW1qdWhhd2VpZ3NjZGJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEyODc4NDYsImV4cCI6MjA2Njg2Mzg0Nn0.C4OgN-JEBX9ZqnRDXU9XmGnED2pCh3kI82GrHPXtq8U';

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

      // Select a random number from 1 to 5 (5 images per theme)
      final randomNumber = Random().nextInt(5) + 1;
      final imageNumber = randomNumber.toString().padLeft(
        2,
        '0',
      ); // Ensures "01", "02", etc.
      final imageName = '$genderPrefix $imageNumber.png';

      final fullPathInBucket = '$genderFolder/$themeFolderName/$imageName';

      debugPrint(
        'Selecting character image from Supabase path: $fullPathInBucket',
      );

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
        'Successfully updated characterimage for unique_id: $uniqueId',
      );

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