import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:dell_photobooth_2025/services/environment_service.dart';

class PythonHandDetectionService {
  static String get baseUrl => EnvironmentService.apiBaseUrl;
  static final PythonHandDetectionService _instance = PythonHandDetectionService._internal();
  
  factory PythonHandDetectionService() => _instance;
  PythonHandDetectionService._internal();
  
  Timer? _detectionTimer;
  StreamController<bool>? _palmDetectionController;
  bool _isProcessing = false;
  
  Stream<bool> get palmDetectionStream {
    _palmDetectionController ??= StreamController<bool>.broadcast();
    return _palmDetectionController!.stream;
  }
  
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(EnvironmentService.getEndpoint('/health')),
      ).timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      return false;
    } on Exception catch (e) {
      debugPrint('Python service health check failed: $e');
      return false;
    }
  }
  
  Future<bool> detectPalm(Uint8List imageBytes) async {
    try {
      // Convert image to base64
      final base64Image = base64Encode(imageBytes);
      
      final response = await http.post(
        Uri.parse(EnvironmentService.getEndpoint('/detect_palm')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': 'data:image/jpeg;base64,$base64Image',
        }),
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final palmDetected = data['palm_detected'] ?? false;
        
        if (palmDetected) {
          debugPrint('Palm detected by Python service: ${data['message']}');
          _palmDetectionController?.add(true);
        }
        
        return palmDetected;
      }
      return false;
    } on Exception catch (e) {
      debugPrint('Error detecting palm: $e');
      return false;
    }
  }
  
  void startContinuousDetection(Function() getImageBytes) {
    if (_isProcessing) return;
    
    _isProcessing = true;
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!_isProcessing) return;
      
      try {
        // Get current camera frame as bytes
        final imageBytes = getImageBytes() as Uint8List?;
        if (imageBytes != null) {
          await detectPalm(imageBytes);
        }
      } on Exception catch (e) {
        debugPrint('Error in continuous detection: $e');
      }
    });
  }
  
  void stopDetection() {
    _isProcessing = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;
  }
  
  Future<void> reset() async {
    try {
      await http.post(Uri.parse(EnvironmentService.getEndpoint('/reset')));
    } on Exception catch (e) {
      debugPrint('Error resetting detector: $e');
    }
  }
  
  void dispose() {
    stopDetection();
    _palmDetectionController?.close();
    _palmDetectionController = null;
  }
}