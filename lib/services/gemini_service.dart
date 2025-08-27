import 'dart:convert';

import 'package:dell_photobooth_2025/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel get _geminiModel {
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash-image-preview',
      apiKey: AppConfig.geminiApiKey,
    );
    return _model!;
  }

  static Future<Uint8List?> generateLinkedInHeadshot({
    required Uint8List inputImageBytes,
  }) async {
    try {
      debugPrint('🔥 Starting Gemini LinkedIn headshot generation');
      
      // Use direct HTTP API call for web to avoid streaming issues
      if (kIsWeb) {
        return await _generateLinkedInHeadshotWeb(inputImageBytes);
      }
      
      const prompt = '''
Transform this person into a professional LinkedIn headshot. Put the person in professional business attire in a modern office setting with clean, professional lighting. Maintain the person's facial features and identity while enhancing the professional appearance. 

Requirements:
- Professional business attire (suit, blazer, or dress shirt)
- Clean, modern office or studio background
- Professional lighting that flatters the person
- High-quality, sharp image suitable for LinkedIn
- Maintain the person's natural facial features and identity
- Remove any distracting elements from the background
- Ensure the person looks confident and approachable
''';

      final imagePart = DataPart('image/jpeg', inputImageBytes);
      final textPart = TextPart(prompt);

      debugPrint('🚀 Sending request to Gemini API');
      
      final response = await _geminiModel.generateContent([
        Content.multi([textPart, imagePart])
      ]);

      debugPrint('📨 Received response from Gemini API');

      if (response.candidates.isNotEmpty) {
        final candidate = response.candidates.first;
        
        if (candidate.content.parts.isNotEmpty) {
          for (final part in candidate.content.parts) {
            if (part is DataPart && part.mimeType.startsWith('image/')) {
              debugPrint('✅ Successfully generated LinkedIn headshot');
              debugPrint('Generated image size: ${part.bytes.length} bytes');
              return part.bytes;
            }
          }
        }
      }

      debugPrint('❌ No image found in Gemini response');
      
      if (response.text != null && response.text!.isNotEmpty) {
        debugPrint('Gemini response text: ${response.text}');
      }
      
      return null;
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API error: ${e.message}');
      return null;
    } on Exception catch (e) {
      debugPrint('❌ Error generating LinkedIn headshot: $e');
      return null;
    }
  }

  static Future<Uint8List?> _generateLinkedInHeadshotWeb(
    Uint8List inputImageBytes,
  ) async {
    try {
      debugPrint('🌐 Using web-compatible HTTP API for Gemini');
      
      const prompt = '''
Transform this person into a professional LinkedIn headshot. Put the person in professional business attire in a modern office setting with clean, professional lighting. Maintain the person's facial features and identity while enhancing the professional appearance. 

Requirements:
- Professional business attire (suit, blazer, or dress shirt)
- Clean, modern office or studio background
- Professional lighting that flatters the person
- High-quality, sharp image suitable for LinkedIn
- Maintain the person's natural facial features and identity
- Remove any distracting elements from the background
- Ensure the person looks confident and approachable
''';

      final base64Image = base64Encode(inputImageBytes);
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'candidateCount': 1,
          'maxOutputTokens': 4096,
        }
      };

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image-preview:generateContent?key=${AppConfig.geminiApiKey}',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('📨 Web API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Debug: Print the entire response structure
        debugPrint('🔍 Full response structure: ${jsonEncode(responseData)}');
        
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty) {
          final candidate = responseData['candidates'][0];
          debugPrint('🔍 Candidate keys: ${candidate.keys.toList()}');
          
          if (candidate['content'] != null && candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];
            debugPrint('🔍 Parts count: ${parts.length}');
            
            for (int i = 0; i < parts.length; i++) {
              final part = parts[i];
              debugPrint('🔍 Part $i keys: ${part.keys.toList()}');
              
              if (part['inlineData'] != null) {
                final imageData = part['inlineData']['data'];
                final imageBytes = base64Decode(imageData);
                debugPrint('✅ Successfully generated LinkedIn headshot via web API');
                debugPrint('Generated image size: ${imageBytes.length} bytes');
                return imageBytes;
              }
              
              if (part['text'] != null) {
                debugPrint('🔍 Part $i text: ${part['text']}');
              }
            }
          } else {
            debugPrint('❌ No content or parts found in candidate');
          }
        } else {
          debugPrint('❌ No candidates found in response');
        }
      } else {
        debugPrint('❌ Web API error: ${response.statusCode} - ${response.body}');
      }
      
      return null;
    } on Exception catch (e) {
      debugPrint('❌ Error in web-compatible Gemini API: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> testGeminiConnection() async {
    try {
      const testPrompt = 'Hello, can you generate a simple test image?';
      
      final response = await _geminiModel.generateContent([
        Content.text(testPrompt)
      ]);

      if (response.text != null) {
        debugPrint('✅ Gemini API connection successful');
        return {
          'status': 'success',
          'message': 'Gemini API connection successful',
          'response': response.text,
        };
      }

      return {
        'status': 'error',
        'message': 'No response from Gemini API',
      };
    } on GenerativeAIException catch (e) {
      debugPrint('❌ Gemini API connection failed: ${e.message}');
      return {
        'status': 'error',
        'message': 'Gemini API error: ${e.message}',
      };
    } on Exception catch (e) {
      debugPrint('❌ Error testing Gemini connection: $e');
      return {
        'status': 'error',
        'message': 'Connection error: $e',
      };
    }
  }
}