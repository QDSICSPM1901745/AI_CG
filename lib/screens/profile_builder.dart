import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

// All providers are in main.dart — import from there
import '../main.dart';

class ProfileBuilderScreen extends ConsumerStatefulWidget {
  const ProfileBuilderScreen({super.key});
  @override
  ConsumerState<ProfileBuilderScreen> createState() =>
      _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends ConsumerState<ProfileBuilderScreen> {
  int _currentStep = 0;

  String _name = '';
  String _education = '';
  // ignore: unused_field
  String _skills = '';
  String _goal = '';

  static const neonColor = Color(0xFF00FFFF);

  void _onStepContinue() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Save all at once using the unified updateProfile
      ref.read(userProvider.notifier).updateProfile(
            _name.trim().isEmpty ? 'Future Developer' : _name.trim(),
            _education.trim().isEmpty ? 'Not Set' : _education.trim(),
            _goal.trim().isEmpty ? 'Not Set' : _goal.trim(),
          );
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050507), Color(0xFF1A0033)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text(
                "PERSONALIZE YOUR AI",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.white,
                  shadows: [Shadow(color: neonColor, blurRadius: 10)],
                ),
              ).animate().fadeIn().slideY(begin: -1, end: 0),
              Expanded(
                child: Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(primary: neonColor),
                  ),
                  child: Stepper(
                    type: StepperType.vertical,
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: () {
                      if (_currentStep > 0) setState(() => _currentStep--);
                    },
                    steps: [
                      _buildStep(
                        "IDENTITY",
                        "What should I call you?",
                        Icons.person,
                        (val) => _name = val,
                      ),
                      _buildStep(
                        "EDUCATION",
                        "Your last completed degree?",
                        Icons.school,
                        (val) => _education = val,
                      ),
                      _buildStep(
                        "SKILLS",
                        "Key skills (e.g. Python, UI Design)",
                        Icons.bolt,
                        (val) => _skills = val,
                      ),
                      _buildStep(
                        "DREAM GOAL",
                        "What is your target role?",
                        Icons.track_changes,
                        (val) => _goal = val,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildStep(
    String title,
    String hint,
    IconData icon,
    Function(String) onChanged,
  ) {
    return Step(
      isActive: true,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
      content: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: neonColor.withValues(alpha: 0.4)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: TextField(
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            icon: Icon(icon, color: neonColor),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            border: InputBorder.none,
          ),
        ),
      ).animate().fadeIn().scale(),
    );
  }
}
