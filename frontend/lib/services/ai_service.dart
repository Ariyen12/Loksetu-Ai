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
  /// Provides EXACT, POINT-BLANK answers with zero preambles, intros, or headers
  static Future<AIResponse> getAnswer({
    required String query,
    required String currentCategory,
    required String activeLanguage,
    String? userApiKey,
  }) async {
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    // 1. TRY LIVE GOOGLE GEMINI API FIRST
    final liveGemini = await GeminiAPIService.queryGoogleGeminiAPI(
      prompt: trimmed,
      language: activeLanguage,
      apiKey: userApiKey,
    );

    if (liveGemini != null) {
      return AIResponse(
        text: liveGemini.text,
        detectedLanguage: activeLanguage,
        isLiveGoogleGemini: true,
      );
    }

    // 2. EXACT POINT-BLANK DIRECT ANSWERS (NO "COMPREHENSIVE FACTUAL ANALYSIS" OR HEADERS)
    return _generateExactAnswer(query, lower, currentCategory, activeLanguage);
  }

  static AIResponse _generateExactAnswer(
    String originalQuery,
    String lower,
    String category,
    String lang,
  ) {
    String answer = "";

    // GREETINGS
    if (lower == "hi" || lower == "hello" || lower == "namaste" || lower.contains("who are you")) {
      answer = "Namaste! I am LokSetu AI. Ask me any question for a direct answer.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("loksetu") || lower.contains("what is this app")) {
      answer = "LokSetu AI is a multilingual assistant for citizens and farmers providing direct government scheme and farming answers.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    // 👑 POPULAR GENERAL KNOWLEDGE & NATIONAL QUERIES
    if (lower.contains("pm of india") || lower.contains("prime minister of india") || lower.contains("pm india") || lower.contains("pradhan mantri")) {
      answer = "The Prime Minister of India is Narendra Modi.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("president of india") || lower.contains("rashtrapati")) {
      answer = "The President of India is Droupadi Murmu.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("capital of india") || lower.contains("india capital")) {
      answer = "The capital of India is New Delhi.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("cm of assam") || lower.contains("chief minister of assam")) {
      answer = "The Chief Minister of Assam is Himanta Biswa Sarma.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("cm of manipur") || lower.contains("chief minister of manipur")) {
      answer = "The Chief Minister of Manipur is N. Biren Singh.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    // 🌾 AGRICULTURE & PEST REMEDIES (DIRECT POINT-BLANK)
    if (lower.contains("yellow rust") || lower.contains("yellow") || lower.contains("fungus")) {
      answer = "Spray Propiconazole 25% EC at 1ml per liter of water during morning hours.";
    } else if (lower.contains("pest") || lower.contains("keeda") || lower.contains("insect") || lower.contains("caterpillar")) {
      answer = "Spray Emamectin Benzoate 5% SG at 0.4 gram per liter of water or Neem Seed Kernel Extract 5%.";
    } else if (lower.contains("pm-kisan") || lower.contains("kisan credit") || lower.contains("kcc") || lower.contains("kist")) {
      answer = "Check your PM-Kisan ₹6,000 yearly benefit and complete e-KYC online at pmkisan.gov.in.";
    } else if (lower.contains("urea") || lower.contains("dap") || lower.contains("fertilizer")) {
      answer = "Apply Neem Coated Urea and DAP based on soil testing from your local Krishi Vigyan Kendra (KVK).";
    } else if (lower.contains("farm") || lower.contains("crop") || lower.contains("soil") || lower.contains("rice") || lower.contains("paddy") || lower.contains("wheat")) {
      answer = "For crop protection, spray Neem Oil 5ml/L. Dial Kisan Call Center toll-free at 1800-180-1551 for free advisory.";
    }

    // 🏥 HEALTHCARE & MEDICAL (DIRECT POINT-BLANK)
    else if (lower.contains("ayushman") || lower.contains("card")) {
      answer = "Ayushman Bharat PM-JAY provides ₹5 Lakh free health coverage per family at government hospitals. Apply at local CSC with Aadhaar and Ration Card.";
    } else if (lower.contains("doctor") || lower.contains("consult") || lower.contains("esanjeevani")) {
      answer = "Consult government doctors online for free at esanjeevaniopd.in.";
    } else if (lower.contains("ambulance") || lower.contains("emergency") || lower.contains("fever") || lower.contains("health") || lower.contains("hospital")) {
      answer = "Call 108 for free emergency hospital ambulance service.";
    }

    // 🏛️ GOVERNANCE & CERTIFICATES (DIRECT POINT-BLANK)
    else if (lower.contains("income") || lower.contains("caste") || lower.contains("certificate") || lower.contains("residence")) {
      answer = "Apply for Income, Caste, or Residence certificates online at your state e-District portal or local CSC center.";
    } else if (lower.contains("ration") || lower.contains("kyc")) {
      answer = "Complete your Ration Card e-KYC fingerprint link at your nearest Fair Price Shop dealer.";
    } else if (lower.contains("scheme") || lower.contains("gov") || lower.contains("aadhaar") || lower.contains("pension")) {
      answer = "Check scheme eligibility and submit applications online at services.india.gov.in.";
    }

    // 🎓 EDUCATION & SCHOLARSHIPS (DIRECT POINT-BLANK)
    else if (lower.contains("scholarship") || lower.contains("stipend") || lower.contains("nsp")) {
      answer = "Apply for Pre-Matric and Post-Matric scholarships on the National Scholarship Portal at scholarships.gov.in.";
    } else if (lower.contains("skill") || lower.contains("pmkvy") || lower.contains("course")) {
      answer = "Enroll in free PMKVY skill training courses at pmkvyofficial.org.";
    } else if (lower.contains("school") || lower.contains("college") || lower.contains("education") || lower.contains("rte")) {
      answer = "25% of private school seats are reserved free for underprivileged students under the RTE Act.";
    }

    // 🌐 GENERAL KNOWLEDGE & OPEN-DOMAIN (NO FILLER / NO HEADERS)
    else {
      answer = "Answer for '$originalQuery': Information for $originalQuery is available on government and regional portals. Ask any specific question for instant details.";
    }

    return AIResponse(
      text: answer,
      detectedLanguage: lang,
    );
  }
}
