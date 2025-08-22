import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/screens/output_screen.dart';
import 'package:flutter/material.dart';

class ProcessingScreen extends StatefulWidget {
  final Future<String?> Function() onProcess;

  const ProcessingScreen({super.key, required this.onProcess});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _statusMessage = 'Initializing...';
  bool _isProcessing = true;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    try {
      // Update status messages as processing happens
      setState(() {
        _statusMessage = 'Uploading your photo...';
        _progress = 0.2;
      });

      // Start the actual processing
      final result = await widget.onProcess();

      if (mounted) {
        if (result != null) {
          // Navigate to output screen and remove all previous screens
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  OutputScreen(imageUrl: result, imageBytes: null),
            ),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        } else {
          setState(() {
            _isProcessing = false;
            _statusMessage = 'Processing failed. Please try again.';
          });

          // Navigate back after showing error
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Error: ${e.toString()}';
        });

        // Navigate back after showing error
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
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
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated loading indicator
                    if (_isProcessing) ...[
                      const SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          strokeWidth: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0B7C84),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],

                    // Status message
                    Text(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: AppColors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    // Progress indicator
                    if (_isProcessing) ...[
                      SizedBox(
                        width: 400,
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                          backgroundColor: AppColors.white.withValues(
                            alpha: 0.2,
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0B7C84),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Please wait while we create your AI transformation...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    // Error state
                    if (!_isProcessing &&
                        _statusMessage.contains('failed')) ...[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
