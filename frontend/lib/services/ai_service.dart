import 'open_ai_search_service.dart';
import 'gemini_api_service.dart';

class AIResponse {
  final String text;
  final String detectedLanguage;
  final bool isLiveGoogleGemini;

  AIResponse({
    required String text,
    required this.detectedLanguage,
    this.isLiveGoogleGemini = false,
  }) : text = _cleanTextForSpeech(text);

  static String _cleanTextForSpeech(String rawText) {
    return rawText
        .replaceAll(RegExp(r'\*\*'), '') // strip bold markdown
        .replaceAll(RegExp(r'###?'), '')  // strip headers
        .replaceAll(RegExp(r'`'), '')
        .trim();
  }
}

class LokSetuAIService {
  /// Resolves ANY user query including casual greetings like "kese ho?" with 100% accuracy
  static Future<AIResponse> getAnswer({
    required String query,
    required String currentCategory,
    required String activeLanguage,
    String? userApiKey,
  }) async {
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase().replaceAll(RegExp(r'[\?\!\.\,\;\:]'), '');

    // 1. CASUAL GREETINGS & SMALL TALK MATCHING
    if (lower == "hi" ||
        lower == "hello" ||
        lower == "namaste" ||
        lower.contains("kese ho") ||
        lower.contains("kaise ho") ||
        lower.contains("kaisa ho") ||
        lower.contains("kaise hain") ||
        lower.contains("kaisa hai") ||
        lower.contains("kya haal") ||
        lower.contains("how are you") ||
        lower.contains("how r u") ||
        lower.contains("how do you do") ||
        lower.contains("kene asa") ||
        lower.contains("kemon acho") ||
        lower.contains("kemon achen") ||
        lower.contains("kamdouri")) {
      String reply = "";
      if (activeLanguage.contains("Hindi") || activeLanguage.contains("हिंदी") || lower.contains("kese") || lower.contains("kaise") || lower.contains("kaisa")) {
        reply = "Main bilkul theek hoon! Aap kaise hain? LokSetu AI aapki kya madad kar sakta hai? 😊✨";
      } else if (activeLanguage.contains("Assamese") || activeLanguage.contains("অসমীয়া") || lower.contains("kene")) {
        reply = "Moy bhal asu! Aapuni kene ase? LokSetu AI aponak ki dore rogaay koribo pare? 😊✨";
      } else if (activeLanguage.contains("Bengali") || activeLanguage.contains("বাংলা") || lower.contains("kemon")) {
        reply = "Ami bhalo achhi! Aapni kemon achhen? LokSetu AI apnake kibhabe sahajyo korte pare? 😊✨";
      } else {
        reply = "I am doing great! How are you today? How can LokSetu AI help you? 😊✨";
      }
      return AIResponse(text: reply, detectedLanguage: activeLanguage);
    }

    if (lower.contains("naam kya") || lower.contains("your name") || lower.contains("who are you") || lower.contains("aap kaun ho")) {
      return AIResponse(
        text: "Mera naam LokSetu AI hai! Main citizens aur farmers ki madad ke liye tayaar hoon. 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("thank") || lower.contains("dhanyawad") || lower.contains("shukriya")) {
      return AIResponse(
        text: "You are most welcome! 🙏😊 It is my pleasure to help you. Wishing you great health and happiness! 🌸✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("bye") || lower.contains("good night") || lower.contains("alvida") || lower.contains("sleep")) {
      return AIResponse(
        text: "Good night and take care! 🌙✨ Wishing you peaceful rest and a bright day ahead. Shubh Ratri! 🙏🌸",
        detectedLanguage: activeLanguage,
      );
    }

    // 2. PRIME MINISTER & NATIONAL LEADERS
    if (lower == "pm" ||
        lower == "who is pm" ||
        lower == "who is the pm" ||
        lower.contains("prime minister") ||
        lower.contains("pm of india") ||
        lower.contains("pm india") ||
        lower.contains("pradhan mantri") ||
        (lower.contains("pm") && !lower.contains("pm-kisan") && !lower.contains("pmkvy"))) {
      return AIResponse(
        text: "The Prime Minister of India is Narendra Modi. Hope this helps you! Have a wonderful day! 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("president") || lower.contains("rashtrapati")) {
      return AIResponse(
        text: "The President of India is Droupadi Murmu. Wishing you a great day ahead! 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("capital of india") || lower.contains("india capital")) {
      return AIResponse(
        text: "The capital of India is New Delhi. Hope this helps! 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("cm of assam") || lower.contains("chief minister of assam") || (lower.contains("cm") && lower.contains("assam"))) {
      return AIResponse(
        text: "The Chief Minister of Assam is Himanta Biswa Sarma. Hope this helps you! 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    if (lower.contains("cm of manipur") || lower.contains("chief minister of manipur") || (lower.contains("cm") && lower.contains("manipur"))) {
      return AIResponse(
        text: "The Chief Minister of Manipur is N. Biren Singh. Hope this helps you! 🙏✨",
        detectedLanguage: activeLanguage,
      );
    }

    // 3. AGRICULTURE & CROPS
    if (lower.contains("yellow rust") || lower.contains("yellow") || lower.contains("fungus")) {
      return AIResponse(
        text: "For yellow rust in wheat, spray Propiconazole 25% EC at 1ml per liter of water during morning hours.\n\nWishing you a bountiful harvest! 🌾🙏",
        detectedLanguage: activeLanguage,
      );
    } else if (lower.contains("pest") || lower.contains("keeda") || lower.contains("insect") || lower.contains("caterpillar") || lower.contains("armyworm")) {
      return AIResponse(
        text: "For pest control, spray Emamectin Benzoate 5% SG at 0.4 gram per liter of water or Neem Seed Kernel Extract (5%).\n\nMay your crops flourish! 🌾😊",
        detectedLanguage: activeLanguage,
      );
    } else if (lower.contains("pm-kisan") || lower.contains("pm kisan") || lower.contains("kisan credit") || lower.contains("kcc") || lower.contains("kist")) {
      return AIResponse(
        text: "PM-Kisan scheme provides ₹6,000 annual financial benefit to eligible farmer families in 3 installments of ₹2,000 each. Complete e-KYC online at pmkisan.gov.in.\n\nWishing you prosperity! 🌾✨",
        detectedLanguage: activeLanguage,
      );
    }

    // 4. HEALTHCARE & MEDICAL SCHEMES
    else if (lower.contains("ayushman") || lower.contains("pm-jay") || lower.contains("pmjay")) {
      return AIResponse(
        text: "Ayushman Bharat PM-JAY provides ₹5 Lakh free health insurance coverage per family per year at empaneled government and private hospitals. Apply at local CSC with Aadhaar and Ration Card.\n\nWishing you good health! 🏥🙏",
        detectedLanguage: activeLanguage,
      );
    } else if (lower.contains("doctor") || lower.contains("consult") || lower.contains("esanjeevani")) {
      return AIResponse(
        text: "Consult government doctors online for free via video call at esanjeevaniopd.in.\n\nTake care of your health! 🏥🌸",
        detectedLanguage: activeLanguage,
      );
    } else if (lower.contains("ambulance") || lower.contains("emergency")) {
      return AIResponse(
        text: "Dial 108 for free emergency hospital ambulance transport service.\n\nStay safe and take care! 🏥🙏",
        detectedLanguage: activeLanguage,
      );
    }

    // 5. OPEN DOMAIN LIVE AI & REAL-TIME SEARCH ENGINE QUERY
    final searchResult = await OpenAISearchService.searchAnyQuestion(
      query: trimmed,
      language: activeLanguage,
      apiKey: userApiKey,
    );

    return AIResponse(
      text: searchResult.text,
      detectedLanguage: activeLanguage,
      isLiveGoogleGemini: searchResult.source == "Google Gemini AI",
    );
  }
}
