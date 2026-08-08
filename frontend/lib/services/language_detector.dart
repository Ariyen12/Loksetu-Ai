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
  /// Auto-detects language from recognized speech text or script ranges
  static LanguageDetectionResult detect(String text) {
    if (text.trim().isEmpty) {
      return const LanguageDetectionResult(
        languageName: "English",
        localeId: "en-IN",
        scriptCode: "Latn",
      );
    }

    final trimmed = text.trim();

    // Devanagari script (Hindi, Marathi, etc.)
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(trimmed);
    if (hasDevanagari) {
      return const LanguageDetectionResult(
        languageName: "Hindi",
        localeId: "hi-IN",
        scriptCode: "Deva",
      );
    }

    // Bengali & Assamese script
    final hasBengaliAssamese = RegExp(r'[\u0980-\u09FF]').hasMatch(trimmed);
    if (hasBengaliAssamese) {
      // Check specific Assamese characters (e.g. ৱ, ৰ)
      if (trimmed.contains('ৱ') || trimmed.contains('ৰ') || trimmed.contains('কৈ')) {
        return const LanguageDetectionResult(
          languageName: "Assamese",
          localeId: "as-IN",
          scriptCode: "Beng",
        );
      }
      return const LanguageDetectionResult(
        languageName: "Bengali",
        localeId: "bn-IN",
        scriptCode: "Beng",
      );
    }

    // Meetei Mayek script (Manipuri)
    final hasManipuri = RegExp(r'[\uABC0-\uABFF]').hasMatch(trimmed);
    if (hasManipuri) {
      return const LanguageDetectionResult(
        languageName: "Manipuri",
        localeId: "mni-IN",
        scriptCode: "Mtei",
      );
    }

    // Check romanized Hindi/Bengali/Assamese keywords spoken in English script
    final lower = trimmed.toLowerCase();
    if (lower.contains("kheti") ||
        lower.contains("kisan") ||
        lower.contains("fasal") ||
        lower.contains("yojana") ||
        lower.contains("namaste") ||
        lower.contains("kaise") ||
        lower.contains("madad")) {
      return const LanguageDetectionResult(
        languageName: "Hindi",
        localeId: "hi-IN",
        scriptCode: "Deva",
      );
    }

    if (lower.contains("krishi") ||
        lower.contains("chash") ||
        lower.contains("dhan") ||
        lower.contains("shasya") ||
        lower.contains("sarkar")) {
      return const LanguageDetectionResult(
        languageName: "Bengali",
        localeId: "bn-IN",
        scriptCode: "Beng",
      );
    }

    if (lower.contains("kheti") ||
        lower.contains("kheti-baati") ||
        lower.contains("sarkari")) {
      return const LanguageDetectionResult(
        languageName: "Assamese",
        localeId: "as-IN",
        scriptCode: "Beng",
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
