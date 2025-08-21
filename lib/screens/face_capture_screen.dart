import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/output_screen.dart';
import 'package:dell_photobooth_2025/services/python_hand_detection.dart';
import 'package:dell_photobooth_2025/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  String _captureMode = 'waiting'; // 'waiting', 'palm', 'manual'
  bool _palmDetected = false;

  final PythonHandDetectionService _handDetectionService =
      PythonHandDetectionService();
  StreamSubscription<bool>? _palmDetectionSubscription;
  Timer? _frameGrabTimer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeHandDetection();
  }

  Future<void> _initializeHandDetection() async {
    // Check if Python service is running
    final isHealthy = await _handDetectionService.checkHealth();
    if (isHealthy) {
      debugPrint('Python hand detection service is running');

      // Listen for palm detection
      _palmDetectionSubscription = _handDetectionService.palmDetectionStream
          .listen((detected) {
            if (detected && !_isCapturing && _countdown == 0) {
              _startPalmCapture();
            }
          });

      // Start periodic frame capture for palm detection
      _startFrameCapture();
    } else {
      debugPrint('Python hand detection service is not running');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Palm detection service not available. Use manual capture.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use front camera if available, otherwise use the first camera
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });

          // Initialize hand detection after camera is ready
          _initializeHandDetection();
        }
      }
    } on Exception catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startFrameCapture() {
    // Capture frames periodically and send to Python service
    _frameGrabTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (!_isCapturing &&
          _countdown == 0 &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        try {
          // Take a picture for analysis
          final XFile photo = await _cameraController!.takePicture();
          final Uint8List imageBytes = await photo.readAsBytes();

          // Send to Python service for palm detection
          await _handDetectionService.detectPalm(imageBytes);
        } on Exception {
          // Silently ignore errors in frame capture for detection
        }
      }
    });
  }

  void _startPalmCapture() {
    setState(() {
      _captureMode = 'palm';
      _palmDetected = true;
      _countdown = 3;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown <= 0) {
          timer.cancel();
          _capturePhoto();
        }
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List imageBytes = await photo.readAsBytes();

      if (mounted) {
        // Store the image in the provider
        context.read<UserSelectionModel>().setCapturedImage(imageBytes);

        // Navigate to the next screen or show preview
        _showCapturedImage(imageBytes);
      }
    } on Exception catch (e) {
      debugPrint('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCapturing = false;
        _captureMode = 'waiting';
        _palmDetected = false;
      });
    }
  }

  void _showCapturedImage(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0A5F63),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Photo Captured!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    imageBytes,
                    width: 400,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _retakePhoto();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Retake',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Navigate to next screen (results/processing)
                        _navigateToResults();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _retakePhoto() {
    setState(() {
      _countdown = 0;
      _captureMode = 'waiting';
      _palmDetected = false;
    });
  }

  Future<void> _navigateToResults() async {
    final selections = context.read<UserSelectionModel>().toMap();
    debugPrint('User selections: $selections');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Processing your transformation...',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Send image to backend for processing
      final result = await _sendImageToBackend();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result != null) {
          // Navigate to output screen with processed image
          final userModel = context.read<UserSelectionModel>();
          final imageUrl = userModel.processedImageUrl ?? '';

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OutputScreen(
                imageUrl: imageUrl.isNotEmpty
                    ? imageUrl
                    : 'data:image/jpeg;base64,${base64Encode(result)}',
                imageBytes: result,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process transformation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<Uint8List?> _sendImageToBackend() async {
    try {
      final userModel = context.read<UserSelectionModel>();
      final capturedImage = userModel.capturedImage;

      if (capturedImage == null) {
        debugPrint('No captured image available');
        return null;
      }

      // Convert captured image to base64
      final base64SourceImage = base64Encode(capturedImage);

      // Fetch random character image from Supabase
      debugPrint('Fetching character image from Supabase...');
      final gender = userModel.gender ?? 'male';
      final characterImage = await SupabaseService.getRandomCharacterImage(
        gender,
      );

      if (characterImage == null) {
        debugPrint('Failed to fetch character image from Supabase');
        // Continue without face swap
        final requestData = {
          'captured_image': 'data:image/jpeg;base64,$base64SourceImage',
          'transformation_type': 'None',
          'gender': gender,
          'name': userModel.userName ?? 'Guest',
          'email': userModel.userEmail ?? 'guest@example.com',
        };

        final response = await http
            .post(
              Uri.parse('http://localhost:5555/api/process-photo'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestData),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true &&
              responseData['image_url'] != null) {
            userModel.setProcessedImageUrl(responseData['image_url']);
          }
          return response.bodyBytes;
        }
        return null;
      }

      debugPrint('Character image fetched: ${characterImage.length} bytes');

      // Convert character image to base64
      final base64TargetImage = base64Encode(characterImage);

      // Prepare request data with both images
      final requestData = {
        'source_image': 'data:image/jpeg;base64,$base64SourceImage',
        'target_image': 'data:image/png;base64,$base64TargetImage',
        'transformation_type':
            userModel.transformationType ?? 'AI Transformation',
        'gender': gender,
        'name': userModel.userName ?? 'Guest',
        'email': userModel.userEmail ?? 'guest@example.com',
      };

      // Send to backend
      final response = await http
          .post(
            Uri.parse('http://localhost:5555/api/process-photo'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('Image processed successfully');

        // Parse response to get image URL
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true &&
            responseData['image_url'] != null) {
          // Store the URL in the model
          userModel.setProcessedImageUrl(responseData['image_url']);

          // If it's a base64 image, return the bytes
          if (responseData['image_url'].startsWith('data:image')) {
            final base64String = responseData['image_url'].split(',').last;
            return base64Decode(base64String);
          }
        }

        return response.bodyBytes;
      } else {
        debugPrint('Backend error: ${response.statusCode}');
        return null;
      }
    } on Exception catch (e) {
      debugPrint('Error sending image to backend: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _frameGrabTimer?.cancel();
    _palmDetectionSubscription?.cancel();
    _handDetectionService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background-two.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dell Logo
            Positioned(
              left: 93,
              top: 104,
              child: Image.asset("assets/images/dell-logo.png", width: 192),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Snap your shot",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Camera View Container
                  Container(
                    width: 790,
                    height: 1085,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _palmDetected
                            ? Colors.green
                            : const Color(0xFF0B7C84),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _isInitialized && _cameraController != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(_cameraController!),

                                // Countdown overlay
                                if (_countdown > 0)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _countdown.toString(),
                                            style: const TextStyle(
                                              fontSize: 120,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          if (_captureMode == 'palm')
                                            const Text(
                                              '✋ Palm Detected!',
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: Colors.white,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Status indicator
                                Positioned(
                                  top: 20,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _captureMode == 'palm'
                                          ? '✋ Capturing...'
                                          : _captureMode == 'manual'
                                          ? '📸 Manual Capture'
                                          : '✋ Show your palm or click capture',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0B7C84),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Instructions
                  const Text(
                    "Show your open palm to the camera to trigger capture",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Back Button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 36,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/icons/arrow-back.png", width: 40),
                        const SizedBox(width: 12),
                        const Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
