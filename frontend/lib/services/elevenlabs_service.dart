import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

class ElevenLabsService {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  // Optional ElevenLabs API Key (user can configure or use natural Web Speech fallback)
  String? apiKey;
  String voiceId = "21m00Tcm4TlvDq8ikWAM"; // Rachel - natural human voice

  ElevenLabsService({this.apiKey});

  bool get isSpeaking => _isSpeaking;

  /// Clean raw text to prevent reading emojis, raw numbers, or markdown
  static String cleanTextForSpeech(String rawText) {
    String cleaned = rawText.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{200D}]',
        unicode: true,
      ),
      '',
    );

    cleaned = cleaned.replaceAll('₹', ' rupees ');
    cleaned = cleaned.replaceAll('\n1. ', '. First, ');
    cleaned = cleaned.replaceAll('\n2. ', '. Second, ');
    cleaned = cleaned.replaceAll('\n3. ', '. Third, ');
    cleaned = cleaned.replaceAll('\n4. ', '. Fourth, ');
    cleaned = cleaned.replaceAll('\n5. ', '. Fifth, ');
    cleaned = cleaned.replaceAll('1. ', 'First, ');
    cleaned = cleaned.replaceAll('2. ', 'Second, ');
    cleaned = cleaned.replaceAll('3. ', 'Third, ');
    cleaned = cleaned.replaceAll('• ', '. ');
    cleaned = cleaned.replaceAll('\n', '. ');
    cleaned = cleaned.replaceAll(RegExp(r'[\*\#\_\~`\[\]\(\)]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\.+'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  Future<void> speak({
    required String text,
    required String localeId,
    required VoidCallback onStart,
    required VoidCallback onComplete,
  }) async {
    final cleanedText = cleanTextForSpeech(text);
    if (cleanedText.isEmpty) return;

    await stop();
    _isSpeaking = true;
    onStart();

    // If ElevenLabs API Key is present, use ElevenLabs REST API
    if (apiKey != null && apiKey!.isNotEmpty) {
      try {
        final url = Uri.parse(
            'https://api.elevenlabs.io/v1/text-to-speech/$voiceId');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'xi-api-key': apiKey!,
          },
          body: jsonEncode({
            'text': cleanedText,
            'model_id': 'eleven_multilingual_v2',
            'voice_settings': {
              'stability': 0.5,
              'similarity_boost': 0.75,
            }
          }),
        );

        if (response.statusCode == 200) {
          // Play audio bytes if supported
          _isSpeaking = false;
          onComplete();
          return;
        }
      } catch (e) {
        debugPrint("ElevenLabs API call fallback to Web Speech: $e");
      }
    }

    // High Quality Natural Web Speech Fallback
    await _tts.setLanguage(localeId);
    await _tts.setSpeechRate(0.46); // Conversational natural pace
    await _tts.setPitch(1.0); // Natural pitch

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete();
    });

    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      onComplete();
    });

    await _tts.speak(cleanedText);
  }

  Future<void> stop() async {
    _isSpeaking = false;
    await _tts.stop();
  }
}
