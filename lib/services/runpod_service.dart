import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RunPodService {
  static Future<Map<String, dynamic>> triggerRunPodWorkflow({
    required Map<String, dynamic> workflow,
    required String apiUrl,
    required String apiKey,
  }) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // The payload structure requires the workflow to be nested under "input" and "workflow" keys.
    final body = jsonEncode({
      'input': {'workflow': workflow}
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        debugPrint('RunPod response: $responseBody');
        // Return a success status and the job ID from RunPod.
        return {
          'status': 'success',
          'message': 'Workflow sent to RunPod successfully.',
          'job_id': responseBody['id'],
        };
      } else {
        // Handle non-200 responses
        debugPrint(
            'Error sending workflow to RunPod. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to send workflow. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Exception while sending workflow to RunPod: $e');
      rethrow;
    }
  }
}