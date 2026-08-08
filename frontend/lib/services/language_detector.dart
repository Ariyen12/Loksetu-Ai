class LanguageDetectionResult {
  final String languageName;
  final String localeId;
  final String scriptCode;

  const LanguageDetectionResult({
    required this.languageName,
    required this.localeId,
    required this.scriptCode,
  });
}

class LanguageDetector {
  /// Expanded Language Registry covering Northeast India & National Languages
  static const Map<String, String> supportedLanguages = {
    "Assamese (অসমীয়া)": "as-IN",
    "Manipuri (মৈৈতৈলোন)": "mni-IN",
    "Bengali (বাংলা)": "bn-IN",
    "Bodo (बर')": "brx-IN",
    "Nepali (नेपाली)": "ne-IN",
    "Hindi (हिंदी)": "hi-IN",
    "English": "en-IN",
    "Khasi (Meghalaya)": "en-IN",
    "Garo (Meghalaya)": "en-IN",
    "Mizo (Mizoram)": "en-IN",
    "Nagamese (Nagaland)": "en-IN",
  };

  /// Auto-detects spoken language from text script, character ranges, and phonetic terms
  static LanguageDetectionResult detect(String text) {
    if (text.trim().isEmpty) {
      return const LanguageDetectionResult(
        languageName: "English",
        localeId: "en-IN",
        scriptCode: "Latn",
      );
    }

    final trimmed = text.trim();

    // 1. Devanagari script (Hindi, Bodo, Nepali)
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(trimmed);
    if (hasDevanagari) {
      if (trimmed.contains('बर') || trimmed.contains('राव')) {
        return const LanguageDetectionResult(
          languageName: "Bodo (बर')",
          localeId: "brx-IN",
          scriptCode: "Deva",
        );
      }
      if (trimmed.contains('छ' ) || trimmed.contains('नेपाल')) {
        return const LanguageDetectionResult(
          languageName: "Nepali (नेपाली)",
          localeId: "ne-IN",
          scriptCode: "Deva",
        );
      }
      return const LanguageDetectionResult(
        languageName: "Hindi (हिंदी)",
        localeId: "hi-IN",
        scriptCode: "Deva",
      );
    }

    // 2. Bengali & Assamese script
    final hasBengaliAssamese = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed);
    if (hasBengaliAssamese) {
      if (trimmed.contains('ৱ') ||
          trimmed.contains('ৰ') ||
          trimmed.contains('কৈ') ||
          trimmed.contains('অসম') ||
          trimmed.contains('লাগে')) {
        return const LanguageDetectionResult(
          languageName: "Assamese (অসমীয়া)",
          localeId: "as-IN",
          scriptCode: "Beng",
        );
      }
      return const LanguageDetectionResult(
        languageName: "Bengali (বাংলা)",
        localeId: "bn-IN",
        scriptCode: "Beng",
      );
    }

    // 3. Meetei Mayek script (Manipuri)
    final hasManipuri = RegExp(r'[\uABC0-\uABFF]').hasMatch(trimmed);
    if (hasManipuri) {
      return const LanguageDetectionResult(
        languageName: "Manipuri (মৈৈতৈলোন)",
        localeId: "mni-IN",
        scriptCode: "Mtei",
      );
    }

    // 4. Phonetic & Romanized Northeast & Indian Language Keywords
    final lower = trimmed.toLowerCase();

    // Assamese Phonetics
    if (lower.contains("kheti") ||
        lower.contains("asomiya") ||
        lower.contains("laage") ||
        lower.contains("dorkar") ||
        lower.contains("dhan") ||
        lower.contains("kela")) {
      return const LanguageDetectionResult(
        languageName: "Assamese (অসমীয়া)",
        localeId: "as-IN",
        scriptCode: "Beng",
      );
    }

    // Manipuri Phonetics
    if (lower.contains("meitei") ||
        lower.contains("manipuri") ||
        lower.contains("shumang") ||
        lower.contains("yamna")) {
      return const LanguageDetectionResult(
        languageName: "Manipuri (মৈৈতৈলোন)",
        localeId: "mni-IN",
        scriptCode: "Mtei",
      );
    }

    // Bengali Phonetics
    if (lower.contains("chash") ||
        lower.contains("shasya") ||
        lower.contains("khad") ||
        lower.contains("amader") ||
        lower.contains("jonno")) {
      return const LanguageDetectionResult(
        languageName: "Bengali (বাংলা)",
        localeId: "bn-IN",
        scriptCode: "Beng",
      );
    }

    // Hindi Phonetics
    if (lower.contains("kisan") ||
        lower.contains("fasal") ||
        lower.contains("yojana") ||
        lower.contains("namaste") ||
        lower.contains("kaise") ||
        lower.contains("madad") ||
        lower.contains("bhai")) {
      return const LanguageDetectionResult(
        languageName: "Hindi (हिंदी)",
        localeId: "hi-IN",
        scriptCode: "Deva",
      );
    }

    // Default Fallback
    return const LanguageDetectionResult(
      languageName: "English",
      localeId: "en-IN",
      scriptCode: "Latn",
    );
  }
}
