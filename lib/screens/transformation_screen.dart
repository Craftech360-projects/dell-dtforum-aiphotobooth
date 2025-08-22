import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/face_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransformationScreen extends StatefulWidget {
  const TransformationScreen({super.key});

  @override
  State<TransformationScreen> createState() => _TransformationScreenState();
}

class _TransformationScreenState extends State<TransformationScreen> {
  String? expandedSection;

  final Map<String, List<TransformationOption>> transformationOptions = {
    'Professional Edge': [
      TransformationOption(
        title: 'Sustainability\nChampions',
        imagePath: 'assets/images/sustainability_champions_thumbnail.png',
      ),
      TransformationOption(
        title: 'Futuristic\nWorkspace',
        imagePath: 'assets/images/futuristic_workspace_thumbnail.png',
      ),
    ],
    'Futuristic Vision': [
      TransformationOption(
        title: 'Cyberpunk\nFuture',
        imagePath: 'assets/images/cyberpunk_future_thumbnail.png',
      ),
      TransformationOption(
        title: 'Space\nExplorer',
        imagePath: 'assets/images/space_explorer_thumbnail.png',
      ),
    ],
    'Playful Fun': [
      TransformationOption(
        title: 'Extreme\nSports',
        imagePath: 'assets/images/extreme_sports_thumbnail.png',
      ),
      TransformationOption(
        title: 'Fantasy\nKingdom',
        imagePath: 'assets/images/fantasy_kingdoom_thumbnail.png',
      ),
    ],
  };

  void toggleSection(String section) {
    setState(() {
      if (expandedSection == section) {
        expandedSection = null;
      } else {
        expandedSection = section;
      }
    });
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
            Positioned(
              left: 0,
              right: 0,
              top: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select your\ntransformation",
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 46),

                  // Dropdown Sections
                  ...transformationOptions.keys.map((section) {
                    final isExpanded = expandedSection == section;
                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () => toggleSection(section),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? const Color(0xFF0B7C84)
                                  : const Color(0xFF0A5F63),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  section,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w300,
                                    color: AppColors.white,
                                  ),
                                ),
                                Image.asset(
                                  isExpanded
                                      ? "assets/icons/up-arrow.png"
                                      : "assets/icons/down-arrow.png",
                                  width: 32,
                                  height: 32,
                                  color: AppColors.white,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Options
                        if (isExpanded) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: transformationOptions[section]!.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final option = entry.value;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Handle option selection
                                    final transformationType = option.title
                                        .replaceAll('\n', ' ');
                                    debugPrint(
                                      'Selected transformation: $transformationType',
                                    );
                                    context
                                        .read<UserSelectionModel>()
                                        .setTransformation(
                                          section,
                                          transformationType,
                                        );

                                    // Log current user selections for debugging
                                    final userModel = context
                                        .read<UserSelectionModel>();
                                    debugPrint(
                                      'Current gender: ${userModel.gender}',
                                    );
                                    debugPrint(
                                      'Current category: ${userModel.category}',
                                    );
                                    debugPrint(
                                      'Current transformation: ${userModel.transformationType}',
                                    );

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const FaceCaptureScreen(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      right: index == 0 ? 20 : 0,
                                      left: index == 1 ? 20 : 0,
                                    ),
                                    padding: const EdgeInsets.all(32),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0A5F63),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.zero,
                                          child: Image.asset(
                                            option.imagePath,
                                            width: double.infinity,
                                            height: 153,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    width: double.infinity,
                                                    height: 153,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 60,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          option.title,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w300,
                                            height: 1.1,
                                            color: AppColors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          height: 12,
                                          width: 94,
                                          color: AppColors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (section != transformationOptions.keys.last)
                          const SizedBox(height: 16),
                      ],
                    );
                  }),

                  const SizedBox(height: 60),

                  // Back Button
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white.withValues(alpha: 0.9),
                      foregroundColor: const Color(0xFF0A5F63),
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

class TransformationOption {
  final String title;
  final String imagePath;

  TransformationOption({required this.title, required this.imagePath});
}
