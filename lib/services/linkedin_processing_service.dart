import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dell_photobooth_2025/services/supabase_service.dart';
import 'package:dell_photobooth_2025/services/environment_service.dart';

class LinkedInProcessingService {
  /// Process image for LinkedIn-style professional headshot
  static Future<String?> processLinkedInPhoto({
    required Uint8List imageBytes,
    String backgroundType = 'white',
    bool enhanceSkin = false,
    bool autoEnhance = false,
  }) async {
    try {
      debugPrint('Starting LinkedIn photo processing...');
      
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Prepare request body
      final requestBody = jsonEncode({
        'image': 'data:image/jpeg;base64,$base64Image',
        'background_type': backgroundType,
        'enhance_skin': enhanceSkin,
        'auto_enhance': autoEnhance,
      });
      
      // Send to Python service for processing
      final response = await http.post(
        Uri.parse(EnvironmentService.getEndpoint('/process_linkedin')),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('LinkedIn photo processed successfully');
          
          // Extract base64 image from response
          String processedImageBase64 = responseData['image'];
          if (processedImageBase64.contains(',')) {
            processedImageBase64 = processedImageBase64.split(',')[1];
          }
          
          // Convert base64 to bytes
          final processedImageBytes = base64Decode(processedImageBase64);
          
          // Upload to Supabase
          final imageUrl = await _uploadToSupabase(processedImageBytes);
          
          return imageUrl;
        } else {
          debugPrint('Processing failed: ${responseData['error']}');
          return null;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return null;
      }
    } on Exception catch (e) {
      debugPrint('Error processing LinkedIn photo: $e');
      return null;
    }
  }
  
  /// Quick enhancement without background removal
  static Future<String?> quickEnhance({
    required Uint8List imageBytes,
  }) async {
    try {
      debugPrint('Starting quick enhancement...');
      
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      // Prepare request body
      final requestBody = jsonEncode({
        'image': 'data:image/jpeg;base64,$base64Image',
      });
      
      // Send to Python service for processing
      final response = await http.post(
        Uri.parse(EnvironmentService.getEndpoint('/quick_enhance')),
        headers: {
          'Content-Type': 'application/json',
        },
        body: requestBody,
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          debugPrint('Quick enhancement successful');
          
          // Extract base64 image from response
          String enhancedImageBase64 = responseData['image'];
          if (enhancedImageBase64.contains(',')) {
            enhancedImageBase64 = enhancedImageBase64.split(',')[1];
          }
          
          // Convert base64 to bytes
          final enhancedImageBytes = base64Decode(enhancedImageBase64);
          
          // Upload to Supabase
          final imageUrl = await _uploadToSupabase(enhancedImageBytes);
          
          return imageUrl;
        } else {
          debugPrint('Enhancement failed: ${responseData['error']}');
          return null;
        }
      } else {
        debugPrint('HTTP error: ${response.statusCode}');
        return null;
      }
    } on Exception catch (e) {
      debugPrint('Error in quick enhance: $e');
      return null;
    }
  }
  
  /// Upload processed image to Supabase
  static Future<String?> _uploadToSupabase(Uint8List imageBytes) async {
    try {
      debugPrint('Uploading LinkedIn photo to Supabase...');
      
      // Upload to Supabase 'linkedin' bucket or 'outputimages' bucket
      final imageUrl = await SupabaseService().uploadImageBytes(
        imageBytes,
        null,
        bucket: 'outputimages',
        prefix: 'linkedin_',
        extension: '.jpg',
      );
      
      if (imageUrl != null) {
        debugPrint('LinkedIn photo uploaded successfully: $imageUrl');
      } else {
        debugPrint('Failed to upload LinkedIn photo to Supabase');
      }
      
      return imageUrl;
    } on Exception catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      return null;
    }
  }
  
  /// Check if LinkedIn processing service is available
  static Future<bool> checkServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse(EnvironmentService.getEndpoint('/health')),
      ).timeout(const Duration(seconds: 3));
      
      return response.statusCode == 200;
    } on Exception catch (e) {
      debugPrint('LinkedIn service health check failed: $e');
      return false;
    }
  }
  
  /// Get available background types
  static List<Map<String, String>> getBackgroundTypes() {
    return [
      {'value': 'white', 'label': 'Pure White'},
      {'value': 'light_gray', 'label': 'Light Gray'},
      {'value': 'gradient_gray', 'label': 'Professional Gray Gradient'},
      {'value': 'gradient_blue', 'label': 'LinkedIn Blue Gradient'},
      {'value': 'linkedin_blue', 'label': 'LinkedIn Blue Solid'},
    ];
  }
}