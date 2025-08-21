import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';

class OutputScreen extends StatefulWidget {
  final String imageUrl;
  final Uint8List? imageBytes;

  const OutputScreen({
    super.key,
    required this.imageUrl,
    this.imageBytes,
  });

  @override
  State<OutputScreen> createState() => _OutputScreenState();
}

class _OutputScreenState extends State<OutputScreen> {
  bool _isLoading = false;
  late Stream<int> _countdownStream;

  @override
  void initState() {
    super.initState();
    _countdownStream = _createCountdownStream();
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
              child: Image.asset(
                "assets/images/dell-logo.png",
                width: 192,
              ),
            ),

            // Main Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    "Here's your",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "new look.",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w200,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Image Display
                  Container(
                    width: 500,
                    height: 600,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0B7C84),
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: _buildImageDisplay(),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // QR Code Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // QR Code
                      Container(
                        width: 150,
                        height: 150,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _getQrData(),
                          version: QrVersions.auto,
                          size: 130,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.L,
                        ),
                      ),
                      const SizedBox(width: 40),

                      // QR Code Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Scan the QR code to",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            "download the image",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Home Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _navigateToHome,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0A5F63),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Home",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Countdown Timer
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildCountdownTimer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getQrData() {
    // If it's a base64 image, create a simple download page URL
    if (widget.imageUrl.startsWith('data:image')) {
      // For base64 images, we can't put them in QR code
      // Instead, return a message or a placeholder URL
      return 'Image too large for QR code. Please use the app to download.';
    }
    // For URLs, use them directly
    return widget.imageUrl;
  }

  Widget _buildImageDisplay() {
    if (widget.imageBytes != null) {
      // Display from bytes if available
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageFromUrl();
        },
      );
    } else {
      return _buildImageFromUrl();
    }
  }

  Widget _buildImageFromUrl() {
    if (widget.imageUrl.startsWith('data:image')) {
      // Handle base64 image
      try {
        final base64String = widget.imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.white54,
              ),
            );
          },
        );
      } on Exception catch (e) {
        debugPrint('Error decoding base64 image: $e');
        return const Center(
          child: Icon(
            Icons.broken_image,
            size: 100,
            color: Colors.white54,
          ),
        );
      }
    } else {
      // Handle URL image
      return Image.network(
        widget.imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF0B7C84),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.broken_image,
              size: 100,
              color: Colors.white54,
            ),
          );
        },
      );
    }
  }

  Widget _buildCountdownTimer() {
    return StreamBuilder<int>(
      stream: _countdownStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final seconds = snapshot.data!;
        if (seconds <= 0) {
          // Auto navigate to home after countdown
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isLoading) {
              _navigateToHome();
            }
          });
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Returning to home in ${seconds}s',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        );
      },
    );
  }

  Stream<int> _createCountdownStream() async* {
    // 30 second countdown
    for (int i = 30; i >= 0; i--) {
      yield i;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  void _navigateToHome() {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    // Clear all user data from provider
    final userModel = context.read<UserSelectionModel>();
    userModel.clearAll();

    // Navigate to home and remove all previous routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (Route<dynamic> route) => false,
    );
  }
}