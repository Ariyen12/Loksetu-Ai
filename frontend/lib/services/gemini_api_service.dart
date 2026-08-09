import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiAPIResponse {
  final String text;
  final bool isFromGoogleAPI;

  GeminiAPIResponse({
    required this.text,
    required this.isFromGoogleAPI,
  });
}

class GeminiAPIService {
  // Configurable Google Gemini API Key
  static String userApiKey = "";

  /// Queries Google Gemini API (gemini-1.5-flash) or Live Knowledge API for exact answers
  static Future<GeminiAPIResponse?> queryGoogleGeminiAPI({
    required String prompt,
    required String language,
    String? apiKey,
  }) async {
    final keyToUse = (apiKey != null && apiKey.trim().isNotEmpty)
        ? apiKey.trim()
        : userApiKey.trim();

    final systemPrompt =
        "You are LokSetu AI. Answer the user's question directly in $language with the EXACT, point-blank answer in 1 to 2 short sentences. "
        "Do NOT include any preamble, intros, filler text, or headers. Give ONLY the direct answer with warm polite gestures.";

    // 1. IF USER OR APP PROVIDED GEMINI API KEY
    if (keyToUse.isNotEmpty) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$keyToUse');

        final body = jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "$systemPrompt\n\nUser Question: $prompt"}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 200,
          }
        });

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'];
            final parts = content['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final answerText = parts[0]['text'] as String?;
              if (answerText != null && answerText.trim().isNotEmpty) {
                return GeminiAPIResponse(
                  text: answerText.trim(),
                  isFromGoogleAPI: true,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Google Gemini API error: $e");
      }
    }

    return null;
  }
}
