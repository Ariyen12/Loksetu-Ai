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

    // 2. CURATED DIRECT ENCYCLOPEDIA & SCIENCE REPOSITORY
    final directResponse = _getCuratedEncyclopediaResponse(lower, trimmed, language);
    if (directResponse != null) {
      return OpenAISearchResponse(
        text: directResponse,
        source: "LokSetu Knowledge Engine",
      );
    }

    // 3. DUCKDUCKGO INSTANT ANSWER REAL-TIME API
    try {
      final duckAnswer = await _searchDuckDuckGo(trimmed);
      if (duckAnswer != null && duckAnswer.isNotEmpty) {
        return OpenAISearchResponse(
          text: "$duckAnswer\n\nHope this helps you! Have a wonderful day ahead! 🙏✨",
          source: "DuckDuckGo Knowledge API",
        );
      }
    } catch (_) {}

    // 4. WIKIPEDIA SMART SEARCH WITH MULTI-TOKEN EXTRACTION
    try {
      final wikiSummary = await _searchWikipediaSmart(trimmed, language);
      if (wikiSummary != null && wikiSummary.isNotEmpty) {
        return OpenAISearchResponse(
          text: "$wikiSummary\n\nHope this helps you! Have a wonderful day ahead! 🙏✨",
          source: "Wikipedia Knowledge Engine",
        );
      }
    } catch (_) {}

    // 5. INTELLIGENT DIRECT CONTEXTUAL KNOWLEDGE ANSWER GENERATOR
    String smartAnswer = _generateContextualAnswer(trimmed, language);
    return OpenAISearchResponse(
      text: smartAnswer,
      source: "LokSetu AI Engine",
    );
  }

  /// Queries DuckDuckGo Instant Answer API
  static Future<String?> _searchDuckDuckGo(String query) async {
    try {
      final url = Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1');
      final resp = await http.get(url).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final abstractText = data['AbstractText'] as String?;
        if (abstractText != null && abstractText.trim().isNotEmpty) {
          final sentences = abstractText.split(RegExp(r'(?<=[.!?])\s+'));
          return sentences.take(2).join(' ');
        }
      }
    } catch (_) {}
    return null;
  }

  /// Searches Wikipedia with multi-token keyword extraction
  static Future<String?> _searchWikipediaSmart(String query, String lang) async {
    String langCode = "en";
    if (lang.contains("Hindi") || lang.contains("हिंदी")) langCode = "hi";
    if (lang.contains("Bengali") || lang.contains("বাংলা")) langCode = "bn";
    if (lang.contains("Assamese") || lang.contains("অসমীয়া")) langCode = "as";

    final headers = {
      'User-Agent': 'LokSetuAI/2.0 (https://github.com/Ariyen12/Loksetu-Ai)',
      'Accept': 'application/json',
    };

    // Clean query words for search
    final cleaned = query.replaceAll(RegExp(r'[\?\!\.\,\;\:\-\_]'), '').trim();
    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((word) => !RegExp(r'^(who|what|where|when|why|how|is|the|are|in|of|for|a|an|tell|me|about|explain|kya|hai|kaun|kaise|hotas|hote)$', caseSensitive: false).hasMatch(word))
        .toList();

    final candidates = <String>[];
    if (tokens.isNotEmpty) candidates.add(tokens.join(' '));
    if (tokens.length >= 2) candidates.add(tokens.take(2).join(' '));
    for (var t in tokens) {
      if (t.length > 3) candidates.add(t);
    }
    candidates.add(cleaned);

    for (var targetQuery in candidates) {
      try {
        final searchUrl = Uri.parse('https://$langCode.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(targetQuery)}&limit=1&format=json');
        final searchResp = await http.get(searchUrl, headers: headers).timeout(const Duration(seconds: 2));
        if (searchResp.statusCode == 200) {
          final searchData = jsonDecode(searchResp.body) as List?;
          if (searchData != null && searchData.length >= 2) {
            final titles = searchData[1] as List?;
            if (titles != null && titles.isNotEmpty) {
              final articleTitle = titles[0] as String;
              if (articleTitle.isNotEmpty) {
                final summaryUrl = Uri.parse('https://$langCode.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(articleTitle)}');
                final summaryResp = await http.get(summaryUrl, headers: headers).timeout(const Duration(seconds: 2));
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
      } catch (_) {}
    }

    return null;
  }

  /// Curated Encyclopedia covering Science, Geography, History, Tech, Farming & Health
  static String? _getCuratedEncyclopediaResponse(String lower, String query, String lang) {
    // 1. SKY / ATMOSPHERE / RAIN
    if (lower.contains("sky") || lower.contains("aasmaan") || lower.contains("akax")) {
      return "The sky appears blue because of Rayleigh scattering. Earth's atmosphere scatters shorter blue light wavelengths from the Sun more than longer red light wavelengths. 🙏✨";
    }

    if (lower.contains("rain") || lower.contains("baarish") || lower.contains("borxun") || lower.contains("bristi") || lower.contains("cloud")) {
      return "Rain occurs when water vapor in clouds condenses into heavier water droplets that fall due to gravity. Clouds are formed by evaporation of water from oceans, rivers, and lakes. 🌧️🙏";
    }

    if (lower.contains("sun") || lower.contains("suraj") || lower.contains("belius") || lower.contains("surjo")) {
      return "The Sun is a yellow dwarf star at the center of our solar system. It generates energy through nuclear fusion of hydrogen into helium, providing heat and light essential for life on Earth. ☀️✨";
    }

    if (lower.contains("moon") || lower.contains("chand") || lower.contains("jon") || lower.contains("chandrama")) {
      return "The Moon is Earth's only natural satellite. It orbits Earth every 27.3 days and causes ocean tides due to its gravitational pull. 🌙✨";
    }

    // 2. SCIENCE INVENTIONS
    if (lower.contains("bulb") || lower.contains("edison") || lower.contains("invented light")) {
      return "The electric light bulb was invented by Thomas Edison in 1879. Hope this helps you! Have a wonderful day! 🙏✨";
    }

    if (lower.contains("telephone") || lower.contains("phone") || lower.contains("bell")) {
      return "The telephone was invented by Alexander Graham Bell in 1876. 🙏✨";
    }

    if (lower.contains("computer") || lower.contains("babbage")) {
      return "Charles Babbage is known as the Father of the Computer for inventing the Analytical Engine. 🙏✨";
    }

    if (lower.contains("photosynthesis")) {
      return "Photosynthesis is the process where green plants use sunlight, water, and carbon dioxide to create glucose energy and release oxygen. 🌿🌾";
    }

    if (lower.contains("gravity") || lower.contains("newton") || lower.contains("gurutva")) {
      return "Gravity is the universal force that attracts physical bodies toward each other. Sir Isaac Newton formulated the Law of Universal Gravitation. 🍎✨";
    }

    if (lower.contains("ai") || lower.contains("artificial intelligence")) {
      return "Artificial Intelligence (AI) refers to computer systems engineered to perform complex cognitive tasks like reasoning, learning, and processing natural human language. 🤖✨";
    }

    // 3. REGIONAL & GENERAL KNOWLEDGE
    if (lower.contains("tea") || lower.contains("assam tea") || lower.contains("chai")) {
      return "Assam is world-famous for producing high-quality black tea (Camellia sinensis var. assamica) grown in the fertile Brahmaputra valley. ☕🌾";
    }

    if (lower.contains("brahmaputra")) {
      return "The Brahmaputra River originates in Tibet (as the Yarlung Tsangpo), flows through Arunachal Pradesh and Assam, and merges into the Bay of Bengal. 🌊🙏";
    }

    return null;
  }

  /// Generates meaningful, helpful response for any open question based on domain keywords
  static String _generateContextualAnswer(String query, String lang) {
    final lower = query.toLowerCase();

    if (lower.contains("crop") || lower.contains("kheti") || lower.contains("farm") || lower.contains("fasal") || lower.contains("rice") || lower.contains("tea") || lower.contains("soil")) {
      return "Regarding your farming query about '$query': For maximum crop yield, test your soil at your local Krishi Vigyan Kendra (KVK), use vermicompost organic fertilizers, and follow proper irrigation. Call Kisan Helpline toll-free at 1800-180-1551 for free crop doctor guidance. 🌾🙏";
    }

    if (lower.contains("health") || lower.contains("fever") || lower.contains("disease") || lower.contains("bimar") || lower.contains("doctor") || lower.contains("medicine")) {
      return "Regarding your medical query about '$query': Consult qualified doctors online for free via eSanjeevani (esanjeevaniopd.in). For health emergencies, call 108 immediately. 🏥🌸";
    }

    if (lower.contains("scheme") || lower.contains("yojana") || lower.contains("government") || lower.contains("sarkari") || lower.contains("loan") || lower.contains("money")) {
      return "Regarding government schemes for '$query': Major public welfare initiatives include Ayushman Bharat (₹5 Lakh health cover), PM-Kisan (₹6,000 annual support), and PM Fasal Bima Yojana. Visit your nearest CSC to check eligibility. 📜✨";
    }

    if (lang.contains("Hindi") || lang.contains("हिंदी")) {
      return "Aapke sawal '$query' ke liye LokSetu AI kheti, swasthya, yojana, vigyan, aur shiksha ki puri jankari deta hai. Kripya apna vishay spakht bolein. 🙏✨";
    } else if (lang.contains("Assamese") || lang.contains("অসমীয়া")) {
      return "Aaponar sawal '$query' babe LokSetu AI kheti, sasthyo, yojana aru shikshor jankari jogay. 🙏✨";
    } else if (lang.contains("Bengali") || lang.contains("বাংলা")) {
      return "Apnar prashno '$query' r jonyo LokSetu AI krishi, swasthya, o sarkari prakalpa niye sahajyo kare. 🙏✨";
    }

    return "Regarding '$query': LokSetu AI provides comprehensive guidance for science, agriculture, healthcare, education, and government welfare schemes. Feel free to ask more details! 🙏✨";
  }
}



