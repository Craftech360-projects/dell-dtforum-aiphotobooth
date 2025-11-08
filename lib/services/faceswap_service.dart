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
      // Send URLs directly instead of base64 to avoid size limits
      // The handler will download the images
      final payload = {
        'input': {'source_image_url': sourceImageUrl, 'target_image_url': targetImageUrl, 'unique_id': uniqueId},
      };

      // Send request to RunPod
      final headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $apiKey'};

      // Ensure URL is properly formatted
      // Remove trailing slash if present
      final cleanApiUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;

      // Only append /run if it's not already there
      final runUrl = cleanApiUrl.endsWith('/run') ? cleanApiUrl : '$cleanApiUrl/run';

      final response = await http.post(Uri.parse(runUrl), headers: headers, body: jsonEncode(payload));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {'status': 'success', 'job_id': responseData['id'], 'message': 'Face swap job started successfully'};
      } else {
        debugPrint('RunPod API error - Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to start face swap job: ${response.statusCode} - ${response.body}');
      }
    } on Exception catch (e) {
      debugPrint('Error in face swap request: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  static Future<bool> checkJobStatus({required String jobId, required String apiUrl, required String apiKey}) async {
    try {
      final headers = {'Authorization': 'Bearer $apiKey'};

      // Ensure URL is properly formatted
      // Remove trailing slash if present
      final cleanApiUrl = apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl;

      // Handle if the base URL already contains /run or other paths
      // For status endpoint, we need the base + /status/{jobId}
      final baseUrl = cleanApiUrl.replaceAll(RegExp(r'/run$'), '');
      final statusUrl = '$baseUrl/status/$jobId';

      final response = await http.get(Uri.parse(statusUrl), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

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
