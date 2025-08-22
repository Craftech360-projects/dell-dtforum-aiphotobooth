import 'package:dell_photobooth_2025/core/app_colors.dart';
import 'package:dell_photobooth_2025/screens/category_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 132, top: 104),
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background-one.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset("assets/images/dell-logo.png", width: 192),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Redefine\nwhat's real.",
                    style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w300,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 35),
                  Container(width: 169, height: 45, color: AppColors.white),
                  const SizedBox(height: 60),
                  const Text(
                    "AI transforms your photo\ninto worlds of play, art, and\nwonder - instantly.",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 120),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CategoryScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 136,
                      ),
                    ),
                    child: const Text(
                      "Start",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
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
