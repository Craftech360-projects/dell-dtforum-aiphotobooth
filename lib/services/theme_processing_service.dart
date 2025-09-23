import 'dart:typed_data';
import 'package:dell_photobooth_2025/services/gemini_service.dart';
import 'package:flutter/material.dart';

class ThemeProcessingService {
  static const Map<String, String> _themePrompts = {
    'linkedin': '''
Transform this person's photo into a professional LinkedIn headshot. Create a clean, professional business portrait with:
- Professional business attire (suit, blazer, or formal wear)
- Clean, polished appearance
- Neutral, professional background (office setting or subtle gradient)
- Confident, approachable expression
- High-quality, well-lit photography style
- Corporate headshot aesthetic
''',

    'diwali_costume': '''
Transform this person into a stunning Diwali costume portrait with:
- Traditional Indian festive clothing (elaborate lehenga, saree, or kurta with rich embroidery)
- Rich, vibrant colors like deep red, golden yellow, royal blue, or emerald green
- Traditional Indian jewelry (kundan, gold jewelry, maang tikka, earrings)
- Festive makeup with bold eyes and traditional elements
- Ornate patterns and embellishments on clothing
- Regal and celebratory appearance
- Warm, festive lighting
''',

    'diwali_celebration': '''
Transform this person into a joyful Diwali celebration scene with:
- Festive Indian attire in bright, celebratory colors
- Surrounded by traditional Diwali elements (diyas, rangoli patterns, marigold flowers)
- Warm, golden lighting mimicking diya glow
- Sparklers or fireworks in the background
- Traditional decorations and lanterns
- Joyful, celebratory expression
- Festive atmosphere with warm amber and gold tones
- Traditional sweets and celebration items nearby
''',

    'crackers': '''
Transform this person into an exciting Diwali crackers celebration with:
- Festive clothing suitable for celebrations
- Background filled with colorful fireworks and sparklers
- Bright, dynamic lighting with bursts of color
- Safe distance from crackers with sparklers in hand
- Night sky with colorful firework displays
- Festive and energetic atmosphere
- Vibrant colors - reds, golds, blues, and greens from fireworks
- Excited, joyful expression
- Traditional Diwali elements mixed with celebration
''',

    'pooja': '''
Transform this person into a serene Diwali pooja (prayer) scene with:
- Traditional Indian prayer attire (simple, elegant saree, kurta, or traditional wear)
- Spiritual and peaceful setting with diyas and prayer items
- Hands in prayer position or holding prayer items
- Traditional pooja thali with diyas, flowers, and incense
- Temple or spiritual background with soft lighting
- Calm, devotional expression
- Warm, soft lighting from oil lamps
- Traditional elements like flowers, incense, and prayer decorations
- Peaceful and spiritual atmosphere
- Golden and warm color palette
'''
  };

  static Future<Uint8List?> processImageWithTheme({
    required Uint8List inputImageBytes,
    required String theme,
  }) async {
    try {
      final prompt = _themePrompts[theme];
      if (prompt == null) {
        debugPrint('❌ Unknown theme: $theme');
        return null;
      }

      debugPrint('🎨 Processing image with $theme theme');

      if (theme == 'linkedin') {
        // Use existing LinkedIn processing
        return await GeminiService.generateLinkedInHeadshot(
          inputImageBytes: inputImageBytes,
        );
      } else {
        // Use custom theme processing
        return await GeminiService.generateThemedImage(
          inputImageBytes: inputImageBytes,
          prompt: prompt,
        );
      }
    } catch (e) {
      debugPrint('❌ Error processing image with theme $theme: $e');
      return null;
    }
  }

  static String getThemeDisplayName(String theme) {
    switch (theme) {
      case 'linkedin':
        return 'LinkedIn Professional';
      case 'diwali_costume':
        return 'Diwali Costume';
      case 'diwali_celebration':
        return 'Diwali Celebration';
      case 'crackers':
        return 'Crackers Theme';
      case 'pooja':
        return 'Pooja Theme';
      default:
        return 'Unknown Theme';
    }
  }
}