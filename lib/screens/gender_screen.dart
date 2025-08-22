import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/face_capture_screen.dart';
import 'package:dell_photobooth_2025/screens/transformation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 93, top: 104, right: 93),
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
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset("assets/images/dell-logo.png", width: 192),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Select your\ngender",
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 83),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          debugPrint('Male gender selected');
                          final userModel = context.read<UserSelectionModel>();
                          userModel.setGender('male');
                          
                          // Check category to determine next screen
                          final category = userModel.category;
                          debugPrint('Category: $category');
                          
                          if (category == 'linkedin') {
                            debugPrint('Navigating to FaceCaptureScreen...');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaceCaptureScreen(),
                              ),
                            );
                          } else {
                            debugPrint('Navigating to TransformationScreen...');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransformationScreen(),
                              ),
                            );
                          }
                        },
                        child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.zero,
                          color: Color(0xFF0B7C84),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/icons/male.png",
                              width: 123,
                              height: 123,
                            ),
                            const SizedBox(height: 60),
                            const Text(
                              "Male",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 18,
                              width: 122,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        debugPrint('Female gender selected');
                        final userModel = context.read<UserSelectionModel>();
                        userModel.setGender('female');
                        
                        // Check category to determine next screen
                        final category = userModel.category;
                        debugPrint('Category: $category');
                        
                        if (category == 'linkedin') {
                          debugPrint('Navigating to FaceCaptureScreen...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaceCaptureScreen(),
                            ),
                          );
                        } else {
                          debugPrint('Navigating to TransformationScreen...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TransformationScreen(),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.zero,
                          color: Color(0xFF0B7C84),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/icons/female.png",
                              width: 123,
                              height: 123,
                            ),
                            const SizedBox(height: 60),
                            const Text(
                              "Female",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 18,
                              width: 122,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

                const SizedBox(height: 360),

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
          ],
        ),
      ),
    );
  }
}
