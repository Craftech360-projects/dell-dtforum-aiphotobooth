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
                      fontWeight: FontWeight.w200,
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
                                    fontSize: 40,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.white,
                                  ),
                                ),
                                Image.asset(
                                  isExpanded
                                      ? "assets/icons/up-arrow.png"
                                      : "assets/icons/down-arrow.png",
                                  width: 32,
                                  height: 32,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded Options
                        if (isExpanded) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: transformationOptions[section]!
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final option = entry.value;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        // Handle option selection
                                        context.read<UserSelectionModel>().setTransformation(
                                          section,
                                          option.title.replaceAll('\n', ' '),
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const FaceCaptureScreen(),
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
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
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
                                                fontWeight: FontWeight.w200,
                                                height: 1.1,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              height: 12,
                                              width: 94,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (section != transformationOptions.keys.last)
                          const SizedBox(height: 16),
                      ],
                    );
                  }),
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
