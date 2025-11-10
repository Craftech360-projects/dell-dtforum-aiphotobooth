import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:dell_photobooth_2025/config/app_config.dart';
import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/processing_screen.dart';
import 'package:dell_photobooth_2025/services/faceswap_service.dart';
import 'package:dell_photobooth_2025/services/gemini_service.dart';
import 'package:dell_photobooth_2025/services/supabase_service.dart';
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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Log all available cameras for debugging
        debugPrint('Available cameras:');
        for (var i = 0; i < _cameras!.length; i++) {
          debugPrint('  [$i] ${_cameras![i].name} - ${_cameras![i].lensDirection}');
        }

        // Prioritize camera selection:
        // 1. External camera (lensDirection == external)
        // 2. Back camera (could be external on desktop)
        // 3. First available camera
        CameraDescription selectedCamera;

        // Try to find external camera first
        try {
          selectedCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.external,
          );
          debugPrint('✅ Using external camera: ${selectedCamera.name}');
        } catch (e) {
          // No external camera found, try back camera
          try {
            selectedCamera = _cameras!.firstWhere(
              (camera) => camera.lensDirection == CameraLensDirection.back,
            );
            debugPrint('✅ Using back camera: ${selectedCamera.name}');
          } catch (e) {
            // Use first available camera as fallback
            selectedCamera = _cameras!.first;
            debugPrint('✅ Using first available camera: ${selectedCamera.name}');
          }
        }

        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
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

  void _startManualCapture() {
    setState(() {
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
        context.read<UserSelectionModel>().setCapturedImage(imageBytes);
        await _navigateToResults();
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
      });
    }
  }

  Future<void> _navigateToResults() async {
    if (_isProcessing) {
      debugPrint('Already processing, skipping...');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final selections = context.read<UserSelectionModel>().toMap();
    debugPrint('User selections: $selections');

    final userModel = context.read<UserSelectionModel>();
    final isLinkedIn = userModel.category == 'linkedin';

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(
            onProcess: isLinkedIn ? _processLinkedIn : _processWithRunpod,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String?> _processWithRunpod() async {
    try {
      final userModel = context.read<UserSelectionModel>();
      final capturedImage = userModel.capturedImage;

      if (capturedImage == null) {
        debugPrint('No captured image available');
        return null;
      }

      // Crop the image to portrait aspect ratio (2:3) before processing - same as LinkedIn
      final croppedImage = _cropImageToPortrait(capturedImage);

      final userImageUrl = await SupabaseService().uploadImageBytes(
        croppedImage,
        null,
        bucket: 'outputimages',
        prefix: 'user_',
      );

      if (userImageUrl == null) {
        debugPrint('Failed to upload user image to Supabase');
        return null;
      }

      final uniqueId = const Uuid().v4();
      final name = userModel.userName ?? 'Guest';
      final email = userModel.userEmail ?? 'guest@example.com';
      final gender = userModel.gender ?? 'male';

      await SupabaseService.client.from('event_output_images').insert({
        'unique_id': uniqueId,
        'name': name,
        'email': email,
        'gender': gender,
        'image_url': userImageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      final transformationType =
          userModel.transformationOption ??
          userModel.transformationType ??
          'AI Transformation';

      final themeName = _getThemeNameFromTransformation(transformationType);

      await SupabaseService().selectAndUpdateRandomCharacterImage(
        uniqueId: uniqueId,
        gender: gender,
        themeName: themeName,
      );

      final record = await SupabaseService.client
          .from('event_output_images')
          .select('characterimage')
          .eq('unique_id', uniqueId)
          .single();

      final characterImageUrl = record['characterimage'] as String?;

      if (characterImageUrl == null) {
        debugPrint('Failed to get character image URL');
        return null;
      }

      final result = await FaceSwapService.sendFaceSwapRequest(
        sourceImageUrl: userImageUrl,
        targetImageUrl: characterImageUrl,
        uniqueId: uniqueId,
        apiUrl: AppConfig.runpodEndpointUrl,
        apiKey: AppConfig.runpodApiKey,
      );

      if (result['status'] != 'success') {
        debugPrint('Failed to start face swap job: ${result['message']}');
        return null;
      }

      final jobId = result['job_id'];
      const maxAttempts = 60;
      const pollInterval = Duration(seconds: 3);

      bool foundImage = false;

      for (int i = 0; i < maxAttempts; i++) {
        if (!mounted) {
          debugPrint('Widget no longer mounted, stopping polling');
          break;
        }

        await Future.delayed(pollInterval);

        if (jobId != null) {
          final jobComplete = await FaceSwapService.checkJobStatus(
            jobId: jobId,
            apiUrl: AppConfig.runpodEndpointUrl,
            apiKey: AppConfig.runpodApiKey,
          );

          if (!jobComplete && i < maxAttempts - 1) {
            debugPrint('Job still processing, attempt ${i + 1}/$maxAttempts');
            continue;
          }
        }

        final outputImage = await SupabaseService().getLatestOutputImage(
          uniqueId,
        );

        if (outputImage != null && outputImage.isNotEmpty) {
          debugPrint('Output image received: $outputImage');
          userModel.setProcessedImageUrl(outputImage);
          foundImage = true;
          return outputImage;
        }

        debugPrint('Polling attempt ${i + 1}/$maxAttempts');
      }

      if (!foundImage) {
        debugPrint('Timeout waiting for output image');
      }
      return null;
    } on Exception catch (e) {
      debugPrint('Error in Runpod workflow processing: $e');
      return null;
    }
  }

  Future<String?> _processLinkedIn() async {
    try {
      final userModel = context.read<UserSelectionModel>();
      final capturedImage = userModel.capturedImage;

      if (capturedImage == null) {
        debugPrint('No captured image available');
        return null;
      }

      debugPrint('🔥 Starting Gemini LinkedIn headshot generation');

      // Crop the image to portrait aspect ratio (2:3) before processing
      final croppedImage = _cropImageToPortrait(capturedImage);

      // Use Gemini service for LinkedIn professional headshot generation
      final generatedImageBytes = await GeminiService.generateLinkedInHeadshot(
        inputImageBytes: croppedImage,
      );

      if (generatedImageBytes == null) {
        debugPrint('❌ Failed to generate LinkedIn headshot with Gemini');
        return null;
      }

      debugPrint('✅ Successfully generated LinkedIn headshot with Gemini');
      debugPrint('Generated image size: ${generatedImageBytes.length} bytes');

      // Now upload the cropped user image to Supabase
      final userImageUrl = await SupabaseService().uploadImageBytes(
        croppedImage,
        null,
        bucket: 'outputimages',
        prefix: 'user_',
      );

      if (userImageUrl == null) {
        debugPrint('Failed to upload user image to Supabase');
        return null;
      }

      final uniqueId = const Uuid().v4();
      final name = userModel.userName ?? 'Guest';
      final email = userModel.userEmail ?? 'guest@example.com';
      final gender = userModel.gender ?? 'male';

      // Store user details in database
      await SupabaseService.client.from('event_output_images').insert({
        'unique_id': uniqueId,
        'name': name,
        'email': email,
        'gender': gender,
        'image_url': userImageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Upload the generated image to Supabase
      final outputImageUrl = await SupabaseService().uploadImageBytes(
        generatedImageBytes,
        uniqueId,
        bucket: 'outputimages',
        prefix: 'linkedin_',
      );

      if (outputImageUrl == null) {
        debugPrint('Failed to upload generated image to Supabase');
        return null;
      }

      // Update the database record with the output image
      await SupabaseService.client
          .from('event_output_images')
          .update({'output': outputImageUrl})
          .eq('unique_id', uniqueId);

      debugPrint('🎉 LinkedIn headshot processing completed: $outputImageUrl');

      // Set the processed image URL in the user model
      userModel.setProcessedImageUrl(outputImageUrl);

      return outputImageUrl;
    } on Exception catch (e) {
      debugPrint('❌ Error in Gemini LinkedIn processing: $e');
      return null;
    }
  }

  Uint8List _cropImageToPortrait(Uint8List imageBytes) {
    try {
      // Decode the image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('❌ Failed to decode image for cropping');
        return imageBytes;
      }

      final originalWidth = image.width;
      final originalHeight = image.height;
      
      debugPrint('📏 Original image dimensions: ${originalWidth}x$originalHeight');

      // Calculate target dimensions for 2:3 aspect ratio (width:height)
      int targetWidth;
      int targetHeight;

      // If the image is already portrait or square, maintain width and adjust height
      if (originalHeight >= originalWidth) {
        targetWidth = originalWidth;
        targetHeight = (originalWidth * 1.5).round(); // 2:3 ratio
        
        // If calculated height is larger than original, use original height and adjust width
        if (targetHeight > originalHeight) {
          targetHeight = originalHeight;
          targetWidth = (originalHeight / 1.5).round();
        }
      } else {
        // Image is landscape, so we need to make it portrait
        // Use height as the base and calculate width for portrait
        targetHeight = originalHeight;
        targetWidth = (originalHeight / 1.5).round(); // For 2:3 ratio
        
        // If calculated width is larger than original, use original width and adjust height
        if (targetWidth > originalWidth) {
          targetWidth = originalWidth;
          targetHeight = (originalWidth * 1.5).round();
        }
      }

      // Calculate crop coordinates (center crop)
      final cropX = ((originalWidth - targetWidth) / 2).round();
      final cropY = ((originalHeight - targetHeight) / 2).round();

      debugPrint('✂️ Cropping to ${targetWidth}x$targetHeight at offset ($cropX, $cropY)');

      // Crop the image
      final croppedImage = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: targetWidth,
        height: targetHeight,
      );

      // Encode back to bytes
      final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage, quality: 90));
      
      debugPrint('✅ Image cropped successfully: ${croppedBytes.length} bytes');
      return croppedBytes;
    } on Exception catch (e) {
      debugPrint('❌ Error cropping image: $e');
      return imageBytes; // Return original if cropping fails
    }
  }

  String _getThemeNameFromTransformation(String transformationType) {
    final cleanedType = transformationType.trim();

    final Map<String, String> transformationToTheme = {
      'Sustainability Champions': 'sustainability_champions',
      'Futuristic Workspace': 'futuristic_workspace',
      'Cyberpunk Future': 'cyberpunk_future',
      'Space Explorer': 'space_explorer',
      'Extreme Sports': 'extreme_sports',
      'Fantasy Kingdom': 'fantasy_kingdom',
      'Professional Edge': 'futuristic_workspace',
      'Futuristic Vision': 'cyberpunk_future',
      'Playful Fun': 'extreme_sports',
      'AI Transformation': 'futuristic_workspace',
    };

    String? matchedTheme = transformationToTheme[cleanedType];

    if (matchedTheme == null) {
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

    return matchedTheme ?? 'futuristic_workspace';
  }

  // Calculate rotation angle to make camera preview portrait
  double _getRotationAngle() {
    if (_cameraController == null) return 0;

    // Get camera preview aspect ratio
    final aspectRatio = _cameraController!.value.aspectRatio;

    // If aspect ratio > 1, camera is in landscape, rotate 90 degrees (π/2 radians)
    // If aspect ratio < 1, camera is already portrait, no rotation needed
    if (aspectRatio > 1) {
      debugPrint('📐 Camera is landscape (${aspectRatio}), rotating to portrait');
      return 1.5708; // 90 degrees in radians (π/2)
    }

    debugPrint('📐 Camera is already portrait (${aspectRatio})');
    return 0;
  }

  // Get preview width for the camera (considering rotation)
  double _getPreviewWidth() {
    if (_cameraController == null) return 100;

    final aspectRatio = _cameraController!.value.aspectRatio;

    // If landscape (will be rotated), use height as width
    if (aspectRatio > 1) {
      return _cameraController!.value.previewSize!.height;
    }

    return _cameraController!.value.previewSize!.width;
  }

  // Get preview height for the camera (considering rotation)
  double _getPreviewHeight() {
    if (_cameraController == null) return 100;

    final aspectRatio = _cameraController!.value.aspectRatio;

    // If landscape (will be rotated), use width as height
    if (aspectRatio > 1) {
      return _cameraController!.value.previewSize!.width;
    }

    return _cameraController!.value.previewSize!.height;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
            image: AssetImage("assets/images/background-one.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dell Logo
            Positioned(
              left: 93,
              top: 104,
              child: Image.asset("assets/images/dell-logo.png", width: 517),
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
                      color: AppColors.black,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Camera View Container
                  Container(
                    width: 700,
                    height: 1050,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF1E429A),
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
                                // Rotate camera preview to portrait and fill container
                                OverflowBox(
                                  maxWidth: double.infinity,
                                  maxHeight: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _getPreviewWidth() * 1.6,  // Scale 60% larger to ensure full coverage
                                      height: _getPreviewHeight() * 1.6, // Scale 60% larger to ensure full coverage
                                      child: Transform.rotate(
                                        angle: _getRotationAngle(),
                                        child: CameraPreview(_cameraController!),
                                      ),
                                    ),
                                  ),
                                ),

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
                                          const Text(
                                            'Get ready!',
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
                                color: Color(0xFF1E429A),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Capture Button
                  Container(
                    width: 700,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: ElevatedButton(
                      onPressed: _isCapturing || _countdown > 0
                          ? null
                          : _startManualCapture,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E429A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Capture Photo",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
