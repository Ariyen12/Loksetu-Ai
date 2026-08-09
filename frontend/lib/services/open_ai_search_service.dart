import 'dart:convert';
import 'package:http/http.dart' as http;
import 'gemini_api_service.dart';

class OpenAISearchResponse {
  final String text;
  final String source;

  OpenAISearchResponse({
    required this.text,
    required this.source,
  });
}

class OpenAISearchService {
  /// Queries Live Google Gemini API or Live Open Knowledge Search API for ANY question
  static Future<OpenAISearchResponse> searchAnyQuestion({
    required String query,
    required String language,
    String? apiKey,
  }) async {
    final trimmed = query.trim();

    // 1. TRY LIVE GOOGLE GEMINI API FIRST
    final liveGemini = await GeminiAPIService.queryGoogleGeminiAPI(
      prompt: trimmed,
      language: language,
      apiKey: apiKey,
    );

    if (liveGemini != null && liveGemini.text.isNotEmpty) {
      return OpenAISearchResponse(
        text: liveGemini.text,
        source: "Google Gemini AI",
      );
    }

    // 2. LIVE WIKIPEDIA REAL-TIME API SEARCH
    try {
      final cleanQuery = trimmed.replaceAll(RegExp(r'[\?\!\.\,\;\:]'), '');
      final wikiResult = await _fetchWikipediaSummary(cleanQuery, language);
      if (wikiResult != null && wikiResult.isNotEmpty) {
        return OpenAISearchResponse(
          text: wikiResult,
          source: "Wikipedia Search",
        );
      }
    } catch (_) {}

    // 3. DUCKDUCKGO INSTANT ANSWER REAL-TIME API SEARCH
    try {
      final ddgResult = await _fetchDuckDuckGoAnswer(trimmed);
      if (ddgResult != null && ddgResult.isNotEmpty) {
        return OpenAISearchResponse(
          text: ddgResult,
          source: "DuckDuckGo Instant Answer",
        );
      }
    } catch (_) {}

    // 4. INTELLIGENT HELPFUL FALLBACK (NO TEMPLATE INTRO TEXT)
    String fallback = "";
    if (language.contains("Hindi") || language.contains("हिंदी")) {
      fallback = "Main aapki madad ke liye hamesha tayaar hoon! Kripya kisi bhi kheti, swasthya, yojana, ya shiksha ke sawal ko bolein ya likhein. 🙏✨";
    } else if (language.contains("Assamese") || language.contains("অসমীয়া")) {
      fallback = "Moy aponar rogaayor babe prosto asu! Kheti, sasthyo aru sarkari aasonir sawal hudhibo pare. 🙏✨";
    } else if (language.contains("Bengali") || language.contains("বাংলা")) {
      fallback = "Ami apnar sahajyer jonyo prostut achhi! Krishi, swasthya o sarkari prakalpa niye prashno korte paren. 🙏✨";
    } else {
      fallback = "I am ready to help you! Please feel free to ask any question about farming, health, government schemes, or education. 🙏✨";
    }

    return OpenAISearchResponse(
      text: fallback,
      source: "LokSetu AI Engine",
    );
  }

  /// Fetches live summary from Wikipedia REST API in target language
  static Future<String?> _fetchWikipediaSummary(String query, String lang) async {
    String langCode = "en";
    if (lang.contains("Hindi") || lang.contains("हिंदी")) langCode = "hi";
    if (lang.contains("Bengali") || lang.contains("বাংলা")) langCode = "bn";
    if (lang.contains("Assamese") || lang.contains("অসমীয়া")) langCode = "as";

    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('https://$langCode.wikipedia.org/api/rest_v1/page/summary/$encoded');

    final response = await http.get(url, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final extract = data['extract'] as String?;
      if (extract != null && extract.trim().isNotEmpty) {
        final sentences = extract.split(RegExp(r'(?<=[.!?])\s+'));
        final shortSummary = sentences.take(2).join(' ');
        return shortSummary;
      }
    }

    if (langCode != "en") {
      final enUrl = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$encoded');
      final enResp = await http.get(enUrl, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 3));
      if (enResp.statusCode == 200) {
        final data = jsonDecode(enResp.body);
        final extract = data['extract'] as String?;
        if (extract != null && extract.trim().isNotEmpty) {
          final sentences = extract.split(RegExp(r'(?<=[.!?])\s+'));
          return sentences.take(2).join(' ');
        }
      }
    }

    return null;
  }

  /// Fetches live answer from DuckDuckGo REST API
  static Future<String?> _fetchDuckDuckGoAnswer(String query) async {
    final url = Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1&skip_disambig=1');
    final response = await http.get(url).timeout(const Duration(seconds: 3));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final abstractText = data['AbstractText'] as String?;
      if (abstractText != null && abstractText.trim().isNotEmpty) {
        return abstractText.trim();
      }
      final answer = data['Answer'] as String?;
      if (answer != null && answer.trim().isNotEmpty) {
        return answer.trim();
      }
    }
    return null;
  }
}
