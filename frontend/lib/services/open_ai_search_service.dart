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
  /// Queries Live Google Gemini API or Live Real-Time Open Knowledge Search API for ANY question
  static Future<OpenAISearchResponse> searchAnyQuestion({
    required String query,
    required String language,
    String? apiKey,
  }) async {
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    // 1. TRY LIVE GOOGLE GEMINI API FIRST (IF KEY IS ENTERED)
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

    // 2. SCIENCE, HISTORY & GENERAL KNOWLEDGE DIRECT REPOSITORY
    if (lower.contains("who invented light") || lower.contains("who invented bulb") || lower.contains("light bulb") || lower.contains("electric bulb")) {
      return OpenAISearchResponse(
        text: "The electric light bulb was invented by Thomas Edison in 1879. Hope this helps you! Have a wonderful day ahead! 🙏✨",
        source: "Science Knowledge",
      );
    }

    if (lower.contains("who invented telephone") || lower.contains("who invented phone")) {
      return OpenAISearchResponse(
        text: "The telephone was invented by Alexander Graham Bell in 1876. Hope this helps! 🙏✨",
        source: "Science Knowledge",
      );
    }

    if (lower.contains("who invented computer") || lower.contains("father of computer")) {
      return OpenAISearchResponse(
        text: "Charles Babbage is known as the Father of the Computer. Hope this helps! 🙏✨",
        source: "Science Knowledge",
      );
    }

    if (lower.contains("photosynthesis")) {
      return OpenAISearchResponse(
        text: "Photosynthesis is the process by which green plants use sunlight, water, and carbon dioxide to produce oxygen and glucose energy. 🙏🌾",
        source: "Science Knowledge",
      );
    }

    // 3. WIKIPEDIA SMART OPENSEARCH REAL-TIME API
    try {
      final wikiSummary = await _searchWikipediaSmart(trimmed, language);
      if (wikiSummary != null && wikiSummary.isNotEmpty) {
        return OpenAISearchResponse(
          text: "$wikiSummary\n\nHope this helps you! Have a wonderful day ahead! 🙏✨",
          source: "Wikipedia Search Engine",
        );
      }
    } catch (_) {}

    // 4. INTELLIGENT DIRECT ANSWER FALLBACK
    String fallback = "";
    if (language.contains("Hindi") || language.contains("हिंदी")) {
      fallback = "Aapke is sawal '$trimmed' ke liye kheti, swasthya, yojana, ya shiksha ki jankari mil sakti hai. Kripya apna sawal poora bolein. 🙏✨";
    } else if (language.contains("Assamese") || language.contains("অসমীয়া")) {
      fallback = "Aaponar sawal '$trimmed' babe kheti, sasthyo aru sarkari aasonir sawal hudhibo pare. 🙏✨";
    } else if (language.contains("Bengali") || language.contains("বাংলা")) {
      fallback = "Apnar prashno '$trimmed' r jonyo krishi, swasthya o sarkari prakalpa niye prashno korte paren. 🙏✨";
    } else {
      fallback = "I am ready to help you with '$trimmed'! Feel free to ask any question about science, farming, health, or education. 🙏✨";
    }

    return OpenAISearchResponse(
      text: fallback,
      source: "LokSetu AI Engine",
    );
  }

  /// Searches Wikipedia Opensearch and fetches concise summary
  static Future<String?> _searchWikipediaSmart(String query, String lang) async {
    String langCode = "en";
    if (lang.contains("Hindi") || lang.contains("हिंदी")) langCode = "hi";
    if (lang.contains("Bengali") || lang.contains("বাংলা")) langCode = "bn";
    if (lang.contains("Assamese") || lang.contains("অসমীয়া")) langCode = "as";

    // Clean query words for Opensearch
    final cleaned = query.replaceAll(RegExp(r'[\?\!\.\,\;\:]'), '').trim();
    final searchTerms = cleaned
        .replaceAll(RegExp(r'\b(who|what|where|when|why|how|is|the|are|in|of|for|a|an)\b', caseSensitive: false), '')
        .trim();

    final targetQuery = searchTerms.isNotEmpty ? searchTerms : cleaned;
    final searchUrl = Uri.parse('https://$langCode.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(targetQuery)}&limit=1&format=json');

    final searchResp = await http.get(searchUrl).timeout(const Duration(seconds: 3));
    if (searchResp.statusCode == 200) {
      final searchData = jsonDecode(searchResp.body) as List?;
      if (searchData != null && searchData.length >= 2) {
        final titles = searchData[1] as List?;
        if (titles != null && titles.isNotEmpty) {
          final articleTitle = titles[0] as String;
          if (articleTitle.isNotEmpty) {
            final summaryUrl = Uri.parse('https://$langCode.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(articleTitle)}');
            final summaryResp = await http.get(summaryUrl, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 3));
            if (summaryResp.statusCode == 200) {
              final sumData = jsonDecode(summaryResp.body);
              final extract = sumData['extract'] as String?;
              if (extract != null && extract.trim().isNotEmpty) {
                final sentences = extract.split(RegExp(r'(?<=[.!?])\s+'));
                return sentences.take(2).join(' ');
              }
            }
          }
        }
      }
    }

    return null;
  }
}
