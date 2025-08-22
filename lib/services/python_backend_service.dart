import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PythonBackendService {
  // Use 127.0.0.1 instead of localhost for better browser compatibility
  static const String _baseUrl = 'http://127.0.0.1:8000';
  
  static Future<Uint8List?> swapFaces({
    required Uint8List sourceImage,
    required Uint8List targetImage,
    required String name,
    required String email,
  }) async {
    try {
      debugPrint('Starting face swap with Python backend...');
      debugPrint('Name: $name, Email: $email');
      
      // Create multipart request
      final uri = Uri.parse('$_baseUrl/api/swap-face/');
      final request = http.MultipartRequest('POST', uri);
      
      // Add image files
      request.files.add(
        http.MultipartFile.fromBytes(
          'sourceImage',
          sourceImage,
          filename: 'source.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      request.files.add(
        http.MultipartFile.fromBytes(
          'targetImage',
          targetImage,
          filename: 'target.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      
      // Add form fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      
      debugPrint('Sending request to Python backend...');
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        debugPrint('Face swap successful!');
        // Return the swapped image as bytes
        return response.bodyBytes;
      } else {
        debugPrint('Face swap failed. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        // Try to parse error message
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['detail'] ?? 'Face swap API call failed';
          throw Exception(errorMessage);
        } on Exception {
          throw Exception('Face swap failed with status ${response.statusCode}');
        }
      }
    } on Exception catch (e) {
      debugPrint('Error in face swap: $e');
      rethrow;
    }
  }
  
  // Helper method to fetch a target image from URL and convert to bytes
  static Future<Uint8List> fetchImageAsBytes(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to fetch image from $imageUrl');
      }
    } on Exception catch (e) {
      debugPrint('Error fetching image: $e');
      rethrow;
    }
  }
}