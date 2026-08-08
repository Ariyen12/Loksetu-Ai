import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/gemini_voice_engine.dart';
import '../services/language_detector.dart';
import '../services/farmer_knowledge_base.dart';

class CategorySuggestion {
  final String id;
  final String title;
  final String description;
  final String answer;

  const CategorySuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.answer,
  });
}

class CategoryAssistantScreen extends StatefulWidget {
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<CategorySuggestion> suggestions;

  const CategoryAssistantScreen({
    super.key,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.suggestions,
  });

  @override
  State<CategoryAssistantScreen> createState() =>
      _CategoryAssistantScreenState();
}

class _CategoryAssistantScreenState extends State<CategoryAssistantScreen>
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

  final Map<String, String> _languages = {
    "English": "en-IN",
    "Hindi": "hi-IN",
    "Bengali": "bn-IN",
    "Assamese": "as-IN",
    "Manipuri": "mni-IN",
  };

  final List<Map<String, String>> _messages = [];

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
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    _messages.add({
      "id": "init_msg",
      "sender": "ai",
      "text":
          "Welcome to ${widget.categoryTitle} Gemini Voice Assistant! 🎙️\n\nTap the microphone and speak naturally in your language — I will auto-detect your language and answer with high quality human voice.",
    });
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
      _showMessage("Microphone initialization failed. Check browser permissions.");
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

        // GEMINI AUTO-LANGUAGE DETECTION
        if (recognized.isNotEmpty) {
          final detected = LanguageDetector.detect(recognized);
          if (detected.languageName != _selectedLanguage) {
            setState(() {
              _selectedLanguage = detected.languageName;
            });
            _showMessage("Gemini Auto-Detected: ${detected.languageName}");
          }
        }

        if (result.finalResult) {
          _sendMessage();
        }
      },
    );
  }

  Future<void> _selectSuggestion(CategorySuggestion suggestion) async {
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _messages.add({
        "id": "${msgId}_u",
        "sender": "user",
        "text": suggestion.title,
      });

      _messages.add({
        "id": "${msgId}_ai",
        "sender": "ai",
        "text": suggestion.answer,
      });
    });

    _scrollToBottom();
    await _speak("${msgId}_ai", suggestion.answer);
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
      });
      _controller.clear();
    });

    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final response = _generateSmartResponse(message);
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

  String _generateSmartResponse(String query) {
    if (widget.categoryTitle == "Agriculture") {
      return FarmerKnowledgeBase.getAccurateFarmerAnswer(
          query, widget.categoryTitle);
    }

    final text = query.toLowerCase();

    for (final sug in widget.suggestions) {
      if (text.contains(sug.title.toLowerCase()) ||
          sug.title.toLowerCase().split(' ').any(
                (w) => w.length > 3 && text.contains(w),
              )) {
        return sug.answer;
      }
    }

    if (widget.categoryTitle == "Healthcare") {
      return "Healthcare Solution for '$query':\n\n"
          "1. For Emergency Help: Dial 108 for free instant ambulance.\n"
          "2. Free Doctor Consultations: Register at esanjeevaniopd.in.\n"
          "3. Ayushman Bharat Card: Visit nearest CSC center with Aadhaar & Ration Card for ₹5 Lakh annual medical coverage.";
    } else if (widget.categoryTitle == "Governance") {
      return "Governance & Certificate Guidance for '$query':\n\n"
          "1. Official Certificates (Income/Caste/Residence): Apply online at your state e-District portal or local CSC center.\n"
          "2. Ration Card e-KYC: Complete Aadhaar biometric linking at local Fair Price Shop dealer.\n"
          "3. Public Grievances: Call national helpline 1915 or register on pgportal.gov.in.";
    } else if (widget.categoryTitle == "Education") {
      return "Education & Scholarship Guidance for '$query':\n\n"
          "1. Government Scholarships: Apply on National Scholarship Portal at scholarships.gov.in.\n"
          "2. Free Skill Training (PMKVY): Enroll at local PMKVY training centers for free certified skill courses with placement support.\n"
          "3. RTE 25% Reserved Quota: Apply online for free private school admissions under Section 12(1)(c).";
    } else {
      return FarmerKnowledgeBase.getAccurateFarmerAnswer(
          query, widget.categoryTitle);
    }
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
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(widget.categoryIcon, color: Colors.white),
            const SizedBox(width: 10),
            Text(widget.categoryTitle),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate, color: Colors.white),
            tooltip: "Language: $_selectedLanguage (Gemini Auto)",
            initialValue: _selectedLanguage,
            onSelected: (lang) {
              setState(() {
                _selectedLanguage = lang;
              });
              _showMessage("Language set to $lang");
            },
            itemBuilder: (context) {
              return _languages.keys.map((lang) {
                return PopupMenuItem<String>(
                  value: lang,
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: _selectedLanguage == lang
                            ? widget.categoryColor
                            : Colors.transparent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(lang),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // PRESET SUGGESTIONS BAR
          Container(
            color: widget.categoryColor.withOpacity(0.06),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars_rounded,
                        color: widget.categoryColor, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Top 3 Most Requested Queries:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.categoryColor,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Chip(
                      avatar: const Icon(Icons.graphic_eq,
                          size: 12, color: Colors.white),
                      label: Text(
                        "Gemini Voice ($_selectedLanguage)",
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      backgroundColor: widget.categoryColor,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...widget.suggestions.asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final sug = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            avatar: CircleAvatar(
                              backgroundColor: widget.categoryColor,
                              child: Text(
                                "$index",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            label: Text(
                              sug.title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black12,
                            onPressed: () => _selectSuggestion(sug),
                          ),
                        );
                      }),
                      // OTHER OPTION
                      ActionChip(
                        avatar: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.more_horiz,
                              color: Colors.white, size: 16),
                        ),
                        label: const Text(
                          "Other (Custom Query / Voice)...",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        backgroundColor: Colors.grey.shade200,
                        elevation: 2,
                        shadowColor: Colors.black12,
                        onPressed: () {
                          _showMessage(
                              "Speak in your native language or type below.");
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // CHAT MESSAGES LIST
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
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? widget.categoryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomRight:
                            isUser ? const Radius.circular(2) : null,
                        bottomLeft:
                            !isUser ? const Radius.circular(2) : null,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSpeaking
                                      ? Colors.red
                                      : widget.categoryColor,
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
                                onPressed: () => _speak(
                                  msgId,
                                  message["text"] ?? "",
                                ),
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

          // GEMINI-STYLE ANIMATED MIC BAR
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // PULSING GEMINI MIC BUTTON
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
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: FloatingActionButton(
                        heroTag: "${widget.categoryTitle}_mic",
                        mini: true,
                        backgroundColor:
                            _isListening ? Colors.red : widget.categoryColor,
                        onPressed: _startListening,
                        tooltip: "Gemini Auto Voice Mic",
                        child: Icon(
                          _isListening ? Icons.graphic_eq : Icons.mic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? "Listening (Gemini Auto-Detecting)..."
                            : "Ask any ${_widgetCategoryLower()} query or click mic...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: "${widget.categoryTitle}_send",
                    mini: true,
                    backgroundColor: widget.categoryColor,
                    onPressed: _sendMessage,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _widgetCategoryLower() {
    return widget.categoryTitle.toLowerCase();
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
