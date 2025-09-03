import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js.dart';

@JS('window.open')
external void windowOpen(String url, String target);

@JS('document.createElement')
external dynamic createElement(String tagName);

class DownloadPage extends StatelessWidget {
  final String imageUrl;

  const DownloadPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.white,
        child: Column(
          children: [
            // Header with Dell Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  "assets/images/dell-logo.png",
                  height: 60,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'DELL',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Your AI Photobooth Image',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Image Display
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxWidth: 600,
                          maxHeight: 800,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 400,
                                height: 600,
                                color: AppColors.lightGrey2,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: const Color(0xFF0B7C84),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 400,
                                height: 600,
                                color: AppColors.lightGrey2,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 80,
                                      color: AppColors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Image could not be loaded',
                                      style: TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Download Button
                    ElevatedButton.icon(
                      onPressed: () => _downloadImage(),
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Download Image',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B7C84),
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Instructions
                    const Text(
                      'Click the button above to save your AI-generated photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                '© Dell Technologies - AI Photobooth 2025',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadImage() {
    if (kIsWeb) {
      try {
        // For web, try to trigger download by opening in new tab
        windowOpen(imageUrl, '_blank');
      } on Exception catch (e) {
        debugPrint('Error downloading image: $e');
        // Fallback: just open the URL
        windowOpen(imageUrl, '_blank');
      }
    } else {
      // For non-web platforms, this shouldn't be called
      debugPrint('Download not supported on this platform');
    }
  }
}