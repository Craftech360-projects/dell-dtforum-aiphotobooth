import 'package:dell_photobooth_2025/config/app_config.dart';
import 'package:dell_photobooth_2025/core/app_theme.dart';
import 'package:dell_photobooth_2025/models/user_selection_model.dart';
import 'package:dell_photobooth_2025/screens/download_page.dart';
import 'package:dell_photobooth_2025/screens/welcome_screen.dart';
import 'package:dell_photobooth_2025/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await AppConfig.initialize();

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
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/download': (context) => _buildDownloadPage(context),
        },
      ),
    );
  }

  Widget _buildDownloadPage(BuildContext context) {
    // Extract image URL from query parameters
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    final imageUrl = uri.queryParameters['img'] ?? '';
    
    if (imageUrl.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Invalid image URL',
            style: TextStyle(fontSize: 24),
          ),
        ),
      );
    }
    
    return DownloadPage(imageUrl: imageUrl);
  }
}
  