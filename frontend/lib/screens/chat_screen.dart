import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/gemini_voice_engine.dart';
import '../services/language_detector.dart';
import '../services/ai_service.dart';
import '../services/gemini_api_service.dart';
import '../widgets/loksetu_logo_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiVoiceEngine _speechEngine = GeminiVoiceEngine();

  late AnimationController _micPulseController;
  late Animation<double> _micPulseAnimation;

  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentlySpeakingId;

  String _selectedLanguage = "Assamese (অসমীয়া)";

  final Map<String, String> _languages = LanguageDetector.supportedLanguages;

  final List<Map<String, dynamic>> _messages = [
    {
      "id": "init_chat",
      "sender": "ai",
      "text":
          "Namaste! 👋 I am LokSetu Voice AI.\n\nPick your language below or press the mic button to speak. I am ready to answer your questions simply and clearly.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = GeminiAPIService.userApiKey;

    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _micPulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _micPulseController, curve: Curves.easeInOut),
    );

    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
    } catch (_) {
      _speechAvailable = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showGeminiApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue),
              SizedBox(width: 8),
              Text("Google Gemini API"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your Google Gemini API Key for live AI responses:",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  hintText: "AIzaSy...",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                GeminiAPIService.userApiKey = _apiKeyController.text.trim();
                Navigator.pop(context);
                _showMessage("Google Gemini API Key Saved!");
              },
              child: const Text("Save Key"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage("Microphone unavailable. Check browser permissions.");
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final localeId = _languages[_selectedLanguage] ?? "as-IN";

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      localeId: localeId,
      onResult: (result) {
        if (!mounted) return;

        final recognized = result.recognizedWords;
        setState(() {
          _controller.text = recognized;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

        if (recognized.isNotEmpty) {
          final detected = LanguageDetector.detect(recognized);
          if (detected.languageName != _selectedLanguage) {
            setState(() {
              _selectedLanguage = detected.languageName;
            });
          }
        }

        if (result.finalResult) {
          _sendMessage();
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${userMsgId}_u",
        "sender": "user",
        "text": message,
      });
      _controller.clear();
    });

    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    final aiResult = await LokSetuAIService.getAnswer(
      query: message,
      currentCategory: "General",
      activeLanguage: _selectedLanguage,
      userApiKey: GeminiAPIService.userApiKey,
    );

    final aiMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${aiMsgId}_ai",
        "sender": "ai",
        "text": aiResult.text,
      });
    });

    _scrollToBottom();
    await _speak("${aiMsgId}_ai", aiResult.text);
  }

  Future<void> _speak(String id, String text) async {
    if (_currentlySpeakingId == id) {
      await _speechEngine.stop();
      setState(() {
        _currentlySpeakingId = null;
      });
      return;
    }

    final localeId = _languages[_selectedLanguage] ?? "as-IN";

    await _speechEngine.speak(
      text: text,
      localeId: localeId,
      onStart: () {
        if (mounted) {
          setState(() {
            _currentlySpeakingId = id;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _currentlySpeakingId = null;
          });
        }
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const ClipOval(
              child: LokSetuLogoWidget(
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text("LokSetu AI Voice Chatbot"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key, color: Colors.blue),
            tooltip: "Connect Google Gemini API Key",
            onPressed: _showGeminiApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1-TAP LANGUAGE SELECTION BAR
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    const Text(
                      "Select Speaking Language:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedLanguage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _languages.keys.map((langKey) {
                      final isSel = _selectedLanguage == langKey;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            langKey,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              color: isSel ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: Colors.blue.shade600,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedLanguage = langKey;
                              });
                              _showMessage("Language set to $langKey");
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // CLEAN CHAT MESSAGES
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["sender"] == "user";
                final msgId = message["id"] ?? index.toString();
                final isSpeaking = _currentlySpeakingId == msgId;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.84,
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade600 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message["text"] ?? "",
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),

                        // LISTEN BUTTON
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSpeaking
                                      ? Colors.red
                                      : Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  isSpeaking
                                      ? Icons.stop_circle
                                      : Icons.volume_up,
                                  size: 16,
                                ),
                                label: Text(
                                  isSpeaking ? "Stop" : "Listen",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () =>
                                    _speak(msgId, message["text"] ?? ""),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ANIMATED MIC BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _isListening
                        ? _micPulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: _isListening
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.6),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: FloatingActionButton(
                        heroTag: "micButton",
                        mini: true,
                        backgroundColor:
                            _isListening ? Colors.red : Colors.blue,
                        onPressed: _startListening,
                        tooltip: "Listen Mic",
                        child: Icon(_isListening ? Icons.graphic_eq : Icons.mic),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? "Listening in $_selectedLanguage..."
                            : "Ask ANY question in $_selectedLanguage...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: "sendButton",
                    mini: true,
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _apiKeyController.dispose();
    _scrollController.dispose();
    _micPulseController.dispose();
    _speech.stop();
    _speechEngine.stop();
    super.dispose();
  }
}