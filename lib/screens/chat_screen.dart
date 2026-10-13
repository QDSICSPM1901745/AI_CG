import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      "text":
          "Hello! I am your AI Career Strategist. How can I help you today?",
      "isUser": false
    },
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _messages.add({"text": _controller.text, "isUser": true});
      _controller.clear();
    });

    // Fake AI Response Delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          "text":
              "Analyzing your profile... I suggest focusing on Flutter & AI integration.",
          "isUser": false
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI STRATEGIST",
            style: TextStyle(letterSpacing: 3, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, i) => _buildChatBubble(_messages[i]),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFFB026FF).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
              color: isUser
                  ? const Color(0xFFB026FF)
                  : const Color(0xFF00FFFF).withOpacity(0.5)),
        ),
        child: Text(msg['text'],
            style: const TextStyle(color: Colors.white, fontSize: 15)),
      ).animate().fade().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 35,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05)
        ]),
        borderGradient: const LinearGradient(
            colors: [Color(0xFFB026FF), Color(0xFF00FFFF)]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                      hintText: "Ask AI anything...", border: InputBorder.none),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF00FFFF)),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
