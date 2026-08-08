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

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  bool _speechAvailable = false;

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
      "sender": "ai",
      "text":
          "Namaste! 👋 I am LokSetu AI.\n\nTap the microphone and speak in your language. I'll help you communicate.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage(
        "Microphone is not available. Please check your browser microphone permission.",
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
            TextPosition(
              offset: _controller.text.length,
            ),
          );
        });

        if (result.finalResult) {
          _sendMessage();
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": message,
      });

      _controller.clear();
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    final response = _getDemoResponse(message);

    setState(() {
      _messages.add({
        "sender": "ai",
        "text": response,
      });
    });

    await _speak(response);
  }

  String _getDemoResponse(String message) {
    final text = message.toLowerCase();

    if (text.contains("scholarship") ||
        text.contains("education") ||
        text.contains("school")) {
      return "I can help you with education and scholarship information. 🎓\n\nTell me your course or class and your state.";
    }

    if (text.contains("hospital") ||
        text.contains("doctor") ||
        text.contains("health")) {
      return "I can help with general healthcare information. 🏥\n\nPlease tell me what information you need.";
    }

    if (text.contains("farmer") ||
        text.contains("crop") ||
        text.contains("agriculture") ||
        text.contains("farming")) {
      return "I can help with agriculture-related information. 🌾\n\nTell me your crop and the problem you are facing.";
    }

    if (text.contains("government") ||
        text.contains("scheme") ||
        text.contains("ration") ||
        text.contains("certificate")) {
      return "I can help you understand government services and schemes. 🏛️\n\nTell me which service you need.";
    }

    if (text.contains("hello") ||
        text.contains("hi") ||
        text.contains("namaste")) {
      return "Namaste! 🙏 How can I help you today?";
    }

    return "I understood your message. 🤖\n\nI can currently help with:\n\n🏛️ Government services\n🏥 Healthcare\n🎓 Education\n🌾 Agriculture\n🌐 Language assistance";
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage(
      _languages[_selectedLanguage] ?? "en-IN",
    );

    await _tts.setSpeechRate(0.48);
    await _tts.speak(text);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
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
              child: Icon(Icons.auto_awesome),
            ),
            SizedBox(width: 10),
            Text("LokSetu AI"),
          ],
        ),
      ),

      body: Column(
        children: [
          // LANGUAGE SELECTOR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.translate),
                const SizedBox(width: 8),

                const Text(
                  "Listener:",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 8),

                DropdownButton<String>(
                  value: _selectedLanguage,
                  items: _languages.keys.map((language) {
                    return DropdownMenuItem(
                      value: language,
                      child: Text(language),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    if (value == null) return;

                    setState(() {
                      _selectedLanguage = value;
                    });

                    await _tts.setLanguage(
                      _languages[value] ?? "en-IN",
                    );
                  },
                ),
              ],
            ),
          ),

          // CHAT
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                final isUser = message["sender"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width * 0.78,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      message["text"] ?? "",
                      style: TextStyle(
                        color:
                            isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // INPUT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // MIC
                  FloatingActionButton(
                    heroTag: "micButton",
                    mini: true,
                    backgroundColor:
                        _isListening ? Colors.red : Colors.blue,
                    onPressed: _startListening,
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
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
                            ? "Listening..."
                            : "Speak or type...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
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
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}