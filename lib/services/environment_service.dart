import 'package:flutter/foundation.dart';

class EnvironmentService {
  static String get apiBaseUrl {
    // Check if running on localhost
    if (kDebugMode || _isLocalhost()) {
      return 'http://localhost:5555';
    }
    
    // Production URL - will be set to your Vercel deployment URL
    // Update this after deploying to Vercel
    return _getProductionUrl();
  }
  
  static bool _isLocalhost() {
    final uri = Uri.base;
    return uri.host == 'localhost' || 
           uri.host == '127.0.0.1' || 
           uri.host.startsWith('192.168.');
  }
  
  static String _getProductionUrl() {
    final uri = Uri.base;
    // Use the same domain for API calls when deployed
    return '${uri.scheme}://${uri.host}/api';
  }
  
  static String getEndpoint(String path) {
    final baseUrl = apiBaseUrl;
    
    // For production, adjust the path
    if (!baseUrl.contains('localhost') && !baseUrl.contains('127.0.0.1')) {
      // Vercel API routes
      switch (path) {
        case '/detect_palm':
          return '$baseUrl/detect_palm';
        case '/process_linkedin':
          return '$baseUrl/process_linkedin';
        case '/health':
          return '$baseUrl/health';
        default:
          return '$baseUrl$path';
      }
    }
    
    // Local development
    return '$baseUrl$path';
  }
}