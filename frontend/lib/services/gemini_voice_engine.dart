import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class GeminiVoiceEngine {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  /// Speaks text with Gemini-style natural voice quality and clear human cadence
  Future<void> speak({
    required String text,
    required String localeId,
    required VoidCallback onStart,
    required VoidCallback onComplete,
  }) async {
    await stop();
    _isSpeaking = true;
    onStart();

    if (kIsWeb) {
      try {
        js.context['LokSetuVoiceEngine'].callMethod('speakText', [text, localeId]);
        return;
      } catch (e) {
        debugPrint("Web JS Voice engine fallback to Flutter TTS: $e");
      }
    }

    // High quality mobile/system fallback
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete();
    });

    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      onComplete();
    });

    await _tts.speak(text);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    if (kIsWeb) {
      try {
        js.context['LokSetuVoiceEngine'].callMethod('stopSpeech');
      } catch (_) {}
    }
    await _tts.stop();
  }
}
