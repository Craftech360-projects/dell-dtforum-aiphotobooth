import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/gender_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  Widget _buildThemeOption(BuildContext context, String themeId, String title, String iconPath) {
    return GestureDetector(
      onTap: () {
        debugPrint('$themeId theme selected');
        context.read<UserSelectionModel>().setTheme(themeId);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GenderScreen(),
          ),
        ).then((_) {
          debugPrint('Returned from GenderScreen');
        });
      },
      child: Container(
        width: 280,
        height: 300,
        padding: const EdgeInsets.all(30),
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
              iconPath,
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: AppColors.white.withOpacity(0.3),
                  child: const Icon(
                    Icons.image,
                    size: 40,
                    color: AppColors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                height: 1.1,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 12,
              width: 80,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }

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
                  "Choose your\nDiwali theme",
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w300,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 50),

                // Grid of theme options
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    _buildThemeOption(
                      context,
                      'linkedin',
                      'LinkedIn\nProfessional',
                      'assets/icons/linkedin.png',
                    ),
                    _buildThemeOption(
                      context,
                      'diwali_costume',
                      'Diwali\nCostume',
                      'assets/icons/diwali-costume.png',
                    ),
                    _buildThemeOption(
                      context,
                      'diwali_celebration',
                      'Diwali\nCelebration',
                      'assets/icons/diwali-celebration.png',
                    ),
                    _buildThemeOption(
                      context,
                      'crackers',
                      'Crackers\nTheme',
                      'assets/icons/crackers.png',
                    ),
                    _buildThemeOption(
                      context,
                      'pooja',
                      'Pooja\nTheme',
                      'assets/icons/pooja.png',
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
