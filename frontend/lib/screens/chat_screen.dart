import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

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
          "Namaste! 👋 I am LokSetu AI Assistant.\n\nPick one of the top preset suggestions below, or press the microphone icon to speak in your language.",
    },
  ];

  final List<Map<String, String>> _globalPresets = [
    {
      "category": "Healthcare",
      "query": "Ayushman Bharat Card (PM-JAY) application",
      "answer":
          "Ayushman Bharat (PM-JAY):\n1. Visit nearest CSC or empaneled hospital with Aadhaar & Ration Card.\n2. Get up to ₹5 Lakh free health coverage per family per year."
    },
    {
      "category": "Governance",
      "query": "Apply for Income / Caste Certificate",
      "answer":
          "Apply at your state e-District portal or local CSC center with Aadhaar card, address proof, and income details."
    },
    {
      "category": "Education",
      "query": "Post-Matric Scholarships application",
      "answer":
          "Register on National Scholarship Portal (scholarships.gov.in) with Aadhaar and bank details for direct scholarship credit."
    },
    {
      "category": "Agriculture",
      "query": "PM-Kisan Installment & e-KYC status",
      "answer":
          "Check status at pmkisan.gov.in. Ensure Aadhaar land seeding & OTP/biometric e-KYC are completed."
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeechAndTts();
  }

  Future<void> _initializeSpeechAndTts() async {
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

    await _tts.setLanguage(_languages[_selectedLanguage] ?? "en-IN");
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingId = null;
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  /// Cleans display text so TTS speaks naturally like a human without reading emojis or bullet numbers
  String _cleanTextForSpeech(String rawText) {
    // 1. Remove all Emoji characters & symbols
    String cleaned = rawText.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F900}-\u{1F9FF}]|[\u{1F1E6}-\u{1F1FF}]|[\u{200D}]',
        unicode: true,
      ),
      '',
    );

    // 2. Convert Indian Rupee symbol ₹ to spoken "rupees"
    cleaned = cleaned.replaceAll('₹', ' rupees ');

    // 3. Convert numbers and bullet lists into natural conversational pauses
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

    // 4. Strip markdown formatting symbols like *, #, _, ~, `, etc.
    cleaned = cleaned.replaceAll(RegExp(r'[\*\#\_\~`\[\]\(\)]'), '');

    // 5. Clean multiple periods and spaces
    cleaned = cleaned.replaceAll(RegExp(r'\.+'), '. ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage("Microphone unavailable or permission denied.");
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

        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

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
    await Future.delayed(const Duration(milliseconds: 500));
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

    if (text.contains("farmer") ||
        text.contains("crop") ||
        text.contains("agriculture") ||
        text.contains("kisan")) {
      return "Agriculture Support 🌾\n\n1. Check PM-Kisan status & e-KYC at pmkisan.gov.in.\n2. Call Kisan Call Center (1800-180-1551) for crop advice.";
    }

    if (text.contains("government") ||
        text.contains("scheme") ||
        text.contains("ration") ||
        text.contains("certificate")) {
      return "Governance & Schemes 🏛️\n\n1. Apply for Certificates at your state e-District portal.\n2. Complete Ration Card e-KYC at your nearest FPS dealer.";
    }

    return "I am LokSetu AI. I can assist you with Healthcare, Governance, Education, and Agriculture.";
  }

  Future<void> _speak(String id, String text) async {
    if (_currentlySpeakingId == id) {
      await _tts.stop();
      setState(() {
        _currentlySpeakingId = null;
      });
      return;
    }

    await _tts.stop();
    final speechText = _cleanTextForSpeech(text);

    await _tts.setLanguage(_languages[_selectedLanguage] ?? "en-IN");
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);

    setState(() {
      _currentlySpeakingId = id;
    });

    await _tts.speak(speechText);
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
            Text("LokSetu AI Chatbot"),
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
            onChanged: (value) async {
              if (value == null) return;
              setState(() {
                _selectedLanguage = value;
              });
              await _tts.setLanguage(_languages[value] ?? "en-IN");
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
                      _showMessage("Speak or type your custom query below.");
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
                                tooltip: "Listen in $_selectedLanguage",
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
                            ? "Listening in $_selectedLanguage..."
                            : "Speak or type your query...",
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
    _tts.stop();
    super.dispose();
  }
}