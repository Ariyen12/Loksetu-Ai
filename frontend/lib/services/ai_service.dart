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
  /// Simple, direct, short answers without additional links
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

    // 2. SIMPLE DIRECT ACCURATE ANSWER
    return _generateSimpleShortAnswer(query, lower, currentCategory, activeLanguage);
  }

  static AIResponse _generateSimpleShortAnswer(
    String originalQuery,
    String lower,
    String category,
    String lang,
  ) {
    String answer = "";

    // GREETINGS & BASIC DIALOGUE
    if (lower == "hi" || lower == "hello" || lower == "namaste" || lower.contains("who are you")) {
      answer = "Namaste! I am LokSetu AI.\n\n"
          "I am here to help citizens and farmers with Agriculture, Healthcare, Governance, and Education.\n"
          "How can I help you today?";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    if (lower.contains("loksetu") || lower.contains("what is this app")) {
      answer = "LokSetu AI is a simple multilingual voice assistant for citizens and farmers across India.";
      return AIResponse(text: answer, detectedLanguage: lang);
    }

    // 🌾 AGRICULTURE & CROPS
    if (lower.contains("farm") ||
        lower.contains("crop") ||
        lower.contains("pest") ||
        lower.contains("soil") ||
        lower.contains("fertilizer") ||
        lower.contains("kisan") ||
        lower.contains("urea") ||
        lower.contains("dap") ||
        lower.contains("keeda") ||
        lower.contains("fasal") ||
        lower.contains("yellow") ||
        lower.contains("fungus") ||
        lower.contains("rice") ||
        lower.contains("paddy") ||
        lower.contains("wheat")) {
      answer = "🌾 Agriculture & Crop Guide:\n\n"
          "• Pest & Insect Remedy: Spray Neem Oil (5ml per liter of water) or Propiconazole (1ml per liter).\n"
          "• PM-Kisan Scheme: Check your ₹6,000 yearly benefit on pmkisan.gov.in.\n"
          "• Kisan Helpline: Dial toll-free 1800-180-1551 for free guidance.";
    }
    // 🏥 HEALTHCARE & MEDICAL
    else if (lower.contains("health") ||
        lower.contains("hospital") ||
        lower.contains("doctor") ||
        lower.contains("ayushman") ||
        lower.contains("medicine") ||
        lower.contains("fever") ||
        lower.contains("emergency")) {
      answer = "🏥 Healthcare Guidance:\n\n"
          "• Emergency Ambulance: Dial 108 for free hospital transport.\n"
          "• Free Doctor Consultation: Consult online at esanjeevaniopd.in.\n"
          "• Ayushman Card: ₹5 Lakh free health coverage per family at government hospitals.";
    }
    // 🏛️ GOVERNANCE & CERTIFICATES
    else if (lower.contains("gov") ||
        lower.contains("scheme") ||
        lower.contains("certificate") ||
        lower.contains("income") ||
        lower.contains("caste") ||
        lower.contains("ration") ||
        lower.contains("aadhaar") ||
        lower.contains("pension")) {
      answer = "🏛️ Governance & Certificates:\n\n"
          "• Certificates: Apply for Income, Caste, or Residence certificates at your state e-District portal or CSC center.\n"
          "• Ration Card e-KYC: Complete Aadhaar fingerprint link at your local ration dealer.\n"
          "• Public Grievances: File complaints online at pgportal.gov.in.";
    }
    // 🎓 EDUCATION & SCHOLARSHIPS
    else if (lower.contains("school") ||
        lower.contains("college") ||
        lower.contains("education") ||
        lower.contains("scholarship") ||
        lower.contains("course") ||
        lower.contains("skill")) {
      answer = "🎓 Education & Scholarships:\n\n"
          "• National Scholarships: Apply for student stipends at scholarships.gov.in.\n"
          "• Free Skill Training: Enroll in PMKVY certified skill courses at local training centers.\n"
          "• School Admissions: 25% free private school seats reserved under RTE Act.";
    }
    // 🌐 GENERAL KNOWLEDGE & OPEN DOMAIN
    else {
      answer = "🌐 Answer for '$originalQuery':\n\n"
          "LokSetu AI has processed your question. Ask any specific question in your language for direct guidance.";
    }

    return AIResponse(
      text: answer,
      detectedLanguage: lang,
    );
  }
}
