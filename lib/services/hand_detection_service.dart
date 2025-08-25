import 'dart:async';
import 'dart:developer';
import 'dart:html' as html;

import 'package:js/js.dart';
import 'package:js/js_util.dart' as js_util;

@JS('handDetector')
external dynamic get handDetector;

class HandDetectionService {
  static final HandDetectionService _instance =
      HandDetectionService._internal();
  factory HandDetectionService() => _instance;
  HandDetectionService._internal();

  StreamController<bool>? _palmDetectionController;
  html.VideoElement? _videoElement;
  Timer? _processTimer;
  bool _isProcessing = false;

  Stream<bool> get palmDetectionStream {
    _palmDetectionController ??= StreamController<bool>.broadcast();
    return _palmDetectionController!.stream;
  }

  Future<void> initialize() async {
    try {
      // Check if handDetector is available
      if (handDetector == null) {
        log('Hand detector not available, skipping initialization');
        return;
      }
      
      // Initialize MediaPipe hands
      js_util.callMethod(handDetector, 'init', []);

      // Listen for palm detection events from JavaScript
      html.window.addEventListener('palmDetected', (event) {
        _palmDetectionController?.add(true);
      });

      log('Hand detection service initialized');
    } on Exception catch (e) {
      log('Error initializing hand detection: $e');
      // Continue without hand detection - app can still work with button
    }
  }

  void startProcessing(html.VideoElement videoElement) {
    if (_isProcessing) return;
    
    // Skip if handDetector is not available
    if (handDetector == null) {
      log('Hand detector not available, skipping video processing');
      return;
    }

    _videoElement = videoElement;
    _isProcessing = true;

    // Process video frames every 100ms
    _processTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_videoElement != null && handDetector != null) {
        try {
          js_util.callMethod(handDetector, 'processVideoFrame', [
            _videoElement,
          ]);
        } on Exception catch (e) {
          log('Error processing video frame: $e');
          // Stop processing if errors persist
          if (e.toString().contains('abort') || e.toString().contains('failed')) {
            stopProcessing();
          }
        }
      }
    });
  }

  void stopProcessing() {
    _isProcessing = false;
    _processTimer?.cancel();
    _processTimer = null;
    _videoElement = null;
  }

  void dispose() {
    stopProcessing();
    _palmDetectionController?.close();
    _palmDetectionController = null;
  }
}
