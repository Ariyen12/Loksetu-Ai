import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/gemini_voice_engine.dart';
import '../services/language_detector.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final GeminiVoiceEngine _speechEngine = GeminiVoiceEngine();

  late AnimationController _micPulseController;
  late Animation<double> _micPulseAnimation;

  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentlySpeakingId;

  String _selectedLanguage = "English";

  final Map<String, String> _languages = LanguageDetector.supportedLanguages;

  final List<Map<String, dynamic>> _messages = [
    {
      "id": "init_chat",
      "sender": "ai",
      "text":
          "Namaste! 👋 I am LokSetu Multilingual AI Assistant.\n\nPress the mic button and speak in any language (Assamese, Manipuri, Bengali, Bodo, Nepali, Hindi, English). I will auto-detect your language and answer with high-accuracy detail.",
      "links": <String>[],
    },
  ];

  final List<Map<String, String>> _globalPresets = [
    {
      "category": "Agriculture",
      "query": "Pest & Crop Disease Control / PM-Kisan",
      "answer":
          "PM-Kisan & Pest Advisory:\n1. For Yellow Rust / Pests: Spray Neem Oil (5ml/L) or Emamectin Benzoate (0.4g/L).\n2. For PM-Kisan: Check pmkisan.gov.in & ensure Aadhaar e-KYC is linked.\n3. Kisan Helpline: Dial toll-free 1800-180-1551 for free guidance."
    },
    {
      "category": "Healthcare",
      "query": "Ayushman Bharat Card & Teleconsultation",
      "answer":
          "Healthcare Support:\n1. Apply for Ayushman Bharat PM-JAY Card for ₹5 Lakh free health coverage per family.\n2. Free Doctor Consultations: Register at esanjeevaniopd.in.\n3. Ambulance: Call 108 for emergency hospital transport."
    },
    {
      "category": "Governance",
      "query": "Income / Caste Certificate & e-District",
      "answer":
          "Government Services:\n1. Apply for Certificates online at state e-District portal or local CSC center.\n2. Link Aadhaar with Ration Card at your local Fair Price Shop dealer."
    },
    {
      "category": "Education",
      "query": "Post-Matric Scholarships & Skill Training",
      "answer":
          "Education & Skills:\n1. National Scholarship Portal: Apply at scholarships.gov.in.\n2. Free PMKVY Skill Courses: Enroll at local centers with job placement support."
    },
  ];

  @override
  void initState() {
    super.initState();
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

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage("Microphone unavailable or browser permission denied.");
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
      });
      return;
    }

    final localeId = _languages[_selectedLanguage] ?? "en-IN";

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
            _showMessage("Auto-Detected Language: ${detected.languageName}");
          }
        }

        if (result.finalResult) {
          _sendMessage();
        }
      },
    );
  }

  Future<void> _selectPreset(Map<String, String> preset) async {
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${msgId}_u",
        "sender": "user",
        "text": preset["query"]!,
        "links": <String>[],
      });
      _messages.add({
        "id": "${msgId}_ai",
        "sender": "ai",
        "text": preset["answer"]!,
        "links": [
          "https://gemini.google.com/search?q=${Uri.encodeComponent(preset['query']!)} (Gemini Research)",
          "https://services.india.gov.in (Official Govt Portal)"
        ],
      });
    });

    _scrollToBottom();
    await _speak("${msgId}_ai", preset["answer"]!);
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final detected = LanguageDetector.detect(message);
    if (detected.languageName != _selectedLanguage) {
      setState(() {
        _selectedLanguage = detected.languageName;
      });
    }

    final userMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${userMsgId}_u",
        "sender": "user",
        "text": message,
        "links": <String>[],
      });
      _controller.clear();
    });

    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final aiResult = await LokSetuAIService.getAnswer(
      query: message,
      currentCategory: "General",
      activeLanguage: _selectedLanguage,
    );

    final aiMsgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${aiMsgId}_ai",
        "sender": "ai",
        "text": aiResult.text,
        "links": aiResult.researchLinks,
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

    final localeId = _languages[_selectedLanguage] ?? "en-IN";

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

  void _launchUrl(String rawUrl) {
    final linkOnly = rawUrl.split(' ').first;
    try {
      js.context.callMethod('open', [linkOnly, '_blank']);
    } catch (_) {
      _showMessage("Opening: $linkOnly");
    }
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
            ClipOval(
              child: Image.asset(
                'assets/images/loksetu_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text("LokSetu AI Voice Chatbot"),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedLanguage,
            underline: const SizedBox(),
            icon: const Icon(Icons.translate, color: Colors.blue),
            items: _languages.keys.map((language) {
              return DropdownMenuItem(
                value: language,
                child: Text(language, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedLanguage = value;
              });
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // QUICK SUGGESTIONS STRIP
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._globalPresets.map((preset) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(preset["category"]![0],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                        label: Text(preset["query"]!,
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white,
                        onPressed: () => _selectPreset(preset),
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.more_horiz,
                          color: Colors.white, size: 14),
                    ),
                    label: const Text("Other (Ask ANY Question)..."),
                    backgroundColor: Colors.grey.shade200,
                    onPressed: () {
                      _showMessage("Ask ANY question in your language below.");
                    },
                  ),
                ],
              ),
            ),
          ),

          // CHAT MESSAGES WITH RESEARCH LINKS
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
                final List<String> links =
                    (message["links"] as List<dynamic>?)?.cast<String>() ?? [];

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
                      color: isUser ? Colors.blue.shade600 : Colors.grey.shade200,
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

                        // VERIFIED RESEARCH LINKS
                        if (!isUser && links.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.link_rounded,
                                  size: 14, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                "Gemini & Verified Research Links:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: links.map((link) {
                              return ActionChip(
                                avatar: const Icon(Icons.open_in_new,
                                    size: 12, color: Colors.blue),
                                label: Text(
                                  link.replaceAll(RegExp(r'https?://'), ''),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: Colors.blue.shade50,
                                onPressed: () => _launchUrl(link),
                              );
                            }).toList(),
                          ),
                        ],

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

          // GEMINI-STYLE ANIMATED MIC INPUT BAR
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
                        tooltip: "Gemini Auto Voice Mic",
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
                            ? "Listening (Speak in ANY language)..."
                            : "Ask ANY question or speak...",
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
    _scrollController.dispose();
    _micPulseController.dispose();
    _speech.stop();
    _speechEngine.stop();
    super.dispose();
  }
}