import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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

class _CategoryAssistantScreenState extends State<CategoryAssistantScreen> {
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

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeechAndTts();
    _addInitialGreeting();
  }

  void _addInitialGreeting() {
    _messages.add({
      "id": "init_msg",
      "sender": "ai",
      "text":
          "Welcome to ${widget.categoryTitle} Services! 👋\nSelect one of the 3 most common queries below, or tap 'Other' to ask your custom question.",
    });
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
    await _tts.setSpeechRate(0.46); // Natural human reading pace
    await _tts.setPitch(1.0); // Natural voice pitch

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
      _showMessage(
        "Microphone initialization failed or browser permission denied.",
      );
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
      return "For your healthcare concern regarding '$query':\n\n1. Visit your nearest Primary Health Centre or Community Health Centre.\n2. Emergency Helpline: Call 108 for instant ambulance service.\n3. Teleconsultation: Access free doctor teleconsultations on eSanjeevani portal at esanjeevaniopd.in.";
    } else if (widget.categoryTitle == "Governance") {
      return "Regarding government service '$query':\n\n1. Applications can be submitted online at your state e-District portal or local CSC Center.\n2. Required documents: Aadhaar Card, Address Proof, and Income Certificate.\n3. National Helpline: Call 1915 for consumer or public grievance assistance.";
    } else if (widget.categoryTitle == "Education") {
      return "For your education query '$query':\n\n1. National Scholarship Portal: Apply at scholarships.gov.in for government stipends.\n2. Skill Development: Join free PMKVY courses with job placement support.\n3. Student Helpline: Reach out to your district education officer or school counselor.";
    } else {
      return "For your agriculture query '$query':\n\n1. PM-Kisan Support: Check installment status at pmkisan.gov.in.\n2. Crop Insurance: Report weather or pest damage within 72 hours on PMFBY app.\n3. Kisan Call Center: Dial 1800-180-1551 toll-free for expert farming guidance.";
    }
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
            tooltip: "Select Language",
            initialValue: _selectedLanguage,
            onSelected: (lang) async {
              setState(() {
                _selectedLanguage = lang;
              });
              await _tts.setLanguage(_languages[lang] ?? "en-IN");
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
          // PRESET SUGGESTIONS BAR (Top 3 preset queries + Other)
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
                      label: Text(
                        _selectedLanguage,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: widget.categoryColor.withOpacity(0.15),
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
                              "Type your query below or press the Mic icon to speak.");
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
                              IconButton(
                                icon: Icon(
                                  isSpeaking
                                      ? Icons.stop_circle
                                      : Icons.volume_up,
                                  color: isSpeaking
                                      ? Colors.red
                                      : widget.categoryColor,
                                  size: 22,
                                ),
                                tooltip: isSpeaking
                                    ? "Stop Voice"
                                    : "Listen in ${_selectedLanguage}",
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

          // BOTTOM CHAT INPUT BAR
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
                  FloatingActionButton(
                    heroTag: "${widget.categoryTitle}_mic",
                    mini: true,
                    backgroundColor:
                        _isListening ? Colors.red : widget.categoryColor,
                    onPressed: _startListening,
                    tooltip: "Speak in $_selectedLanguage",
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
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
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}
