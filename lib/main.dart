import 'package:dell_photobooth_2025/core/app_theme.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/welcome_screen.dart';
import 'package:dell_photobooth_2025/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } on Exception catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UserSelectionModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        title: 'DT Forum 2025 - AI Photobooth',
        home: const WelcomeScreen(),
      ),
    );
  }
}
