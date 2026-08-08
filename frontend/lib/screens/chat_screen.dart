import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/elevenlabs_service.dart';
import '../services/language_detector.dart';
import '../services/farmer_knowledge_base.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final ElevenLabsService _speechService = ElevenLabsService();

  bool _isListening = false;
  bool _speechAvailable = false;
  String? _currentlySpeakingId;

  String _selectedLanguage = "English";

  final Map<String, String> _languages = {
    "English": "en-IN",
    "Hindi": "hi-IN",
    "Bengali": "bn-IN",
    "Assamese": "as-IN",
    "Manipuri": "mni-IN",
  };

  final List<Map<String, String>> _messages = [
    {
      "id": "init_chat",
      "sender": "ai",
      "text":
          "Namaste! 👋 I am LokSetu Multilingual AI.\n\nPress the mic button and speak in any language — I will auto-detect your language and answer your queries.",
    },
  ];

  final List<Map<String, String>> _globalPresets = [
    {
      "category": "Agriculture",
      "query": "Pest & Insects Control / PM-Kisan status",
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

        // AUTO-DETECT USER SPOKEN LANGUAGE
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
      });
      _messages.add({
        "id": "${msgId}_ai",
        "sender": "ai",
        "text": preset["answer"]!,
      });
    });

    _scrollToBottom();
    await _speak("${msgId}_ai", preset["answer"]!);
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    // AUTO-DETECT LANGUAGE
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
      });
      _controller.clear();
    });

    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final response = _getDemoResponse(message);
    final aiMsgId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _messages.add({
        "id": "${aiMsgId}_ai",
        "sender": "ai",
        "text": response,
      });
    });

    _scrollToBottom();
    await _speak("${aiMsgId}_ai", response);
  }

  String _getDemoResponse(String message) {
    final text = message.toLowerCase();

    if (text.contains("farmer") ||
        text.contains("crop") ||
        text.contains("agriculture") ||
        text.contains("kisan") ||
        text.contains("pest") ||
        text.contains("soil") ||
        text.contains("keeda") ||
        text.contains("fasal")) {
      return FarmerKnowledgeBase.getAccurateFarmerAnswer(message, "Agriculture");
    }

    if (text.contains("scholarship") ||
        text.contains("education") ||
        text.contains("school")) {
      return "Education & Scholarships 🎓\n\n1. Register on scholarships.gov.in for government post-matric stipends.\n2. Free PMKVY Skill courses with job assistance available.";
    }

    if (text.contains("hospital") ||
        text.contains("doctor") ||
        text.contains("health") ||
        text.contains("ayushman")) {
      return "Healthcare Assistance 🏥\n\n1. Apply for Ayushman Bharat PM-JAY Card for ₹5 Lakh health coverage.\n2. Get free doctor consultation on eSanjeevani portal at esanjeevaniopd.in.";
    }

    if (text.contains("government") ||
        text.contains("scheme") ||
        text.contains("ration") ||
        text.contains("certificate")) {
      return "Governance & Schemes 🏛️\n\n1. Apply for Certificates at your state e-District portal.\n2. Complete Ration Card e-KYC at your nearest FPS dealer.";
    }

    return FarmerKnowledgeBase.getAccurateFarmerAnswer(message, "General");
  }

  Future<void> _speak(String id, String text) async {
    if (_currentlySpeakingId == id) {
      await _speechService.stop();
      setState(() {
        _currentlySpeakingId = null;
      });
      return;
    }

    final localeId = _languages[_selectedLanguage] ?? "en-IN";

    await _speechService.speak(
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
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue,
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            SizedBox(width: 10),
            Text("LokSetu AI Voice Chatbot"),
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
                child: Text(language, style: const TextStyle(fontSize: 13)),
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
                    label: const Text("Other..."),
                    backgroundColor: Colors.grey.shade200,
                    onPressed: () {
                      _showMessage("Speak in your native language or type below.");
                    },
                  ),
                ],
              ),
            ),
          ),

          // CHAT MESSAGES
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
                      maxWidth: MediaQuery.of(context).size.width * 0.80,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
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
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isSpeaking
                                      ? Icons.stop_circle
                                      : Icons.volume_up,
                                  color: isSpeaking ? Colors.red : Colors.blue,
                                  size: 20,
                                ),
                                tooltip: "Listen Natural Voice ($_selectedLanguage)",
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

          // INPUT BAR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: "micButton",
                    mini: true,
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                    onPressed: _startListening,
                    tooltip: "Auto-Detect Language Mic",
                    child: Icon(_isListening ? Icons.stop : Icons.mic),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? "Listening (Auto-Detecting Language)..."
                            : "Speak in any language or type...",
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
    _speech.stop();
    _speechService.stop();
    super.dispose();
  }
}