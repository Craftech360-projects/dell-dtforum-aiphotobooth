import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceSwapService {
  static Future<Map<String, dynamic>> sendFaceSwapRequest({
    required String sourceImageUrl,
    required String targetImageUrl,
    required String uniqueId,
    required String apiUrl,
    required String apiKey,
  }) async {
    try {
      debugPrint('Sending face swap request for unique_id: $uniqueId');
      debugPrint('Source image URL: $sourceImageUrl');
      debugPrint('Target image URL: $targetImageUrl');
      
      // Send URLs directly instead of base64 to avoid size limits
      // The handler will download the images
      final payload = {
        'input': {
          'source_image_url': sourceImageUrl,
          'target_image_url': targetImageUrl,
          'unique_id': uniqueId,
        }
      };
      
      // Send request to RunPod
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      
      // Ensure URL is properly formatted
      final cleanApiUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
      final runUrl = '$cleanApiUrl/run';
      debugPrint('Sending request to: $runUrl');
      
      final response = await http.post(
        Uri.parse(runUrl),
        headers: headers,
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('RunPod job started: ${responseData['id']}');
        
        return {
          'status': 'success',
          'job_id': responseData['id'],
          'message': 'Face swap job started successfully',
        };
      } else {
        debugPrint('RunPod API error - Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to start face swap job: ${response.statusCode} - ${response.body}');
      }
    } on Exception catch (e) {
      debugPrint('Error in face swap request: $e');
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
  
  static Future<bool> checkJobStatus({
    required String jobId,
    required String apiUrl,
    required String apiKey,
  }) async {
    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
      };
      
      // Ensure URL is properly formatted
      final cleanApiUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;
      final statusUrl = '$cleanApiUrl/status/$jobId';
      
      final response = await http.get(
        Uri.parse(statusUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];
        
        debugPrint('Job $jobId status: $status');
        
        if (status == 'COMPLETED') {
          // The handler already uploads to Supabase, so we just need to know it's done
          return true;
        } else if (status == 'FAILED') {
          debugPrint('Job failed: ${data['output']}');
          throw Exception('Face swap job failed');
        }
      }
      
      return false; // Still processing
    } on Exception catch (e) {
      debugPrint('Error checking job status: $e');
      return false;
    }
  }
}