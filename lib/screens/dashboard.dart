import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

// 1. Color Palette (Make sure this matches your main file)
class NeonColors {
  static const purple = Color(0xFFB026FF);
  static const cyan = Color(0xFF00FFFF);
  static const lime = Color(0xFF39FF14);
  static const bg = Color(0xFF050507);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [NeonColors.bg, Color(0xFF0F0025)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildSectionTitle("AI RECOMMENDED PATHS"),
                const SizedBox(height: 20),
                _buildCareerCards(),
                const SizedBox(height: 30),
                _buildSectionTitle("SKILL PROGRESS"),
                const SizedBox(height: 20),
                _buildProgressCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: NeonColors.bg,
        selectedItemColor: NeonColors.cyan,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Roadmap"),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), label: "AI Chat"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome back,",
                style: TextStyle(color: Colors.white54, fontSize: 16)),
            Text(
              "Future Developer",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: NeonColors.cyan, blurRadius: 10)],
              ),
            ),
          ],
        ),
        const CircleAvatar(
          radius: 25,
          backgroundColor: NeonColors.purple,
          child: Icon(Icons.person, color: Colors.white),
        ).animate().shimmer(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: NeonColors.lime,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
          fontSize: 12),
    ).animate().fadeIn(delay: 300.ms).slideX();
  }

  Widget _buildCareerCards() {
    final paths = [
      {"title": "AI Engineer", "match": "95%", "icon": Icons.psychology},
      {"title": "Full Stack Dev", "match": "82%", "icon": Icons.code},
      {"title": "Cloud Architect", "match": "75%", "icon": Icons.cloud_queue},
    ];

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        itemBuilder: (context, i) {
          return GlassmorphicContainer(
            width: 160,
            height: 180,
            borderRadius: 25,
            blur: 15,
            alignment: Alignment.center,
            border: 2,
            margin: const EdgeInsets.only(right: 20),
            linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05)
                ]),
            borderGradient: const LinearGradient(
                colors: [NeonColors.purple, NeonColors.cyan]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(paths[i]['icon'] as IconData,
                    color: NeonColors.cyan, size: 40),
                const SizedBox(height: 15),
                Text(paths[i]['title'] as String,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${paths[i]['match']} Match",
                    style:
                        const TextStyle(color: NeonColors.lime, fontSize: 12)),
              ],
            ),
          ).animate().scale(delay: (i * 200).ms, duration: 400.ms);
        },
      ),
    );
  }

  Widget _buildProgressCard() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100,
      borderRadius: 20,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(colors: [
        Colors.white.withOpacity(0.05),
        Colors.white.withOpacity(0.02)
      ]),
      borderGradient:
          const LinearGradient(colors: [NeonColors.cyan, Colors.transparent]),
      child: const ListTile(
        leading: Icon(Icons.auto_graph, color: NeonColors.purple),
        title: Text("Roadmap Progress", style: TextStyle(color: Colors.white)),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: LinearProgressIndicator(
              value: 0.6,
              backgroundColor: Colors.white10,
              color: NeonColors.cyan),
        ),
        trailing: Text("60%",
            style:
                TextStyle(color: NeonColors.cyan, fontWeight: FontWeight.bold)),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

// --- Placeholder for Chat ---
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.bg,
      appBar: AppBar(
          title: const Text("AI Assistant"),
          backgroundColor: Colors.transparent),
      body: const Center(child: Text("Chat UI coming soon...")),
    );
  }
}
