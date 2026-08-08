import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiAPIResponse {
  final String text;
  final List<String> links;
  final bool isFromGoogleAPI;

  GeminiAPIResponse({
    required this.text,
    required this.links,
    required this.isFromGoogleAPI,
  });
}

class GeminiAPIService {
  // Configurable Google Gemini API Key
  static String userApiKey = "";

  /// Queries Google Gemini API (gemini-1.5-flash) for live real-time answers
  static Future<GeminiAPIResponse?> queryGoogleGeminiAPI({
    required String prompt,
    required String language,
    String? apiKey,
  }) async {
    final keyToUse = (apiKey != null && apiKey.isNotEmpty) ? apiKey : userApiKey;
    if (keyToUse.trim().isEmpty) {
      return null;
    }

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$keyToUse');

      final systemPrompt =
          "You are LokSetu AI, a smart multilingual assistant for farmers and citizens across India. "
          "Answer the user's question accurately in short, crisp 2-3 bullet points in $language. "
          "Do not give long paragraphs. Keep it sweet, direct, and concise.";

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$systemPrompt\n\nUser Question: $prompt"}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.4,
          "maxOutputTokens": 300,
        }
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

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
                links: [
                  "https://gemini.google.com/search?q=${Uri.encodeComponent(prompt)} (Google Gemini AI)",
                  "https://chatgpt.com (ChatGPT)",
                  "https://services.india.gov.in (Official Govt Portal)"
                ],
                isFromGoogleAPI: true,
              );
            }
          }
        }
      } else {
        debugPrint("Google Gemini API HTTP Error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Google Gemini API Exception: $e");
    }

    return null;
  }
}
