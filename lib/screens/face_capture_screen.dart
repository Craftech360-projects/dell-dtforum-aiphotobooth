import 'dart:async';
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
// import 'package:dell_photobooth_2025/config/app_config.dart'; // Commented out - not needed with Python backend
import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/processing_screen.dart';
import 'package:dell_photobooth_2025/services/hand_detection_service.dart';
import 'package:dell_photobooth_2025/services/linkedin_processing_service.dart';
// import 'package:dell_photobooth_2025/services/runpod_service.dart'; // Commented out - using Python backend
import 'package:dell_photobooth_2025/services/python_backend_service.dart';
import 'package:dell_photobooth_2025/services/supabase_service.dart';
// import 'package:dell_photobooth_2025/workflow/workflow.dart'; // Commented out - not needed with Python backend
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
  bool _isProcessing = false; // Add flag to prevent re-processing

  StreamSubscription<bool>? _palmDetectionSubscription;
  HandDetectionService? _jsHandDetection;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeHandDetection();
  }

  Future<void> _initializeHandDetection() async {
    // Always use JavaScript-based detection for both local and production
    debugPrint('Initializing JavaScript-based palm detection');

    try {
      _jsHandDetection = HandDetectionService();
      await _jsHandDetection!.initialize();

      // Listen for palm detection from JavaScript
      _palmDetectionSubscription = _jsHandDetection!.palmDetectionStream.listen(
        (detected) {
          if (detected && !_isCapturing && _countdown == 0) {
            _startPalmCapture();
          }
        },
      );

      debugPrint('JavaScript hand detection initialized successfully');

      // Start processing video frames after camera is initialized
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        _startJSFrameProcessing();
      }

      // Note: JavaScript detection works with the camera preview directly
      // The hand_detector.js will process frames from the video element
    } on Exception catch (e) {
      debugPrint('Failed to initialize JavaScript hand detection: $e');
      // Palm detection won't work, but manual capture button is still available
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
          await _initializeHandDetection();
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

  void _startJSFrameProcessing() {
    // For JavaScript-based detection, we need to connect the video element
    // The JavaScript handDetector will process frames directly from the camera preview
    debugPrint('Starting JavaScript frame processing...');

    // Wait a bit for the video element to be rendered in the DOM
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // Get the video element from the DOM
        final videoElements = html.document.getElementsByTagName('video');
        if (videoElements.isNotEmpty) {
          final videoElement = videoElements[0] as html.VideoElement;
          _jsHandDetection?.startProcessing(videoElement);
          debugPrint('Started JavaScript frame processing with video element');
        } else {
          debugPrint('No video element found in DOM, retrying...');
          // Retry after another delay
          Future.delayed(const Duration(milliseconds: 500), () {
            final retryElements = html.document.getElementsByTagName('video');
            if (retryElements.isNotEmpty) {
              final videoElement = retryElements[0] as html.VideoElement;
              _jsHandDetection?.startProcessing(videoElement);
              debugPrint('Started JavaScript frame processing on retry');
            }
          });
        }
      } on Exception catch (e) {
        debugPrint('Error starting JavaScript frame processing: $e');
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

  // void _startManualCapture() {
  //   setState(() {
  //     _captureMode = 'manual';
  //     _countdown = 3;
  //   });

  //   _countdownTimer?.cancel();
  //   _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (mounted) {
  //       setState(() {
  //         _countdown--;
  //       });

  //       if (_countdown <= 0) {
  //         timer.cancel();
  //         _capturePhoto();
  //       }
  //     }
  //   });
  // }

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

        // Directly start processing without showing preview
        if (mounted) {
          await _navigateToResults();
        }
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

  Future<void> _navigateToResults() async {
    // Prevent re-processing if already processing
    if (_isProcessing) {
      debugPrint('Already processing, skipping...');
      return;
    }

    // Store references early to avoid accessing context after disposal
    final userModel = context.read<UserSelectionModel>();
    final selections = userModel.toMap();
    debugPrint('User selections: $selections');

    setState(() {
      _isProcessing = true;
    });

    // Check if this is LinkedIn mode
    final isLinkedIn = userModel.category == 'linkedin';

    // Stop hand detection before navigating
    _jsHandDetection?.stopProcessing();

    // Navigate to processing screen with appropriate processor
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            onProcess: isLinkedIn ? _processLinkedIn : _processWithRunpod,
          ),
        ),
      );

      // Reset processing flag and restart hand detection when returning from processing screen
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Restart hand detection
        _jsHandDetection?.startProcessing(
          html.document.getElementsByTagName('video')[0] as html.VideoElement,
        );
      }
    }
  }

  // Modified to use Python backend instead of Runpod
  Future<String?> _processWithRunpod() async {
    // Store the model reference early to avoid accessing context after disposal
    final userModel = context.read<UserSelectionModel>();
    
    try {
      final capturedImage = userModel.capturedImage;

      if (capturedImage == null) {
        debugPrint('No captured image available');
        return null;
      }

      // NEW IMPLEMENTATION - Using Python backend
      // Step 1: Get user details
      final name = userModel.userName ?? 'Guest';
      final email = userModel.userEmail ?? 'guest@example.com';
      final gender = userModel.gender ?? 'male';
      
      debugPrint('Processing with Python backend...');
      debugPrint('User: $name, Email: $email, Gender: $gender');
      
      // Step 2: Select a random character image based on transformation type
      final transformationType = 
          userModel.transformationOption ?? 
          userModel.transformationType ?? 
          'AI Transformation';
      
      final themeName = _getThemeNameFromTransformation(transformationType);
      debugPrint('Selected theme: $themeName');
      
      // Get a random character image URL from Supabase
      final characterImageUrl = await _getRandomCharacterImageUrl(
        gender: gender,
        themeName: themeName,
      );
      
      if (characterImageUrl == null) {
        debugPrint('Failed to get character image');
        return null;
      }
      
      debugPrint('Character image URL: $characterImageUrl');
      
      // Step 3: Fetch the target image as bytes
      final targetImageBytes = await PythonBackendService.fetchImageAsBytes(characterImageUrl);
      
      // Step 4: Send both images to Python backend for face swap
      // Note: In the Python backend, sourceImage is the face to swap FROM (character)
      // and targetImage is where to place the face (user's photo)
      debugPrint('Sending images to Python backend for face swap...');
      final swappedImageBytes = await PythonBackendService.swapFaces(
        sourceImage: targetImageBytes,  // Character image (face source)
        targetImage: capturedImage,      // User's photo (face destination)
        name: name,
        email: email,
      );
      
      if (swappedImageBytes == null) {
        debugPrint('Face swap failed');
        return null;
      }
      
      // Step 5: Upload the swapped image to Supabase
      debugPrint('Uploading swapped image to Supabase...');
      final swappedImageUrl = await SupabaseService().uploadImageBytes(
        swappedImageBytes,
        null,
        bucket: 'outputimages',
        prefix: 'swapped_',
      );
      
      if (swappedImageUrl == null) {
        debugPrint('Failed to upload swapped image');
        return null;
      }
      
      debugPrint('Swapped image uploaded: $swappedImageUrl');
      
      // Step 6: Store the result in the database
      final uniqueId = const Uuid().v4();
      
      // Upload the source image first
      final sourceImageUrl = await SupabaseService().uploadImageBytes(
        capturedImage,
        null,
        bucket: 'outputimages',
        prefix: 'source_',
      );
      
      // Store in the database - using correct column name "output" for the result image
      await SupabaseService.client.from('event_output_images').insert({
        'unique_id': uniqueId,
        'name': name,
        'email': email,
        'gender': gender,
        'image_url': sourceImageUrl,  // Source image
        'characterimage': characterImageUrl,  // Character/target image
        'output': swappedImageUrl,  // Result image in "output" column
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Stored result with unique_id: $uniqueId');
      
      // Store the processed image URL in the model
      userModel.setProcessedImageUrl(swappedImageUrl);
      
      return swappedImageUrl;
    } on Exception catch (e) {
      debugPrint('Error in Runpod workflow processing: $e');
      return null;
    }
  }

  Future<String?> _processLinkedIn() async {
    // Store the model reference early to avoid accessing context after disposal
    final userModel = context.read<UserSelectionModel>();
    
    try {
      final capturedImage = userModel.capturedImage;

      if (capturedImage == null) {
        debugPrint('No captured image available');
        return null;
      }

      debugPrint('Processing LinkedIn professional headshot...');

      // Process with LinkedIn service (only background removal with white background)
      final processedImageUrl =
          await LinkedInProcessingService.processLinkedInPhoto(
            imageBytes: capturedImage,
            backgroundType: 'white', // Clean white background
            enhanceSkin: false, // No skin smoothing
            autoEnhance: false, // No enhancements
          );

      if (processedImageUrl != null) {
        debugPrint('LinkedIn photo processed successfully: $processedImageUrl');
        // Store the processed image URL in the model
        userModel.setProcessedImageUrl(processedImageUrl);
        return processedImageUrl;
      } else {
        debugPrint('Failed to process LinkedIn photo');
        return null;
      }
    } on Exception catch (e) {
      debugPrint('Error in LinkedIn processing: $e');
      return null;
    }
  }

  Future<String?> _getRandomCharacterImageUrl({
    required String gender,
    required String themeName,
  }) async {
    try {
      final themeFolderName = themeName.toLowerCase().replaceAll(' ', '_');
      final genderFolder = gender.toLowerCase();
      
      // Images are named like "Male 01.png", "Female 02.png", etc.
      final genderPrefix = gender.toLowerCase() == 'male' ? 'Male' : 'Female';
      
      // Select a random number from 1 to 7 (7 images per theme)
      final random = Random();
      final randomNumber = random.nextInt(7) + 1;
      final imageNumber = randomNumber.toString().padLeft(2, '0');
      final imageName = '$genderPrefix $imageNumber.png';

      final fullPathInBucket = '$genderFolder/$themeFolderName/$imageName';

      debugPrint('Getting character image from Supabase path: $fullPathInBucket');

      // Get the public URL of the random character image
      final publicUrl = SupabaseService.client.storage
          .from('themes')
          .getPublicUrl(fullPathInBucket);

      debugPrint('Character image URL: $publicUrl');
      
      return publicUrl;
    } on Exception catch (e) {
      debugPrint('Error getting character image URL: $e');
      return null;
    }
  }

  String _getThemeNameFromTransformation(String transformationType) {
    // Map transformation types to theme folder names in Supabase
    // These must match exactly with the folder names in the themes bucket
    // Clean up the transformation type first (remove extra spaces, normalize)
    final cleanedType = transformationType.trim();

    final Map<String, String> transformationToTheme = {
      // From TransformationScreen options (with spaces from \n replacement)
      'Sustainability Champions': 'sustainability_champions',
      'Futuristic Workspace': 'futuristic_workspace',
      'Cyberpunk Future': 'cyberpunk_future',
      'Space Explorer': 'space_explorer',
      'Extreme Sports': 'extreme_sports',
      'Fantasy Kingdom': 'fantasy_kingdom',
      // Section names (in case they get passed)
      'Professional Edge': 'futuristic_workspace',
      'Futuristic Vision': 'cyberpunk_future',
      'Playful Fun': 'extreme_sports',
      // Legacy/fallback mappings
      'AI Transformation': 'futuristic_workspace',
    };

    debugPrint(
      'Mapping transformation "$cleanedType" to theme: ${transformationToTheme[cleanedType]}',
    );

    // If no exact match found, try to find a partial match
    String? matchedTheme = transformationToTheme[cleanedType];

    if (matchedTheme == null) {
      // Try case-insensitive partial matching
      final lowerType = cleanedType.toLowerCase();

      if (lowerType.contains('sustainability')) {
        matchedTheme = 'sustainability_champions';
      } else if (lowerType.contains('futuristic') ||
          lowerType.contains('workspace')) {
        matchedTheme = 'futuristic_workspace';
      } else if (lowerType.contains('cyberpunk')) {
        matchedTheme = 'cyberpunk_future';
      } else if (lowerType.contains('space')) {
        matchedTheme = 'space_explorer';
      } else if (lowerType.contains('extreme') ||
          lowerType.contains('sports')) {
        matchedTheme = 'extreme_sports';
      } else if (lowerType.contains('fantasy')) {
        matchedTheme = 'fantasy_kingdom';
      }
    }

    debugPrint(
      'Final matched theme: ${matchedTheme ?? "futuristic_workspace (fallback)"}',
    );

    return matchedTheme ?? 'futuristic_workspace';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _palmDetectionSubscription?.cancel();
    _jsHandDetection?.stopProcessing();
    _jsHandDetection?.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Snap your shot",
                    style: TextStyle(
                      fontSize: 76,
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                      color: AppColors.white,
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
                                              color: AppColors.white,
                                            ),
                                          ),
                                          if (_captureMode == 'palm')
                                            const Text(
                                              '✋ Palm Detected!',
                                              style: TextStyle(
                                                fontSize: 24,
                                                color: AppColors.white,
                                              ),
                                            ),
                                        ],
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

                  const SizedBox(height: 40),

                  // Instructions
                  const Text(
                    "Show your open palm\nto capture photo",
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w300,
                      color: AppColors.white,
                      height: 1.1,
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
