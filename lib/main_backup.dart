import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────

class RoadmapStep {
  final String title;
  final String description;
  final String duration;
  final List<String> skills;
  final List<String> resources;
  final List<String> dailyTasks;

  RoadmapStep({
    required this.title,
    required this.description,
    required this.duration,
    required this.skills,
    this.resources = const [],
    this.dailyTasks = const [],
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> j) => RoadmapStep(
        title: j['title'] ?? 'Step',
        description: j['description'] ?? '',
        duration: j['duration'] ?? '2 weeks',
        skills: List<String>.from(j['skills'] ?? []),
        resources: List<String>.from(j['resources'] ?? []),
        dailyTasks: List<String>.from(j['dailyTasks'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'duration': duration,
        'skills': skills,
        'resources': resources,
        'dailyTasks': dailyTasks,
      };
}

class CareerMatch {
  final String role;
  final String reason;
  final int percentage;
  final IconData icon;

  CareerMatch({
    required this.role,
    required this.percentage,
    required this.reason,
    required this.icon,
  });
}

class ShuffledQuestion {
  final String question;
  final List<String> shuffledOpts;
  final int correctIndex;
  ShuffledQuestion({
    required this.question,
    required this.shuffledOpts,
    required this.correctIndex,
  });
}

// ─────────────────────────────────────────
// ✅ FIREBASE CONFIG — SAHI JAGAH
// Firebase Console > Project Settings > General > Your Apps > Web App
// wahan se copy karo apni REAL values
// apiKey HAMESHA "AIza..." se shuru hoti hai
// ─────────────────────────────────────────

const _firebaseOptions = FirebaseOptions(
  apiKey:
      'AIzaSyAVRy75a0058PCZyXTJSAO2Ip0XW1hywm4', // ← Firebase key (AIza... se shuru)
  authDomain: 'ai-career-guide-b03be.firebaseapp.com',
  projectId: 'ai-career-guide-b03be',
  storageBucket: 'ai-career-guide-b03be.firebasestorage.app',
  messagingSenderId: '429836778807',
  appId: '1:429836778807:web:9cd27d0fe51203d0162eb2',
  measurementId: 'G-FWPTWLD52S',
);

// ─────────────────────────────────────────
// FIREBASE SERVICE
// ─────────────────────────────────────────

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String get uid => _auth.currentUser?.uid ?? '';
  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<String?> signup(
      String email, String password, String name) async {
    try {
      if (email.trim().isEmpty) return 'Email cannot be empty.';
      if (password.isEmpty) return 'Password cannot be empty.';
      if (password.length < 6) return 'Password must be at least 6 characters.';
      if (name.trim().isEmpty) return 'Name cannot be empty.';

      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

      await cred.user?.updateDisplayName(name.trim());
      await cred.user?.reload();

      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'degree': 'Not Set',
        'goal': 'Not Set',
        'email': email.trim().toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Please login.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'Email/Password sign-in is not enabled. Firebase Console mein enable karo.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'configuration-not-found':
          return 'Firebase config galat hai. APIKey check karo.';
        default:
          return e.message ?? 'Signup failed. Please try again.';
      }
    } catch (e) {
      return 'Something went wrong: ${e.toString()}';
    }
  }

  static Future<String?> login(String email, String password) async {
    try {
      if (email.trim().isEmpty) return 'Please enter your email.';
      if (password.isEmpty) return 'Please enter your password.';

      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email. Please sign up first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check and try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait and try again later.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        case 'operation-not-allowed':
          return 'Email/Password login is not enabled. Firebase Console mein enable karo.';
        case 'configuration-not-found':
          return 'Firebase config galat hai. APIKey check karo.';
        default:
          return e.message ?? 'Login failed. Please try again.';
      }
    } catch (e) {
      return 'Something went wrong: ${e.toString()}';
    }
  }

  static Future<void> logout() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  static Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      await googleSignIn.signOut();

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return 'Google sign-in was cancelled.';

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        return 'Google authentication failed. Please try again.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = cred.user!;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _db.collection('users').doc(user.uid).set({
          'name': user.displayName ?? 'User',
          'degree': 'Not Set',
          'goal': 'Not Set',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'network-request-failed':
          return 'No internet connection. Please check your network.';
        default:
          return e.message ?? 'Google sign-in failed. Please try again.';
      }
    } catch (e) {
      return 'Google sign-in failed: ${e.toString()}';
    }
  }

  static Future<String?> changePassword(String newPassword) async {
    try {
      if (newPassword.length < 6) {
        return 'Password must be at least 6 characters.';
      }
      await _auth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please logout and login again before changing password.';
      }
      return e.message ?? 'Password change failed.';
    }
  }

  static Future<void> saveProfile(
      String name, String degree, String goal) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).set(
          {'name': name, 'degree': degree, 'goal': goal},
          SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<Map<String, String>> loadProfile() async {
    if (uid.isEmpty) {
      return {
        'name': 'Future Developer',
        'degree': 'Not Set',
        'goal': 'Not Set'
      };
    }
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {
          'name': 'Future Developer',
          'degree': 'Not Set',
          'goal': 'Not Set'
        };
      }
      final d = doc.data()!;
      return {
        'name': d['name'] ?? 'Future Developer',
        'degree': d['degree'] ?? 'Not Set',
        'goal': d['goal'] ?? 'Not Set',
      };
    } catch (_) {
      return {
        'name': 'Future Developer',
        'degree': 'Not Set',
        'goal': 'Not Set'
      };
    }
  }

  static Future<void> saveNotes(List<String> notes) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set({'notes': notes}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<List<String>> loadNotes() async {
    if (uid.isEmpty) return [];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return List<String>.from(doc.data()?['notes'] ?? []);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveQuizHistory(List<Map<String, dynamic>> h) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set({'quizHistory': h}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> loadQuizHistory() async {
    if (uid.isEmpty) return [];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return List<Map<String, dynamic>>.from(doc.data()?['quizHistory'] ?? []);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveQuizScore(int score) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .set({'quizScore': score}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<int> loadQuizScore() async {
    if (uid.isEmpty) return 0;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return (doc.data()?['quizScore'] ?? 0) as int;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> saveRoadmap(Map<int, int> map) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).set(
          {'roadmap': map.map((k, v) => MapEntry(k.toString(), v))},
          SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<Map<int, int>> loadRoadmap() async {
    if (uid.isEmpty) return {0: 0, 1: 0};
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final raw = Map<String, dynamic>.from(doc.data()?['roadmap'] ?? {});
      if (raw.isEmpty) return {0: 0, 1: 0};
      return raw.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {0: 0, 1: 0};
    }
  }

  static Future<void> saveDynamicRoadmap(List<RoadmapStep> steps) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).set(
          {'dynamicRoadmap': steps.map((s) => s.toJson()).toList()},
          SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<List<RoadmapStep>> loadDynamicRoadmap() async {
    if (uid.isEmpty) return [];
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final raw = doc.data()?['dynamicRoadmap'] as List?;
      if (raw == null || raw.isEmpty) return [];
      return raw
          .map((e) => RoadmapStep.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────
// NOTIFICATION SERVICE
// ─────────────────────────────────────────

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true);
      await _plugin.initialize(
          settings: const InitializationSettings(android: android, iOS: ios));
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> showCareerTip() async {
    try {
      const tips = [
        'Build one project this week — portfolios speak louder than degrees!',
        'Update your LinkedIn today — recruiters are always searching.',
        'Practice 2 LeetCode problems daily — consistency beats cramming!',
        'Reach out to one professional on LinkedIn this week.',
        'AI + domain expertise = your unique competitive edge!',
      ];
      final tip = tips[DateTime.now().day % tips.length];
      const androidDetails = AndroidNotificationDetails(
          'career_tips', 'Career Tips',
          channelDescription: 'Daily career growth tips',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher');
      const details = NotificationDetails(
          android: androidDetails, iOS: DarwinNotificationDetails());
      await _plugin.show(
          id: 1,
          title: '💡 Career Tip',
          body: tip,
          notificationDetails: details);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────
// STORAGE SERVICE
// ─────────────────────────────────────────

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async =>
      _prefs = await SharedPreferences.getInstance();

  static Future<void> savePhotoPath(String path) async =>
      await _prefs?.setString('profile_photo', path);
  static String? loadPhotoPath() => _prefs?.getString('profile_photo');

  static Future<void> saveTheme(bool isDark) async =>
      await _prefs?.setBool('theme_dark', isDark);
  static bool loadTheme() => _prefs?.getBool('theme_dark') ?? true;

  static Future<void> setOnboardingDone() async =>
      await _prefs?.setBool('onboarding_done', true);
  static bool isOnboardingDone() => _prefs?.getBool('onboarding_done') ?? false;

  static Future<void> setNotifEnabled(bool v) async =>
      await _prefs?.setBool('notif_enabled', v);
  static bool isNotifEnabled() => _prefs?.getBool('notif_enabled') ?? true;
}

// ─────────────────────────────────────────
// ✅ ANTHROPIC SERVICE — KEY SAHI JAGAH HAI
// Apni real Anthropic key yahan daalein
// console.anthropic.com se milegi
// ─────────────────────────────────────────

class AnthropicService {
  // ✅ SIRF YEH LINE BADALNI HAI — apni Anthropic key yahan daalein
  static const String _apiKey =
      'YOUR_ANTHROPIC_API_KEY_HERE';
  // Example: 'YOUR_ANTHROPIC_API_KEY_HERE'

  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-haiku-4-5';

  static const String _systemPrompt = '''
You are an expert AI Career Strategist for Pakistani tech professionals and students.
You help with: career paths, skill development, resume writing, interview preparation,
salary negotiation, freelancing (Upwork, Fiverr), job search in Pakistan and remote markets.

Key context:
- Pakistan tech market 2026: AI roles +42%, Flutter +31%, high demand for remote workers
- Salary ranges: Flutter Dev PKR 80K-200K/mo, AI Engineer PKR 150K-400K+, Full Stack PKR 100K-250K
- Remote USD roles via Upwork/Toptal pay 5-10x more

Rules:
- Keep responses concise (max 3-4 sentences or a short numbered list)
- Be practical, actionable, Pakistan-context-aware
- Use English but include Urdu words naturally
- Always end with an actionable tip or next step
''';

  static Future<String> sendMessage(List<Map<String, String>> history) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      return _localFallback(history.last['content'] ?? '');
    }
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': 400,
              'system': _systemPrompt,
              'messages': history,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else if (response.statusCode == 401) {
        return 'Anthropic API key invalid. Please check your key.';
      } else if (response.statusCode == 429) {
        return 'Rate limit reached. Please wait a moment and try again.';
      } else {
        return _localFallback(history.last['content'] ?? '');
      }
    } on SocketException {
      return 'No internet connection. Check your network and try again.';
    } on TimeoutException {
      return 'Request timed out. Please try again.';
    } catch (e) {
      return _localFallback(history.last['content'] ?? '');
    }
  }

  static Future<List<RoadmapStep>> generateRoadmap(
      String goal, String degree, String skills) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') return _fallbackRoadmap(goal);
    try {
      final prompt = """
Generate a personalized 5-step learning roadmap for a Pakistani tech student.

Student Profile:
- Career Goal: $goal
- Degree: $degree
- Current Skills: $skills

Return ONLY a JSON array with exactly 5 objects. Each object must have:
- "title": short step name (max 4 words)
- "description": what to learn in this step (1-2 sentences)
- "duration": estimated time e.g. "2 weeks"
- "skills": array of 3-4 specific skills to learn
- "resources": array of 2-3 real free URLs (YouTube, docs, freeCodeCamp)
- "dailyTasks": array of 3 specific daily tasks (30-60 min each)

Return ONLY the JSON array, no other text.
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 1000,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'][0]['text'] as String)
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> parsed = jsonDecode(text);
        return parsed
            .map((e) => RoadmapStep.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}
    return _fallbackRoadmap(goal);
  }

  static Future<List<CareerMatch>> getCareerMatches(
      String degree, String goal, String skills) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') return _fallbackMatches(goal);
    try {
      final prompt = """
You are a career advisor for Pakistani tech students.
Analyze this profile and return career match percentages.

Profile:
- Degree: $degree
- Goal: $goal
- Skills: $skills

Return ONLY a JSON array with exactly 3 roles.
Each object:
- "role": job title
- "percentage": 60-99 integer
- "reason": max 8 words why this matches

Return ONLY JSON, no other text.
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 300,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'][0]['text'] as String)
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> parsed = jsonDecode(text);
        return parsed
            .map((e) => CareerMatch(
                role: e['role'] as String,
                percentage: e['percentage'] as int,
                reason: e['reason'] as String,
                icon: _iconForRole(e['role'] as String)))
            .toList();
      }
    } catch (_) {}
    return _fallbackMatches(goal);
  }

  static Future<List<ShuffledQuestion>> generateAdaptiveQuiz(
      String topic, String difficulty, String goal) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') return _fallbackQuiz();
    try {
      final prompt = """
Generate 10 multiple choice quiz questions for a Pakistani tech student.

Topic: $topic
Difficulty: $difficulty
Career Goal: $goal

Each question has exactly 4 options, one correct answer.
Mix Urdu and English naturally.

Return ONLY a JSON array with 10 objects:
{
  "question": "question text",
  "options": ["A", "B", "C", "D"],
  "correct": 0
}
"correct" is the INDEX 0-3 of correct option.
Return ONLY JSON array, no other text.
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 2000,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'][0]['text'] as String)
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final parsed = jsonDecode(text) as List;
        return parsed.map((item) {
          final correctVal = item['options'][item['correct']];
          final opts = List<String>.from(item['options'])..shuffle();
          return ShuffledQuestion(
              question: item['question'] as String,
              shuffledOpts: opts,
              correctIndex: opts.indexOf(correctVal));
        }).toList();
      }
    } catch (_) {}
    return _fallbackQuiz();
  }

  static Future<String> analyzeResume(String resumeText) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      return '📝 Resume analysis needs a real Anthropic API key. console.anthropic.com se key lo.';
    }
    try {
      final prompt = """
You are an expert resume reviewer for Pakistani tech jobs.
Analyze this resume and give:
1. Score out of 10
2. Top 3 strengths  
3. Top 3 improvements needed
4. Missing ATS keywords

Resume Text:
$resumeText
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 500,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (_) {}
    return 'Could not analyze resume. Please try again.';
  }

  static Future<String> getInterviewQuestion(
      String role, String difficulty) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      return 'Q: Tell me about yourself and why you want this role?\nA: Briefly describe your background, skills, and passion for the field.';
    }
    try {
      final prompt = """
Generate ONE interview question for a $role position in Pakistan.
Difficulty: $difficulty

Format exactly like this:
Q: [question here]
A: [ideal answer in 2-3 sentences]
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 300,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (_) {}
    return 'Could not load question. Try again.';
  }

  static Future<String> estimateSalary(
      String role, String experience, String city) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      return '💰 Salary estimation needs a real Anthropic API key. console.anthropic.com se key lo.';
    }
    try {
      final prompt = """
Estimate realistic salary for this Pakistani tech professional in 2026:
Role: $role
Experience: $experience  
City: $city

Give:
- Local salary range (PKR/month)
- Remote/Upwork rate (USD/hour)
- 2 tips to increase salary
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 300,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (_) {}
    return 'Could not estimate salary. Try again.';
  }

  static Future<String> getDailyTip(String goal) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      return '🎯 Build one project today — portfolios speak louder than degrees!';
    }
    try {
      final prompt = """
Give ONE actionable career tip for a Pakistani tech student
whose goal is: $goal
Make it specific, motivating, and doable today.
Max 2 sentences. Start with an emoji.
""";
      final response = await http
          .post(Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01'
              },
              body: jsonEncode({
                'model': _model,
                'max_tokens': 150,
                'messages': [
                  {'role': 'user', 'content': prompt}
                ]
              }))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      }
    } catch (_) {}
    return '🎯 Build one project today — portfolios speak louder than degrees!';
  }

  // ── Helpers ──

  static IconData _iconForRole(String role) {
    final r = role.toLowerCase();
    if (r.contains('flutter') || r.contains('mobile')) {
      return Icons.phone_android;
    }
    if (r.contains('ai') || r.contains('data') || r.contains('ml')) {
      return Icons.auto_awesome;
    }
    if (r.contains('web') || r.contains('full')) return Icons.web;
    if (r.contains('backend')) return Icons.storage;
    return Icons.work_outline;
  }

  static List<CareerMatch> _fallbackMatches(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('flutter') || g.contains('mobile')) {
      return [
        CareerMatch(
            role: 'Flutter Developer',
            percentage: 95,
            reason: 'Goal directly matches this role',
            icon: Icons.phone_android),
        CareerMatch(
            role: 'Mobile App Developer',
            percentage: 82,
            reason: 'Cross-platform skills highly valued',
            icon: Icons.smartphone),
        CareerMatch(
            role: 'Full Stack Developer',
            percentage: 68,
            reason: 'Good foundation to expand skills',
            icon: Icons.layers),
      ];
    }
    return [
      CareerMatch(
          role: 'Software Engineer',
          percentage: 85,
          reason: 'Core CS skills match well',
          icon: Icons.code),
      CareerMatch(
          role: 'Backend Developer',
          percentage: 75,
          reason: 'Strong programming foundation',
          icon: Icons.storage),
      CareerMatch(
          role: 'AI Engineer',
          percentage: 65,
          reason: 'Growing field high demand',
          icon: Icons.auto_awesome),
    ];
  }

  static List<RoadmapStep> _fallbackRoadmap(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('flutter') || g.contains('mobile')) {
      return [
        RoadmapStep(
            title: 'Dart Fundamentals',
            description: 'Learn Dart syntax, OOP, and null safety basics.',
            duration: '2 weeks',
            skills: ['Variables', 'Classes', 'Async/Await', 'Null Safety']),
        RoadmapStep(
            title: 'Flutter Basics',
            description: 'Build UI with widgets, layouts, and navigation.',
            duration: '3 weeks',
            skills: ['Widgets', 'StatefulWidget', 'Navigation', 'ListView']),
        RoadmapStep(
            title: 'State Management',
            description: 'Master Riverpod for clean MVVM architecture.',
            duration: '2 weeks',
            skills: ['Riverpod', 'StateNotifier', 'Provider', 'MVVM']),
        RoadmapStep(
            title: 'Firebase Integration',
            description: 'Add backend with Auth and Firestore.',
            duration: '2 weeks',
            skills: ['Firebase Auth', 'Firestore', 'CRUD', 'Real-time']),
        RoadmapStep(
            title: 'Production & Portfolio',
            description: 'Deploy app and build portfolio projects.',
            duration: '3 weeks',
            skills: ['Play Store', 'Testing', 'CI/CD', 'Portfolio']),
      ];
    }
    return [
      RoadmapStep(
          title: 'Programming Basics',
          description: 'Master core programming concepts.',
          duration: '3 weeks',
          skills: ['Python/Dart', 'Data Structures', 'Algorithms', 'OOP']),
      RoadmapStep(
          title: 'App Development',
          description: 'Build projects with modern frameworks.',
          duration: '4 weeks',
          skills: ['Flutter/React', 'REST APIs', 'Database', 'Git']),
      RoadmapStep(
          title: 'Backend Development',
          description: 'Server-side and database skills.',
          duration: '3 weeks',
          skills: ['Node.js', 'SQL', 'NoSQL', 'Firebase']),
      RoadmapStep(
          title: 'Professional Skills',
          description: 'Resume, GitHub, LinkedIn setup.',
          duration: '2 weeks',
          skills: ['Resume', 'GitHub', 'LinkedIn', 'Portfolio']),
      RoadmapStep(
          title: 'Job Readiness',
          description: 'Interview prep and Upwork profile.',
          duration: '2 weeks',
          skills: ['LeetCode', 'System Design', 'Upwork', 'Freelancing']),
    ];
  }

  static List<ShuffledQuestion> _fallbackQuiz() {
    final raw = List.from(_rawQuizBank)..shuffle();
    return raw.take(10).map((item) {
      final correctVal = item['opts'][item['correct']];
      final opts = List<String>.from(item['opts'])..shuffle();
      return ShuffledQuestion(
          question: item['q'] as String,
          shuffledOpts: opts,
          correctIndex: opts.indexOf(correctVal));
    }).toList();
  }

  static String _localFallback(String input) {
    final q = input.toLowerCase();
    if (q.contains('flutter') || q.contains('dart')) {
      return '🚀 Flutter is one of the fastest-growing mobile frameworks in 2026! Focus on Riverpod for state management and build at least 3 production-quality apps. 🎯 Start with a clone project this week!';
    }
    if (q.contains('ai') || q.contains('machine learning')) {
      return '🤖 AI/ML is the hottest field! Start with Python → Pandas → Scikit-learn → PyTorch. Work on Kaggle competitions. 🎯 Join one Kaggle competition this month!';
    }
    if (q.contains('resume') || q.contains('cv')) {
      return '📄 Strong tech resume: (1) 2-line impact summary, (2) Quantify wins, (3) 3-5 GitHub projects, (4) Keep to 1 page. 🎯 Update your GitHub README today.';
    }
    if (q.contains('salary') || q.contains('income')) {
      return '💰 2026 Pakistan tech salaries: Flutter Dev PKR 80K–200K/mo, AI Engineer PKR 150K–400K+. Remote USD roles via Upwork pay 5-10x more. 🎯 Create an Upwork profile this weekend!';
    }
    if (q.contains('hello') || q.contains('hi') || q.contains('salam')) {
      return '👋 Assalam o Alaikum! I\'m your AI Career Strategist. Ask me about career paths, skills, resume tips, interview prep, or salaries!';
    }
    return '💡 Great question! Focus on building practical skills through real projects. 🎯 Pick ONE skill to master this month!';
  }
}

// ─────────────────────────────────────────
// STATE PROVIDERS
// ─────────────────────────────────────────

final userProvider = StateNotifierProvider<UserNotifier, Map<String, String>>(
    (ref) => UserNotifier());

class UserNotifier extends StateNotifier<Map<String, String>> {
  UserNotifier()
      : super({
          'name': 'Future Developer',
          'degree': 'Not Set',
          'goal': 'Not Set'
        });
  Future<void> loadFromFirebase() async =>
      state = await FirebaseService.loadProfile();
  void updateProfile(String name, String degree, String goal) {
    state = {'name': name, 'degree': degree, 'goal': goal};
    FirebaseService.saveProfile(name, degree, goal);
  }
}

final profilePhotoProvider =
    StateNotifierProvider<PhotoNotifier, String?>((ref) => PhotoNotifier());

class PhotoNotifier extends StateNotifier<String?> {
  PhotoNotifier() : super(StorageService.loadPhotoPath());
  void setPhoto(String path) {
    state = path;
    StorageService.savePhotoPath(path);
  }

  void clearPhoto() {
    state = null;
    StorageService.savePhotoPath('');
  }
}

final themeModeProvider = StateProvider<ThemeMode>(
    (ref) => StorageService.loadTheme() ? ThemeMode.dark : ThemeMode.light);

final quizScoreProvider =
    StateNotifierProvider<QuizScoreNotifier, int>((ref) => QuizScoreNotifier());

class QuizScoreNotifier extends StateNotifier<int> {
  QuizScoreNotifier() : super(0);
  Future<void> loadFromFirebase() async =>
      state = await FirebaseService.loadQuizScore();
  void setScore(int score) {
    state = score;
    FirebaseService.saveQuizScore(score);
  }
}

final quizHistoryProvider =
    StateNotifierProvider<QuizHistoryNotifier, List<Map<String, dynamic>>>(
        (ref) => QuizHistoryNotifier());

class QuizHistoryNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  QuizHistoryNotifier() : super([]);
  Future<void> loadFromFirebase() async =>
      state = await FirebaseService.loadQuizHistory();
  void addResult(int score, String date) {
    state = [
      ...state,
      {'score': score, 'date': date, 'total': 300}
    ];
    FirebaseService.saveQuizHistory(state);
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<String>>(
    (ref) => NotesNotifier());

class NotesNotifier extends StateNotifier<List<String>> {
  NotesNotifier() : super([]);
  Future<void> loadFromFirebase() async =>
      state = await FirebaseService.loadNotes();
  void addNote(String note) {
    if (note.trim().isEmpty) return;
    state = [...state, note.trim()];
    FirebaseService.saveNotes(state);
  }

  void deleteNote(int index) {
    final u = [...state];
    u.removeAt(index);
    state = u;
    FirebaseService.saveNotes(state);
  }
}

final roadmapProgressProvider =
    StateNotifierProvider<RoadmapProgressNotifier, Map<int, int>>(
        (ref) => RoadmapProgressNotifier());

class RoadmapProgressNotifier extends StateNotifier<Map<int, int>> {
  RoadmapProgressNotifier() : super({0: 0, 1: 0, 2: 0, 3: 0, 4: 0});
  Future<void> loadFromFirebase() async =>
      state = await FirebaseService.loadRoadmap();
  void updateProgress(int index, int value) {
    state = {...state, index: value};
    FirebaseService.saveRoadmap(state);
  }
}

final dynamicRoadmapProvider =
    StateNotifierProvider<DynamicRoadmapNotifier, List<RoadmapStep>>(
        (ref) => DynamicRoadmapNotifier());

class DynamicRoadmapNotifier extends StateNotifier<List<RoadmapStep>> {
  DynamicRoadmapNotifier() : super([]);
  Future<void> loadFromFirebase() async {
    final steps = await FirebaseService.loadDynamicRoadmap();
    if (steps.isNotEmpty) state = steps;
  }

  Future<void> generateAndSave(
      String goal, String degree, String skills) async {
    final steps = await AnthropicService.generateRoadmap(goal, degree, skills);
    state = steps;
    await FirebaseService.saveDynamicRoadmap(steps);
  }
}

final careerMatchProvider =
    StateNotifierProvider<CareerMatchNotifier, List<CareerMatch>>(
        (ref) => CareerMatchNotifier());

class CareerMatchNotifier extends StateNotifier<List<CareerMatch>> {
  CareerMatchNotifier() : super([]);
  Future<void> generateMatches(
      String degree, String goal, String skills) async {
    final matches =
        await AnthropicService.getCareerMatches(degree, goal, skills);
    state = matches;
  }
}

final dailyTipProvider = StateNotifierProvider<DailyTipNotifier, String>(
    (ref) => DailyTipNotifier());

class DailyTipNotifier extends StateNotifier<String> {
  DailyTipNotifier() : super('');
  Future<void> loadTip(String goal) async {
    if (state.isNotEmpty) return;
    final tip = await AnthropicService.getDailyTip(goal);
    state = tip;
  }
}

// ─────────────────────────────────────────
// AUTH STATE
// ─────────────────────────────────────────

class AuthState {
  final bool isLoggedIn;
  final String email;
  const AuthState({this.isLoggedIn = false, this.email = ''});
  AuthState copyWith({bool? isLoggedIn, String? email}) => AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn, email: email ?? this.email);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(AuthState(
            isLoggedIn: FirebaseService.isLoggedIn,
            email: FirebaseService.currentUser?.email ?? ''));

  Future<String?> signup(String email, String password, String name) async {
    final err = await FirebaseService.signup(email, password, name);
    if (err != null) return err;
    state = AuthState(isLoggedIn: true, email: email.trim());
    return null;
  }

  Future<String?> login(String email, String password) async {
    final err = await FirebaseService.login(email, password);
    if (err != null) return err;
    state = AuthState(isLoggedIn: true, email: email.trim());
    return null;
  }

  Future<void> logout() async {
    await FirebaseService.logout();
    state = const AuthState();
  }

  Future<String?> changePassword(String newPass) async =>
      await FirebaseService.changePassword(newPass);
}

class SettingsState {
  final bool notificationsEnabled;
  final bool quizReminder;
  final bool soundEnabled;
  const SettingsState(
      {this.notificationsEnabled = true,
      this.quizReminder = true,
      this.soundEnabled = false});
  SettingsState copyWith(
          {bool? notificationsEnabled,
          bool? quizReminder,
          bool? soundEnabled}) =>
      SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        quizReminder: quizReminder ?? this.quizReminder,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
    (ref) => SettingsNotifier());

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());
  void toggle(String key) {
    switch (key) {
      case 'notifications':
        state =
            state.copyWith(notificationsEnabled: !state.notificationsEnabled);
        break;
      case 'quiz':
        state = state.copyWith(quizReminder: !state.quizReminder);
        break;
      case 'sound':
        state = state.copyWith(soundEnabled: !state.soundEnabled);
        break;
    }
  }
}

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────

class Neon {
  static const purple = Color(0xFFB026FF);
  static const cyan = Color(0xFF00E5FF);
  static const lime = Color(0xFF39FF14);
  static const pink = Color(0xFFFF00C8);
  static const orange = Color(0xFFFF6B00);
  static const purpleL = Color(0xFF7B00CC);
  static const cyanL = Color(0xFF007A99);
  static const limeL = Color(0xFF1E7A00);
  static const pinkL = Color(0xFFB0006F);
  static const orangeL = Color(0xFFBF4800);
  static const bgDark = Color(0xFF06060F);
  static const cardDark = Color(0xFF0F0F1E);
  static const card2Dark = Color(0xFF181828);
  static const bgLight = Color(0xFFF2F0FF);
  static const cardLight = Color(0xFFFFFFFF);
  static const card2Light = Color(0xFFEDE9FF);

  static Color bg(ThemeMode m) => m == ThemeMode.light ? bgLight : bgDark;
  static Color card(ThemeMode m) => m == ThemeMode.light ? cardLight : cardDark;
  static Color card2(ThemeMode m) =>
      m == ThemeMode.light ? card2Light : card2Dark;
  static Color text(ThemeMode m) =>
      m == ThemeMode.light ? const Color(0xFF12004F) : Colors.white;
  static Color subtext(ThemeMode m) =>
      m == ThemeMode.light ? const Color(0xFF4A3880) : Colors.white54;
  static Color hint(ThemeMode m) =>
      m == ThemeMode.light ? const Color(0xFF8070A8) : Colors.white30;
  static Color border(ThemeMode m) =>
      m == ThemeMode.light ? const Color(0xFFCEC4F0) : Colors.white10;
}

// ─────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: _firebaseOptions);
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  await StorageService.init();

  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Notification init error: $e');
  }

  runApp(const ProviderScope(child: AICareerApp()));
}

class AICareerApp extends ConsumerWidget {
  const AICareerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final interLight = GoogleFonts.interTextTheme(ThemeData.light().textTheme)
        .apply(
            bodyColor: const Color(0xFF12004F),
            displayColor: const Color(0xFF12004F));
    final interDark = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final lightTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: Neon.bgLight,
      colorScheme: ColorScheme.fromSeed(
          seedColor: Neon.purpleL,
          brightness: Brightness.light,
          surface: Neon.cardLight),
      textTheme: interLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF12004F),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: const Color(0xFF12004F)),
      ),
      cardColor: Neon.cardLight,
      dividerColor: Neon.border(ThemeMode.light),
      iconTheme: const IconThemeData(color: Color(0xFF12004F)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Neon.card2Light,
        hintStyle:
            GoogleFonts.inter(color: Neon.hint(ThemeMode.light), fontSize: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Neon.border(ThemeMode.light))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Neon.purpleL, width: 2)),
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: Neon.bgDark,
      colorScheme: ColorScheme.fromSeed(
          seedColor: Neon.purple,
          brightness: Brightness.dark,
          surface: Neon.cardDark),
      textTheme: interDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.white),
      ),
      cardColor: Neon.cardDark,
      dividerColor: Colors.white12,
      iconTheme: const IconThemeData(color: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Neon.card2Dark,
        hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 13),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Neon.purple, width: 2)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: _getHomeScreen(),
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const MainNavigationHub(),
        '/onboarding': (_) => const OnboardingScreen(),
      },
    );
  }

  Widget _getHomeScreen() {
    try {
      if (FirebaseService.isLoggedIn) return const _LoadDataScreen();
      if (StorageService.isOnboardingDone()) return const AuthScreen();
      return const SplashScreen();
    } catch (_) {
      return const AuthScreen();
    }
  }
}

// ─────────────────────────────────────────
// DATA LOADER
// ─────────────────────────────────────────

class _LoadDataScreen extends ConsumerStatefulWidget {
  const _LoadDataScreen();
  @override
  ConsumerState<_LoadDataScreen> createState() => _LoadDataScreenState();
}

class _LoadDataScreenState extends ConsumerState<_LoadDataScreen> {
  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        ref.read(userProvider.notifier).loadFromFirebase(),
        ref.read(notesProvider.notifier).loadFromFirebase(),
        ref.read(quizHistoryProvider.notifier).loadFromFirebase(),
        ref.read(quizScoreProvider.notifier).loadFromFirebase(),
        ref.read(roadmapProgressProvider.notifier).loadFromFirebase(),
        ref.read(dynamicRoadmapProvider.notifier).loadFromFirebase(),
      ]);
    } catch (e) {
      debugPrint('Data load error: $e');
    }
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainNavigationHub()));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Neon.bgDark,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.psychology_alt_rounded, size: 64, color: Neon.purple)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 1500.ms,
                  colors: [Neon.purple, Neon.cyan, Neon.purple]),
          const SizedBox(height: 24),
          Text('Loading your data...',
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 12, letterSpacing: 2)),
          const SizedBox(height: 20),
          SizedBox(
              width: 140,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                      minHeight: 3,
                      color: Neon.cyan,
                      backgroundColor: Colors.white10))),
        ])),
      );
}

// ─────────────────────────────────────────
// AUTH SCREEN
// ─────────────────────────────────────────

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _loginEmail = TextEditingController();
  final _loginPass = TextEditingController();
  final _signupName = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPass = TextEditingController();
  final _signupConfirm = TextEditingController();
  bool _loginPassVisible = false;
  bool _signupPassVisible = false;
  bool _signupConfirmVisible = false;
  bool _isLoading = false;
  String? _loginError;
  String? _signupError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {
          _loginError = null;
          _signupError = null;
        }));
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmail.dispose();
    _loginPass.dispose();
    _signupName.dispose();
    _signupEmail.dispose();
    _signupPass.dispose();
    _signupConfirm.dispose();
    super.dispose();
  }

  void _doLogin() async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });
    final err = await ref
        .read(authProvider.notifier)
        .login(_loginEmail.text.trim(), _loginPass.text);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _loginError = err);
      return;
    }
    try {
      await ref.read(userProvider.notifier).loadFromFirebase();
    } catch (_) {}
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const _LoadDataScreen()));
  }

  void _doSignup() async {
    setState(() => _signupError = null);
    if (_signupName.text.trim().isEmpty) {
      setState(() => _signupError = 'Please enter your name.');
      return;
    }
    if (_signupEmail.text.trim().isEmpty) {
      setState(() => _signupError = 'Please enter your email.');
      return;
    }
    if (_signupPass.text.length < 6) {
      setState(() => _signupError = 'Password must be at least 6 characters.');
      return;
    }
    if (_signupPass.text != _signupConfirm.text) {
      setState(() => _signupError = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    final err = await ref.read(authProvider.notifier).signup(
        _signupEmail.text.trim(), _signupPass.text, _signupName.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _signupError = err);
      return;
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
  }

  void _doGoogleSignIn() async {
    setState(() {
      _loginError = null;
      _isLoading = true;
    });
    final err = await FirebaseService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (err != null) {
      setState(() => _loginError = err);
      return;
    }
    final isNew = !StorageService.isOnboardingDone();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                isNew ? const OnboardingScreen() : const _LoadDataScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final acPink = isDark ? Neon.pink : Neon.pinkL;
    final textColor = Neon.text(themeMode);

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      body: Stack(children: [
        Positioned(
            top: -60,
            left: -60,
            child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: acPurple.withValues(alpha: 0.10)))),
        Positioned(
            bottom: -40,
            right: -40,
            child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: acCyan.withValues(alpha: 0.09)))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(children: [
              const SizedBox(height: 30),

              Icon(Icons.psychology_alt_rounded, size: 72, color: acPurple)
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .shimmer(
                      delay: 800.ms,
                      duration: 2.seconds,
                      colors: [acPurple, acCyan, acPurple]),
              const SizedBox(height: 14),
              Text('CAREER GUIDE',
                      style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: textColor,
                          shadows: [Shadow(color: acPurple, blurRadius: 18)]))
                  .animate()
                  .fadeIn(delay: 300.ms),
              const SizedBox(height: 6),
              Text('AI-Powered Career Platform',
                  style: GoogleFonts.inter(
                      color: Neon.subtext(themeMode),
                      fontSize: 11,
                      letterSpacing: 2)),
              const SizedBox(height: 40),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Neon.border(themeMode))),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                      color: acPurple, borderRadius: BorderRadius.circular(14)),
                  labelColor: Colors.white,
                  unselectedLabelColor: Neon.subtext(themeMode),
                  labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 2),
                  tabs: const [Tab(text: 'LOGIN'), Tab(text: 'SIGN UP')],
                ),
              ),
              const SizedBox(height: 32),

              // LOGIN TAB
              if (_tab.index == 0) ...[
                _authField('Email Address', Icons.email_outlined, _loginEmail,
                    acCyan, themeMode),
                const SizedBox(height: 16),
                _authField('Password', Icons.lock_outline, _loginPass, acPurple,
                    themeMode,
                    isPassword: true,
                    visible: _loginPassVisible,
                    onToggle: () =>
                        setState(() => _loginPassVisible = !_loginPassVisible)),
                if (_loginError != null) ...[
                  const SizedBox(height: 12),
                  _errorBox(_loginError!),
                ],
                const SizedBox(height: 28),
                _authButton('LOGIN', acPurple, _doLogin),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: Divider(color: Neon.border(themeMode))),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: GoogleFonts.inter(
                              color: Neon.hint(themeMode), fontSize: 11))),
                  Expanded(child: Divider(color: Neon.border(themeMode))),
                ]),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(color: acCyan.withValues(alpha: 0.45)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: _isLoading ? null : _doGoogleSignIn,
                  icon:
                      Icon(Icons.g_mobiledata_rounded, color: acCyan, size: 24),
                  label: Text('Continue with Google',
                      style: GoogleFonts.inter(color: acCyan, fontSize: 13)),
                ),
              ],

              // SIGNUP TAB
              if (_tab.index == 1) ...[
                _authField('Full Name', Icons.person_outline, _signupName,
                    acLime, themeMode),
                const SizedBox(height: 16),
                _authField('Email Address', Icons.email_outlined, _signupEmail,
                    acCyan, themeMode),
                const SizedBox(height: 16),
                _authField('Password (min 6 chars)', Icons.lock_outline,
                    _signupPass, acPurple, themeMode,
                    isPassword: true,
                    visible: _signupPassVisible,
                    onToggle: () => setState(
                        () => _signupPassVisible = !_signupPassVisible)),
                const SizedBox(height: 16),
                _authField('Confirm Password', Icons.lock_person_outlined,
                    _signupConfirm, acPink, themeMode,
                    isPassword: true,
                    visible: _signupConfirmVisible,
                    onToggle: () => setState(
                        () => _signupConfirmVisible = !_signupConfirmVisible)),
                const SizedBox(height: 10),
                _passwordStrength(_signupPass.text, themeMode, isDark),
                if (_signupError != null) ...[
                  const SizedBox(height: 12),
                  _errorBox(_signupError!),
                ],
                const SizedBox(height: 28),
                _authButton('CREATE ACCOUNT', acPurple, _doSignup),
                const SizedBox(height: 12),
                Text('By signing up you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Neon.hint(themeMode), fontSize: 10)),
              ],

              const SizedBox(height: 40),
            ]),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
              child: Container(
                  color: Colors.black54,
                  child: Center(
                      child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                              color: Neon.card(themeMode),
                              borderRadius: BorderRadius.circular(20)),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            CircularProgressIndicator(color: acPurple),
                            const SizedBox(height: 16),
                            Text('Please wait...',
                                style: GoogleFonts.inter(
                                    color: textColor,
                                    fontSize: 13,
                                    letterSpacing: 1)),
                          ]))))),
      ]),
    );
  }

  Widget _errorBox(String msg) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.4))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg,
                  style: GoogleFonts.inter(
                      color: Colors.redAccent, fontSize: 13))),
        ]),
      );

  Widget _authField(String hint, IconData icon, TextEditingController ctrl,
          Color col, ThemeMode tm,
          {bool isPassword = false,
          bool visible = false,
          VoidCallback? onToggle}) =>
      TextField(
        controller: ctrl,
        obscureText: isPassword && !visible,
        onChanged: (_) => setState(() {
          _loginError = null;
          _signupError = null;
        }),
        style: GoogleFonts.inter(color: Neon.text(tm), fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: col, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Neon.hint(tm),
                      size: 18),
                  onPressed: onToggle)
              : null,
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Neon.hint(tm), fontSize: 13),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Neon.border(tm))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: col, width: 2)),
        ),
      ).animate().fadeIn(duration: 300.ms);

  Widget _authButton(String label, Color color, VoidCallback onTap) =>
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size(double.infinity, 58),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 10,
            shadowColor: color.withValues(alpha: 0.4)),
        onPressed: _isLoading ? null : onTap,
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 3)),
      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);

  Widget _passwordStrength(String pass, ThemeMode m, bool isDark) {
    if (pass.isEmpty) return const SizedBox.shrink();
    int strength = 0;
    if (pass.length >= 6) strength++;
    if (pass.contains(RegExp(r'[A-Z]'))) strength++;
    if (pass.contains(RegExp(r'[0-9]'))) strength++;
    if (pass.contains(RegExp(r'[!@#$%^&*]'))) strength++;
    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      Colors.transparent,
      Colors.red,
      isDark ? Neon.orange : Neon.orangeL,
      isDark ? Neon.cyan : Neon.cyanL,
      isDark ? Neon.lime : Neon.limeL
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
          children: List.generate(
              4,
              (i) => Expanded(
                  child: AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 5),
                      height: 5,
                      decoration: BoxDecoration(
                          color:
                              i < strength ? colors[strength] : Neon.border(m),
                          borderRadius: BorderRadius.circular(3)))))),
      const SizedBox(height: 6),
      Text('Password strength: ${labels[strength]}',
          style: GoogleFonts.inter(
              color: colors[strength], fontSize: 11, letterSpacing: 1)),
    ]);
  }
}

// ─────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    Timer(4000.ms, () {
      if (mounted) {
        Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const AuthScreen(),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
              transitionDuration: 600.ms,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Neon.bgDark,
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.psychology_alt_rounded,
                  size: 80, color: Colors.white)
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                  duration: 2.seconds,
                  colors: [Colors.white, Neon.cyan, Neon.purple, Neon.pink]),
          const SizedBox(height: 28),
          Text('CAREER',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: Colors.white,
                  shadows: [const Shadow(color: Neon.purple, blurRadius: 22)])),
          Text('GUIDE',
              style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: Neon.cyan,
                  shadows: [const Shadow(color: Neon.cyan, blurRadius: 24)])),
          const SizedBox(height: 14),
          Text('AI-POWERED FUTURE',
              style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 6,
                  color: Neon.pink,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 52),
          SizedBox(
              width: 160,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                      minHeight: 3,
                      color: Neon.cyan,
                      backgroundColor: Colors.white10))),
        ])),
      );
}

// ─────────────────────────────────────────
// ONBOARDING SCREEN
// ─────────────────────────────────────────

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const _slides = [
    {
      'title': 'AI CAREER MENTOR',
      'subtitle': 'Your 24/7 career advisor',
      'icon': Icons.forum_outlined,
      'desc':
          'Ask anything — resume reviews, interview tips, salary benchmarks.',
      'color': Neon.purple,
      'colorL': Neon.purpleL,
      'tag': 'ALWAYS AVAILABLE'
    },
    {
      'title': 'SMART ROADMAPS',
      'subtitle': 'Step-by-step to your dream job',
      'icon': Icons.alt_route_outlined,
      'desc':
          'AI-generated learning paths personalized to your goal and skills.',
      'color': Neon.lime,
      'colorL': Neon.limeL,
      'tag': 'PERSONALIZED'
    },
    {
      'title': 'SKILL QUIZZES',
      'subtitle': 'Test yourself, grow faster',
      'icon': Icons.quiz_outlined,
      'desc': 'AI-generated quiz questions matched to your career goal.',
      'color': Neon.cyan,
      'colorL': Neon.cyanL,
      'tag': 'AI GENERATED'
    },
    {
      'title': 'AI TOOLS',
      'subtitle': 'Resume, Interview, Salary',
      'icon': Icons.auto_awesome_outlined,
      'desc':
          'Analyze resume, practice interviews, estimate salary — powered by AI.',
      'color': Neon.pink,
      'colorL': Neon.pinkL,
      'tag': 'POWERED BY CLAUDE'
    },
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pc.nextPage(duration: 450.ms, curve: Curves.easeInOutCubic);
    } else {
      StorageService.setOnboardingDone();
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ProfileBuilderScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final accentColor =
        (isDark ? _slides[_page]['color'] : _slides[_page]['colorL']) as Color;

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      body: Stack(children: [
        PageView.builder(
          controller: _pc,
          onPageChanged: (v) => setState(() => _page = v),
          itemCount: _slides.length,
          itemBuilder: (ctx, i) => _buildSlide(_slides[i], themeMode),
        ),
        Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                        duration: 350.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: _page == i ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: _page == i
                                ? accentColor
                                : (isDark
                                    ? Colors.white24
                                    : Neon.border(themeMode)),
                            borderRadius: BorderRadius.circular(4)))))),
        Positioned(
            bottom: 40,
            left: 28,
            right: 28,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => _pc.jumpToPage(_slides.length - 1),
                    child: Text('SKIP',
                        style: GoogleFonts.inter(
                            color: isDark
                                ? Colors.white38
                                : Neon.subtext(themeMode),
                            fontSize: 12,
                            letterSpacing: 2)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 36, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32))),
                    onPressed: _next,
                    child: Text(
                        _page == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 2)),
                  ),
                ])),
      ]),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    final c = (isDark ? slide['color'] : slide['colorL']) as Color;
    return SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 180),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: c.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.4))),
                child: Text(slide['tag'] as String,
                    style: GoogleFonts.inter(
                        color: c,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3)),
              ),
              const SizedBox(height: 40),
              Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Neon.cardDark : Colors.white,
                      border: Border.all(
                          color: c.withValues(alpha: 0.55), width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: c.withValues(alpha: 0.3),
                            blurRadius: 32,
                            spreadRadius: 2)
                      ]),
                  child: Icon(slide['icon'] as IconData, size: 80, color: c)),
              const SizedBox(height: 40),
              Text(slide['title'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Neon.text(themeMode))),
              const SizedBox(height: 8),
              Text(slide['subtitle'] as String,
                  style: GoogleFonts.inter(
                      color: c,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),
              Text(slide['desc'] as String,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Neon.subtext(themeMode),
                      fontSize: 13,
                      height: 1.7)),
            ])));
  }
}

// ─────────────────────────────────────────
// PROFILE BUILDER
// ─────────────────────────────────────────

class ProfileBuilderScreen extends ConsumerStatefulWidget {
  const ProfileBuilderScreen({super.key});
  @override
  ConsumerState<ProfileBuilderScreen> createState() =>
      _ProfileBuilderScreenState();
}

class _ProfileBuilderScreenState extends ConsumerState<ProfileBuilderScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _degreeCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  String _selectedExp = 'Student';
  String _gradYear = '2025';
  String _jobType = 'Full-time';

  static const _expOptions = [
    'Student',
    'Fresh Graduate',
    '1-2 Years',
    '3-5 Years',
    '5+ Years'
  ];
  static const _yearOptions = ['2024', '2025', '2026', '2027', '2028'];
  static const _jobOptions = [
    'Full-time',
    'Part-time',
    'Freelance',
    'Remote',
    'Internship'
  ];

  void _nextStep() {
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      _showMsg('Please enter your name.', isError: true);
      return;
    }
    if (_step == 1 && _degreeCtrl.text.trim().isEmpty) {
      _showMsg('Please enter your degree.', isError: true);
      return;
    }
    if (_step == 2) {
      if (_goalCtrl.text.trim().isEmpty) {
        _showMsg('Please enter your career goal.', isError: true);
        return;
      }
      _saveAndContinue();
      return;
    }
    setState(() => _step++);
    _pageCtrl.animateToPage(_step,
        duration: 400.ms, curve: Curves.easeInOutCubic);
  }

  void _saveAndContinue() {
    final goal = _goalCtrl.text.trim();
    final degree = '${_degreeCtrl.text.trim()} — $_gradYear';
    final skills = _skillsCtrl.text.trim();
    ref
        .read(userProvider.notifier)
        .updateProfile(_nameCtrl.text.trim(), degree, goal);
    // Auto generate roadmap from profile
    ref.read(dynamicRoadmapProvider.notifier).generateAndSave(
        goal, degree, skills.isEmpty ? 'Basic programming' : skills);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainNavigationHub()));
  }

  void _showMsg(String msg, {bool isError = false}) => AwesomeDialog(
          context: context,
          dialogType: isError ? DialogType.error : DialogType.success,
          animType: AnimType.bottomSlide,
          title: isError ? 'Missing Info' : 'Done!',
          desc: msg,
          btnOkColor: Neon.purple,
          btnOkOnPress: () {})
      .show();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = Neon.text(themeMode);
    final cardColor = Neon.card(themeMode);
    final borderColor = Neon.border(themeMode);
    final c0 = isDark ? Neon.cyan : Neon.cyanL;
    final c1 = isDark ? Neon.purple : Neon.purpleL;
    final c2 = isDark ? Neon.lime : Neon.limeL;
    final stepColors = [c0, c1, c2];
    final stepTitles = ['Personal Info', 'Academic', 'Career Goals'];
    final stepIcons = [
      Icons.person_outline,
      Icons.school_outlined,
      Icons.rocket_launch_outlined
    ];

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      body: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                  children: List.generate(3, (i) {
                final done = i < _step;
                final active = i == _step;
                final c = stepColors[i];
                return Expanded(
                    child: Row(children: [
                  AnimatedContainer(
                      duration: 300.ms,
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? c
                              : (active
                                  ? c.withValues(alpha: 0.2)
                                  : borderColor),
                          border: Border.all(
                              color: active || done ? c : borderColor,
                              width: 2)),
                      child: Icon(done ? Icons.check_rounded : stepIcons[i],
                          size: 16,
                          color: done
                              ? Colors.white
                              : (active
                                  ? c
                                  : textColor.withValues(alpha: 0.35)))),
                  if (i < 2)
                    Expanded(
                        child: Container(
                            height: 2,
                            color: done ? stepColors[i] : borderColor)),
                ]));
              })),
              const SizedBox(height: 14),
              Text('Step ${_step + 1} of 3',
                  style: GoogleFonts.inter(
                      color: stepColors[_step],
                      fontSize: 11,
                      letterSpacing: 3)),
              Text(stepTitles[_step],
                  style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
            ])),
        const SizedBox(height: 10),
        Expanded(
            child: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _stepPage(cardColor, borderColor, textColor, [
              _label('Full Name *', themeMode),
              _field(_nameCtrl, 'e.g. Ali Hassan', Icons.person_outline, c0,
                  textColor),
              const SizedBox(height: 18),
              _label('Experience Level', themeMode),
              _chipGroup(_expOptions, _selectedExp, c0, isDark, themeMode,
                  (v) => setState(() => _selectedExp = v)),
            ]),
            _stepPage(cardColor, borderColor, textColor, [
              _label('Degree / Program *', themeMode),
              _field(_degreeCtrl, 'e.g. BS Computer Science',
                  Icons.school_outlined, c1, textColor),
              const SizedBox(height: 18),
              _label('Graduation Year', themeMode),
              _chipGroup(_yearOptions, _gradYear, c1, isDark, themeMode,
                  (v) => setState(() => _gradYear = v)),
            ]),
            _stepPage(cardColor, borderColor, textColor, [
              _label('Career Goal *', themeMode),
              _field(_goalCtrl, 'e.g. Flutter Developer, AI Engineer',
                  Icons.star_outline, c2, textColor),
              const SizedBox(height: 18),
              _label('Your Key Skills', themeMode),
              _field(
                  _skillsCtrl,
                  'e.g. Dart, Python, Machine Learning',
                  Icons.code_rounded,
                  isDark ? Neon.pink : Neon.pinkL,
                  textColor),
              const SizedBox(height: 18),
              _label('Preferred Job Type', themeMode),
              _chipGroup(_jobOptions, _jobType, c2, isDark, themeMode,
                  (v) => setState(() => _jobType = v)),
            ]),
          ],
        )),
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
            child: Row(children: [
              if (_step > 0)
                GestureDetector(
                  onTap: () {
                    setState(() => _step--);
                    _pageCtrl.animateToPage(_step,
                        duration: 400.ms, curve: Curves.easeInOutCubic);
                  },
                  child: Container(
                      width: 52,
                      height: 52,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                          color: cardColor),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: textColor.withValues(alpha: 0.5))),
                ),
              Expanded(
                  child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: stepColors[_step],
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                onPressed: _nextStep,
                child: Text(_step == 2 ? 'COMPLETE PROFILE' : 'NEXT',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 2,
                        color: Colors.white)),
              )),
            ])),
      ])),
    );
  }

  Widget _stepPage(Color cardColor, Color borderColor, Color textColor,
          List<Widget> children) =>
      SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children)));

  Widget _label(String text, ThemeMode m) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: Neon.subtext(m))));

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
          Color col, Color textColor) =>
      TextField(
          controller: ctrl,
          style: GoogleFonts.inter(color: textColor, fontSize: 14),
          decoration: InputDecoration(
              prefixIcon: Icon(icon, color: col, size: 20), hintText: hint));

  Widget _chipGroup(List<String> opts, String selected, Color ac, bool isDark,
          ThemeMode m, ValueChanged<String> onTap) =>
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: opts.map((o) {
            final isSel = o == selected;
            return GestureDetector(
                onTap: () => onTap(o),
                child: AnimatedContainer(
                    duration: 200.ms,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: isSel
                            ? ac.withValues(alpha: isDark ? 0.2 : 0.14)
                            : Neon.card2(m),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? ac : Neon.border(m),
                            width: isSel ? 1.5 : 1)),
                    child: Text(o,
                        style: GoogleFonts.inter(
                            color: isSel ? ac : Neon.subtext(m),
                            fontSize: 12,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w400))));
          }).toList());
}

// ─────────────────────────────────────────
// MAIN NAVIGATION HUB
// ─────────────────────────────────────────

class MainNavigationHub extends ConsumerStatefulWidget {
  const MainNavigationHub({super.key});
  @override
  ConsumerState<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends ConsumerState<MainNavigationHub> {
  int _idx = 0;
  final List<Widget> _tabs = [
    const DashboardHome(),
    const DynamicRoadmapScreen(),
    const ChatScreen(),
    const AdaptiveQuizScreen(),
    const SettingsScreen(),
  ];
  final _titles = [
    'Dashboard',
    'My Roadmap',
    'AI Chatbot',
    'Skill Quiz',
    'Settings'
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_idx]),
        actions: [
          IconButton(
            icon: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                color: isDark ? Neon.cyan : Neon.cyanL),
            onPressed: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).state = newMode;
              StorageService.saveTheme(newMode == ThemeMode.dark);
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
          duration: 320.ms,
          child: KeyedSubtree(key: ValueKey(_idx), child: _tabs[_idx])),
      bottomNavigationBar: CurvedNavigationBar(
        index: _idx,
        height: 62,
        items: const [
          Icon(Icons.grid_view_rounded, size: 26, color: Colors.white),
          Icon(Icons.map_outlined, size: 26, color: Colors.white),
          Icon(Icons.psychology_outlined, size: 26, color: Colors.white),
          Icon(Icons.quiz_outlined, size: 26, color: Colors.white),
          Icon(Icons.settings_outlined, size: 26, color: Colors.white),
        ],
        color: Theme.of(context).cardColor,
        buttonBackgroundColor: isDark ? Neon.purple : Neon.purpleL,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOutCubic,
        animationDuration: 380.ms,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DASHBOARD
// ─────────────────────────────────────────

class DashboardHome extends ConsumerStatefulWidget {
  const DashboardHome({super.key});
  @override
  ConsumerState<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends ConsumerState<DashboardHome> {
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider);
      ref
          .read(dailyTipProvider.notifier)
          .loadTip(user['goal'] ?? 'Software Development');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final notes = ref.watch(notesProvider);
    final quizScore = ref.watch(quizScoreProvider);
    final themeMode = ref.watch(themeModeProvider);
    final dailyTip = ref.watch(dailyTipProvider);
    final isDark = themeMode == ThemeMode.dark;
    final textColor = Neon.text(themeMode);
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final acPink = isDark ? Neon.pink : Neon.pinkL;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('WELCOME BACK,',
                    style: GoogleFonts.inter(
                        color: acCyan, fontSize: 10, letterSpacing: 3)),
                const SizedBox(height: 4),
                Text(user['name']!.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: textColor)),
                Text(user['goal']!,
                    style: GoogleFonts.inter(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 11,
                        letterSpacing: 2)),
              ])),
          Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: acPurple.withValues(alpha: 0.5), width: 2),
                  color: acPurple.withValues(alpha: 0.15)),
              child: Icon(Icons.person_rounded, color: acPurple, size: 28)),
        ]).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 20),
        if (dailyTip.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: acLime.withValues(alpha: isDark ? 0.08 : 0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: acLime.withValues(alpha: 0.35))),
            child: Row(children: [
              Icon(Icons.lightbulb_outline, color: acLime, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(dailyTip,
                      style: GoogleFonts.inter(
                          color: textColor, fontSize: 12, height: 1.5))),
            ]),
          ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
        Row(children: [
          _statChip('Quiz Score', '$quizScore pts', acLime,
              Icons.emoji_events_outlined, themeMode),
          const SizedBox(width: 12),
          _statChip('Notes', '${notes.length}', acPink,
              Icons.sticky_note_2_outlined, themeMode),
          const SizedBox(width: 12),
          _statChip(
              'AI Tools', '6', acCyan, Icons.auto_awesome_outlined, themeMode),
        ]),
        const SizedBox(height: 30),
        _sectionTitle('CAREER MATCHES', acLime),
        const SizedBox(height: 14),
        const CareerMatchSection(),
        const SizedBox(height: 30),
        _sectionTitle('AI TOOLS', acLime),
        const SizedBox(height: 14),
        Row(children: [
          _aiToolCard(
              'Resume\nAnalyzer',
              Icons.description_outlined,
              acCyan,
              themeMode,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ResumeAnalyzerScreen()))),
          const SizedBox(width: 12),
          _aiToolCard(
              'Interview\nCoach',
              Icons.record_voice_over_outlined,
              acPurple,
              themeMode,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const InterviewCoachScreen()))),
          const SizedBox(width: 12),
          _aiToolCard(
              'Salary\nEstimator',
              Icons.attach_money_rounded,
              acLime,
              themeMode,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SalaryEstimatorScreen()))),
        ]),
        const SizedBox(height: 30),
        _sectionTitle('PERFORMANCE', acLime),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: acPurple.withValues(alpha: 0.2))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Career Readiness',
                  style: GoogleFonts.inter(fontSize: 13, color: textColor)),
              Text('${quizScore > 0 ? ((quizScore / 300) * 100).round() : 0}%',
                  style: GoogleFonts.inter(
                      color: acLime, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                    value: quizScore > 0 ? quizScore / 300 : 0,
                    minHeight: 12,
                    color: acLime,
                    backgroundColor: Colors.black12)),
          ]),
        ).animate().fadeIn(delay: 150.ms),
        const SizedBox(height: 30),
        _sectionTitle('SAVED NOTES', acLime),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: TextField(
            controller: _noteCtrl,
            style: GoogleFonts.inter(color: textColor, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Add a career note...',
              hintStyle:
                  GoogleFonts.inter(color: Neon.hint(themeMode), fontSize: 12),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: acCyan)),
            ),
          )),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              ref.read(notesProvider.notifier).addNote(_noteCtrl.text);
              _noteCtrl.clear();
            },
            child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: acPurple,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: acPurple.withValues(alpha: 0.4),
                          blurRadius: 12)
                    ]),
                child: const Icon(Icons.add, color: Colors.white, size: 22)),
          ),
        ]),
        const SizedBox(height: 14),
        if (notes.isEmpty)
          Center(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No notes yet. Add your first one!',
                      style: GoogleFonts.inter(
                          color: Neon.hint(themeMode), fontSize: 12))))
        else
          ...notes
              .asMap()
              .entries
              .map((e) => _noteItem(e.key, e.value, themeMode, acCyan)),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _aiToolCard(String label, IconData icon, Color color, ThemeMode m,
          VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.35))),
                child: Column(children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
              ).animate().scale(delay: 100.ms, curve: Curves.easeOutBack)));

  Widget _sectionTitle(String t, Color c) => Text(t,
      style: GoogleFonts.inter(
          color: c,
          fontSize: 11,
          letterSpacing: 4,
          fontWeight: FontWeight.w700));

  Widget _statChip(String label, String value, Color color, IconData icon,
          ThemeMode m) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.28))),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.inter(
                  color: Neon.hint(m), fontSize: 9, letterSpacing: 1)),
        ]),
      ).animate().fadeIn().scale(delay: 100.ms, curve: Curves.easeOutBack));

  Widget _noteItem(int index, String note, ThemeMode m, Color acCyan) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: acCyan.withValues(alpha: 0.18))),
        child: Row(children: [
          Icon(Icons.sticky_note_2_outlined, color: acCyan, size: 18),
          const SizedBox(width: 12),
          Expanded(
              child: Text(note,
                  style: GoogleFonts.inter(color: Neon.text(m), fontSize: 13))),
          GestureDetector(
              onTap: () => ref.read(notesProvider.notifier).deleteNote(index),
              child: Icon(Icons.close_rounded, color: Neon.hint(m), size: 18)),
        ]),
      ).animate().fadeIn().slideX(begin: 0.1);
}

// ─────────────────────────────────────────
// CAREER MATCH SECTION
// ─────────────────────────────────────────

class CareerMatchSection extends ConsumerStatefulWidget {
  const CareerMatchSection({super.key});
  @override
  ConsumerState<CareerMatchSection> createState() => _CareerMatchSectionState();
}

class _CareerMatchSectionState extends ConsumerState<CareerMatchSection> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final matches = ref.read(careerMatchProvider);
    if (matches.isNotEmpty) return;
    final user = ref.read(userProvider);
    if (user['goal'] == 'Not Set') return;
    setState(() => _loading = true);
    await ref.read(careerMatchProvider.notifier).generateMatches(
        user['degree'] ?? 'BS CS',
        user['goal'] ?? 'Software Engineer',
        'Dart, Flutter, Firebase');
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(careerMatchProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acLime = isDark ? Neon.lime : Neon.limeL;

    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: acPurple.withValues(alpha: 0.2))),
        child: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(color: acPurple, strokeWidth: 2)),
          const SizedBox(width: 12),
          Text('AI calculating your career matches...',
              style: GoogleFonts.inter(
                  color: Neon.subtext(themeMode), fontSize: 12)),
        ]),
      );
    }

    if (matches.isEmpty) {
      return GestureDetector(
          onTap: _load,
          child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: acPurple.withValues(alpha: 0.3))),
              child: Row(children: [
                Icon(Icons.auto_awesome, color: acPurple, size: 20),
                const SizedBox(width: 12),
                Text('Tap to generate AI career matches',
                    style: GoogleFonts.inter(
                        color: Neon.subtext(themeMode), fontSize: 13)),
              ])));
    }

    return Column(
        children: matches.map((m) {
      final color = m.percentage >= 90
          ? acLime
          : m.percentage >= 75
              ? acCyan
              : acPurple;
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25))),
        child: Column(children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(m.icon, color: color, size: 22)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(m.role,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Neon.text(themeMode))),
                  const SizedBox(height: 4),
                  Text(m.reason,
                      style: GoogleFonts.inter(
                          color: Neon.subtext(themeMode), fontSize: 11)),
                ])),
            Text('${m.percentage}%',
                style: GoogleFonts.inter(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                  value: m.percentage / 100,
                  minHeight: 5,
                  color: color,
                  backgroundColor: Colors.black12)),
        ]),
      )
          .animate()
          .slideX(begin: 0.18, duration: 420.ms, curve: Curves.easeOutCubic);
    }).toList());
  }
}

// ─────────────────────────────────────────
// RESUME ANALYZER
// ─────────────────────────────────────────

class ResumeAnalyzerScreen extends ConsumerStatefulWidget {
  const ResumeAnalyzerScreen({super.key});
  @override
  ConsumerState<ResumeAnalyzerScreen> createState() =>
      _ResumeAnalyzerScreenState();
}

class _ResumeAnalyzerScreenState extends ConsumerState<ResumeAnalyzerScreen> {
  final _ctrl = TextEditingController();
  String _result = '';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final textColor = Neon.text(themeMode);

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      appBar: AppBar(
          title: const Text('AI Resume Analyzer'),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            TextField(
                controller: _ctrl,
                maxLines: 10,
                style: GoogleFonts.inter(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste your resume text here...',
                  hintStyle: GoogleFonts.inter(
                      color: Neon.hint(themeMode), fontSize: 12),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: acCyan)),
                )),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: acPurple,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: _loading
                  ? null
                  : () async {
                      if (_ctrl.text.trim().isEmpty) return;
                      setState(() => _loading = true);
                      final result = await AnthropicService.analyzeResume(
                          _ctrl.text.trim());
                      if (mounted) {
                        setState(() {
                          _result = result;
                          _loading = false;
                        });
                      }
                    },
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 18),
              label: Text(_loading ? 'Analyzing...' : 'Analyze My Resume',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: acCyan.withValues(alpha: 0.3))),
                child: Text(_result,
                    style: GoogleFonts.inter(
                        color: textColor, fontSize: 13, height: 1.6)),
              ).animate().fadeIn(),
            ],
          ])),
    );
  }
}

// ─────────────────────────────────────────
// INTERVIEW COACH
// ─────────────────────────────────────────

class InterviewCoachScreen extends ConsumerStatefulWidget {
  const InterviewCoachScreen({super.key});
  @override
  ConsumerState<InterviewCoachScreen> createState() =>
      _InterviewCoachScreenState();
}

class _InterviewCoachScreenState extends ConsumerState<InterviewCoachScreen> {
  String _result = '';
  bool _loading = false;
  String _difficulty = 'Beginner';
  static const _difficulties = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final textColor = Neon.text(themeMode);

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      appBar: AppBar(
          title: const Text('AI Interview Coach'),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: acPurple.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: acPurple.withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(Icons.work_outline, color: acPurple, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Role: ${user['goal']}',
                          style: GoogleFonts.inter(
                              color: acPurple,
                              fontWeight: FontWeight.w700,
                              fontSize: 14))),
                ])),
            const SizedBox(height: 20),
            Row(
                children: _difficulties.map((d) {
              final isSel = d == _difficulty;
              return Expanded(
                  child: GestureDetector(
                      onTap: () => setState(() => _difficulty = d),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color:
                                isSel ? acPurple : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    isSel ? acPurple : Neon.border(themeMode))),
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                                color: isSel
                                    ? Colors.white
                                    : Neon.subtext(themeMode),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      )));
            }).toList()),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: acPurple,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final result =
                          await AnthropicService.getInterviewQuestion(
                              user['goal'] ?? 'Software Engineer', _difficulty);
                      if (mounted) {
                        setState(() {
                          _result = result;
                          _loading = false;
                        });
                      }
                    },
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.record_voice_over_outlined,
                      color: Colors.white, size: 18),
              label: Text(_loading ? 'Generating...' : 'Get Interview Question',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: acCyan.withValues(alpha: 0.3))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_result,
                            style: GoogleFonts.inter(
                                color: textColor, fontSize: 14, height: 1.7)),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () async {
                            setState(() => _loading = true);
                            final result =
                                await AnthropicService.getInterviewQuestion(
                                    user['goal'] ?? 'Software Engineer',
                                    _difficulty);
                            if (mounted) {
                              setState(() {
                                _result = result;
                                _loading = false;
                              });
                            }
                          },
                          icon: Icon(Icons.refresh_rounded,
                              color: acCyan, size: 16),
                          label: Text('Next Question',
                              style: GoogleFonts.inter(color: acCyan)),
                        ),
                      ])),
            ],
          ])),
    );
  }
}

// ─────────────────────────────────────────
// SALARY ESTIMATOR
// ─────────────────────────────────────────

class SalaryEstimatorScreen extends ConsumerStatefulWidget {
  const SalaryEstimatorScreen({super.key});
  @override
  ConsumerState<SalaryEstimatorScreen> createState() =>
      _SalaryEstimatorScreenState();
}

class _SalaryEstimatorScreenState extends ConsumerState<SalaryEstimatorScreen> {
  final _roleCtrl = TextEditingController();
  String _experience = '0-1 Year';
  String _city = 'Lahore';
  String _result = '';
  bool _loading = false;

  static const _experiences = [
    '0-1 Year',
    '1-2 Years',
    '2-3 Years',
    '3-5 Years',
    '5+ Years'
  ];
  static const _cities = [
    'Lahore',
    'Karachi',
    'Islamabad',
    'Rawalpindi',
    'Remote'
  ];

  @override
  void initState() {
    super.initState();
    _roleCtrl.text = ref.read(userProvider)['goal'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final textColor = Neon.text(themeMode);

    return Scaffold(
      backgroundColor: Neon.bg(themeMode),
      appBar: AppBar(
          title: const Text('AI Salary Estimator'),
          backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Job Role',
                style: GoogleFonts.inter(
                    color: Neon.subtext(themeMode),
                    fontSize: 11,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            TextField(
                controller: _roleCtrl,
                style: GoogleFonts.inter(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Flutter Developer',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: acLime)),
                )),
            const SizedBox(height: 20),
            Text('Experience',
                style: GoogleFonts.inter(
                    color: Neon.subtext(themeMode),
                    fontSize: 11,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _experiences.map((e) {
                  final isSel = e == _experience;
                  return GestureDetector(
                      onTap: () => setState(() => _experience = e),
                      child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: isSel
                                  ? acLime.withValues(alpha: 0.15)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      isSel ? acLime : Neon.border(themeMode))),
                          child: Text(e,
                              style: GoogleFonts.inter(
                                  color:
                                      isSel ? acLime : Neon.subtext(themeMode),
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.normal))));
                }).toList()),
            const SizedBox(height: 20),
            Text('City',
                style: GoogleFonts.inter(
                    color: Neon.subtext(themeMode),
                    fontSize: 11,
                    letterSpacing: 2)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _cities.map((c) {
                  final isSel = c == _city;
                  return GestureDetector(
                      onTap: () => setState(() => _city = c),
                      child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: isSel
                                  ? acPurple.withValues(alpha: 0.15)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSel
                                      ? acPurple
                                      : Neon.border(themeMode))),
                          child: Text(c,
                              style: GoogleFonts.inter(
                                  color: isSel
                                      ? acPurple
                                      : Neon.subtext(themeMode),
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.w700
                                      : FontWeight.normal))));
                }).toList()),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: acLime,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final result = await AnthropicService.estimateSalary(
                          _roleCtrl.text.trim().isEmpty
                              ? 'Software Engineer'
                              : _roleCtrl.text.trim(),
                          _experience,
                          _city);
                      if (mounted) {
                        setState(() {
                          _result = result;
                          _loading = false;
                        });
                      }
                    },
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Icon(Icons.attach_money_rounded,
                      color: isDark ? Colors.black : Colors.white, size: 20),
              label: Text(_loading ? 'Estimating...' : 'Estimate My Salary',
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: acLime.withValues(alpha: 0.3))),
                child: Text(_result,
                    style: GoogleFonts.inter(
                        color: textColor, fontSize: 13, height: 1.6)),
              ).animate().fadeIn(),
            ],
          ])),
    );
  }
}

// ─────────────────────────────────────────
// DYNAMIC ROADMAP SCREEN
// ─────────────────────────────────────────

class DynamicRoadmapScreen extends ConsumerStatefulWidget {
  const DynamicRoadmapScreen({super.key});
  @override
  ConsumerState<DynamicRoadmapScreen> createState() =>
      _DynamicRoadmapScreenState();
}

class _DynamicRoadmapScreenState extends ConsumerState<DynamicRoadmapScreen> {
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final steps = ref.watch(dynamicRoadmapProvider);
    final progress = ref.watch(roadmapProgressProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final textColor = Neon.text(themeMode);

    final totalProgress = progress.values.isEmpty
        ? 0
        : progress.values.reduce((a, b) => a + b) ~/
            (steps.isEmpty ? 5 : steps.length);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: acLime.withValues(alpha: isDark ? 0.08 : 0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: acLime.withValues(alpha: 0.3))),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                    child: Text('${user['goal']}',
                        style: GoogleFonts.inter(
                            color: acLime, fontSize: 12, letterSpacing: 2))),
                Text('$totalProgress% Done',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, color: acLime)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: totalProgress / 100,
                      minHeight: 12,
                      color: acLime,
                      backgroundColor: Colors.black12)),
            ]),
          ).animate().fadeIn().slideY(begin: -0.2),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: acPurple,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: _generating
                ? null
                : () async {
                    setState(() => _generating = true);
                    await ref
                        .read(dynamicRoadmapProvider.notifier)
                        .generateAndSave(
                            user['goal'] ?? 'Flutter Developer',
                            user['degree'] ?? 'BS CS',
                            'Dart, Flutter, Firebase');
                    if (mounted) setState(() => _generating = false);
                  },
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            label: Text(
                _generating
                    ? 'AI Generating Your Roadmap...'
                    : steps.isEmpty
                        ? 'Generate My Personal Roadmap'
                        : 'Regenerate Roadmap',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ).animate().fadeIn(),
          const SizedBox(height: 20),
          if (steps.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, i) {
                final step = steps[i];
                final prog = progress[i] ?? 0;
                return GestureDetector(
                  onTap: () => _showProgressDialog(
                      context, ref, i, step.title, themeMode),
                  child: IntrinsicHeight(
                      child: Row(children: [
                    Column(children: [
                      AnimatedContainer(
                          duration: 300.ms,
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: prog == 100
                                  ? acLime
                                  : acCyan.withValues(alpha: 0.2),
                              border: Border.all(
                                  color: prog == 100 ? acLime : acCyan,
                                  width: 2)),
                          child: Icon(
                              prog == 100 ? Icons.check : Icons.play_arrow,
                              color: Colors.white,
                              size: 14)),
                      if (i != steps.length - 1)
                        Expanded(
                            child: Container(
                                width: 2,
                                color: acCyan.withValues(alpha: 0.3))),
                    ]),
                    const SizedBox(width: 18),
                    Expanded(
                        child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: acCyan.withValues(alpha: 0.25))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: Text(step.title,
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: textColor,
                                              fontSize: 14))),
                                  Text('$prog%',
                                      style: GoogleFonts.inter(
                                          color: prog == 100 ? acLime : acCyan,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ]),
                            const SizedBox(height: 4),
                            Text(step.description,
                                style: GoogleFonts.inter(
                                    color: Neon.subtext(themeMode),
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: step.skills
                                    .map((skill) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: acPurple.withValues(
                                                alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: acPurple.withValues(
                                                    alpha: 0.3))),
                                        child: Text(skill,
                                            style: GoogleFonts.inter(
                                                color: acPurple,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700))))
                                    .toList()),
                            const SizedBox(height: 8),
                            Row(children: [
                              Icon(Icons.schedule_rounded,
                                  color: acCyan, size: 12),
                              const SizedBox(width: 4),
                              Text(step.duration,
                                  style: GoogleFonts.inter(
                                      color: acCyan, fontSize: 11)),
                              const Spacer(),
                              Text('Tap to update',
                                  style: GoogleFonts.inter(
                                      color: acCyan.withValues(alpha: 0.45),
                                      fontSize: 10)),
                            ]),
                            if (prog > 0 && prog < 100) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                      value: prog / 100,
                                      minHeight: 8,
                                      color: acLime,
                                      backgroundColor: Colors.black12)),
                            ],
                            // DAILY TASKS
                            if (step.dailyTasks.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Icon(Icons.checklist_rounded,
                                    color: acLime, size: 13),
                                const SizedBox(width: 4),
                                Text('DAILY TASKS',
                                    style: GoogleFonts.inter(
                                        color: acLime,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 6),
                              ...step.dailyTasks.map((task) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                                color: acLime,
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(task,
                                                style: GoogleFonts.inter(
                                                    color: textColor,
                                                    fontSize: 11,
                                                    height: 1.4))),
                                      ]))),
                            ],
                            // RESOURCES
                            if (step.resources.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(children: [
                                Icon(Icons.link_rounded,
                                    color: acCyan, size: 13),
                                const SizedBox(width: 4),
                                Text('RESOURCES',
                                    style: GoogleFonts.inter(
                                        color: acCyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5)),
                              ]),
                              const SizedBox(height: 6),
                              ...step.resources.map((res) => Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.open_in_new_rounded,
                                            color: acCyan, size: 12),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(res,
                                                style: GoogleFonts.inter(
                                                    color: acCyan,
                                                    fontSize: 11,
                                                    height: 1.4,
                                                    decoration: TextDecoration
                                                        .underline))),
                                      ]))),
                            ],
                          ]),
                    )),
                  ])),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 80));
              },
            ),
        ]));
  }

  void _showProgressDialog(BuildContext ctx, WidgetRef ref, int index,
      String title, ThemeMode themeMode) {
    double val = (ref.read(roadmapProgressProvider)[index] ?? 0).toDouble();
    final isDark = themeMode == ThemeMode.dark;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    showDialog(
        context: ctx,
        builder: (c) => StatefulBuilder(
              builder: (c, setS) => AlertDialog(
                backgroundColor: Neon.card(themeMode),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text('Update: $title',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Neon.text(themeMode))),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${val.round()}%',
                      style: GoogleFonts.inter(
                          fontSize: 28,
                          color: acLime,
                          fontWeight: FontWeight.w700)),
                  Slider(
                      value: val,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: acLime,
                      inactiveColor: Colors.black12,
                      onChanged: (v) => setS(() => val = v)),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('CANCEL',
                          style:
                              GoogleFonts.inter(color: Neon.hint(themeMode)))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Neon.purple : Neon.purpleL,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      ref
                          .read(roadmapProgressProvider.notifier)
                          .updateProgress(index, val.round());
                      Navigator.pop(c);
                    },
                    child: Text('SAVE',
                        style: GoogleFonts.inter(color: Colors.white)),
                  ),
                ],
              ),
            ));
  }
}

// ─────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<Map<String, dynamic>> _msgs = [
    {
      'text':
          'Assalam o Alaikum! 👋 I\'m your AI Career Strategist.\n\nAsk me about career paths, skills, resume tips, salary, or interview prep!',
      'isU': false,
      'time': _nowTime()
    }
  ];
  final List<Map<String, String>> _apiHistory = [];
  final TextEditingController _tc = TextEditingController();
  final ScrollController _sc = ScrollController();
  bool _loading = false;

  static String _nowTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _send() async {
    if (_tc.text.trim().isEmpty || _loading) return;
    final text = _tc.text.trim();
    setState(() {
      _msgs.add({'text': text, 'isU': true, 'time': _nowTime()});
      _loading = true;
      _tc.clear();
    });
    _scrollDown();
    _apiHistory.add({'role': 'user', 'content': text});
    final response = await AnthropicService.sendMessage(List.from(_apiHistory));
    _apiHistory.add({'role': 'assistant', 'content': response});
    if (!mounted) return;
    setState(() {
      _msgs.add({'text': response, 'isU': false, 'time': _nowTime()});
      _loading = false;
    });
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(100.ms, () {
      if (_sc.hasClients) {
        _sc.animateTo(_sc.position.maxScrollExtent,
            duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final textColor = Neon.text(themeMode);

    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: [
              'Career Path',
              'Resume Tips',
              'Interview',
              'Salary',
              'Freelance'
            ]
                    .map((label) => GestureDetector(
                          onTap: () {
                            if (!_loading) {
                              _tc.text =
                                  'Tell me about $label for Pakistani tech professionals';
                              _send();
                            }
                          },
                          child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                  color: acPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: acPurple.withValues(alpha: 0.4))),
                              child: Text(label,
                                  style: GoogleFonts.inter(
                                      color: acCyan, fontSize: 11))),
                        ))
                    .toList()),
          )),
      const SizedBox(height: 6),
      Expanded(
          child: ListView.builder(
        controller: _sc,
        padding: const EdgeInsets.all(18),
        itemCount: _msgs.length,
        itemBuilder: (context, i) =>
            _bubble(_msgs[i], themeMode, acCyan, acPurple, textColor),
      )),
      if (_loading)
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: acCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ...List.generate(
                        3,
                        (i) => Container(
                                width: 6,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                    color: acCyan, shape: BoxShape.circle))
                            .animate(onPlay: (c) => c.repeat())
                            .fadeIn(
                                delay: Duration(milliseconds: i * 180),
                                duration: 350.ms)
                            .then()
                            .fadeOut(duration: 350.ms)),
                    const SizedBox(width: 8),
                    Text('Claude is thinking...',
                        style: GoogleFonts.inter(
                            color: acCyan, fontSize: 10, letterSpacing: 1)),
                  ])),
            ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
          child: Container(
              height: 62,
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: acPurple.withValues(alpha: 0.4))),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                      controller: _tc,
                      onSubmitted: (_) => _send(),
                      style: GoogleFonts.inter(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                          hintText: 'Ask Claude AI about your career...',
                          hintStyle: GoogleFonts.inter(
                              fontSize: 12, color: Neon.hint(themeMode)),
                          border: InputBorder.none),
                    )),
                    GestureDetector(
                        onTap: _send,
                        child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                                color: _loading
                                    ? acPurple.withValues(alpha: 0.4)
                                    : acPurple,
                                borderRadius: BorderRadius.circular(10)),
                            child: Icon(
                                _loading
                                    ? Icons.hourglass_empty_rounded
                                    : Icons.send_rounded,
                                color: Colors.white,
                                size: 18))),
                  ])))),
    ]);
  }

  Widget _bubble(Map<String, dynamic> m, ThemeMode tm, Color acCyan,
      Color acPurple, Color textColor) {
    final isU = m['isU'] as bool;
    final isDark = tm == ThemeMode.dark;
    return Align(
      alignment: isU ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isU
              ? acPurple.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark ? Neon.cardDark : Neon.card2Light),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isU ? const Radius.circular(20) : Radius.zero,
            bottomRight: isU ? Radius.zero : const Radius.circular(20),
          ),
          border: Border.all(
              color: isU
                  ? acPurple.withValues(alpha: 0.45)
                  : acCyan.withValues(alpha: 0.18)),
        ),
        child: Column(
            crossAxisAlignment:
                isU ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isU)
                Row(children: [
                  Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: acPurple.withValues(alpha: 0.2)),
                      child: Icon(Icons.psychology_alt_rounded,
                          size: 12, color: acPurple)),
                  Text('AI Strategist',
                      style: GoogleFonts.inter(
                          color: acPurple,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700)),
                ]),
              if (!isU) const SizedBox(height: 6),
              Text(m['text'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.65, color: textColor)),
              const SizedBox(height: 6),
              Text(m['time'] as String,
                  style: GoogleFonts.inter(color: Neon.hint(tm), fontSize: 9)),
            ]),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────
// ADAPTIVE QUIZ SCREEN
// ─────────────────────────────────────────

class AdaptiveQuizScreen extends ConsumerStatefulWidget {
  const AdaptiveQuizScreen({super.key});
  @override
  ConsumerState<AdaptiveQuizScreen> createState() => _AdaptiveQuizScreenState();
}

class _AdaptiveQuizScreenState extends ConsumerState<AdaptiveQuizScreen>
    with SingleTickerProviderStateMixin {
  List<ShuffledQuestion> _bank = [];
  int _currentIdx = 0;
  int _localScore = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;
  bool _loading = true;
  bool _showHistory = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: 400.ms);
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuiz());
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    if (mounted) setState(() => _loading = true);
    try {
      final user = ref.read(userProvider);
      final history = ref.read(quizHistoryProvider);
      final steps = ref.read(dynamicRoadmapProvider);
      final goal = user['goal'] ?? 'Software Development';
      String topic = steps.isNotEmpty ? steps[0].title : goal;
      final diff = history.isEmpty
          ? 'beginner'
          : history.length >= 3 && (history.last['score'] as int) > 200
              ? 'advanced'
              : 'intermediate';
      final questions =
          await AnthropicService.generateAdaptiveQuiz(topic, diff, goal);
      if (mounted) {
        setState(() {
          _bank = questions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectAnswer(int selected) {
    if (_answered) return;
    setState(() {
      _selected = selected;
      _answered = true;
    });
    if (selected != _bank[_currentIdx].correctIndex) {
      _shakeCtrl.forward(from: 0);
    }
    Future.delayed(950.ms, () {
      if (!mounted) return;
      if (selected == _bank[_currentIdx].correctIndex) {
        _localScore += 10;
        ref.read(quizScoreProvider.notifier).setScore(_localScore);
      }
      setState(() {
        if (_currentIdx < _bank.length - 1) {
          _currentIdx++;
          _selected = null;
          _answered = false;
        } else {
          _finished = true;
          final now = DateTime.now();
          ref
              .read(quizHistoryProvider.notifier)
              .addResult(_localScore, '${now.day}/${now.month}/${now.year}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(quizHistoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final textColor = Neon.text(themeMode);

    if (_showHistory) return _historyUI(history, themeMode);
    if (_loading) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: acPurple),
        const SizedBox(height: 16),
        Text('AI preparing your quiz...',
            style: GoogleFonts.inter(
                color: Neon.subtext(themeMode), fontSize: 13)),
      ]));
    }
    if (_finished) return _resultUI(history, themeMode);
    if (_bank.isEmpty) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: acCyan, size: 48),
        const SizedBox(height: 16),
        Text('Could not load quiz.',
            style: GoogleFonts.inter(color: textColor)),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: _loadQuiz,
            style: ElevatedButton.styleFrom(backgroundColor: acPurple),
            child:
                Text('Retry', style: GoogleFonts.inter(color: Colors.white))),
      ]));
    }

    final q = _bank[_currentIdx];
    final pct = (_currentIdx + 1) / _bank.length;

    return SafeArea(
        child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Q ${_currentIdx + 1}/${_bank.length}',
              style: GoogleFonts.inter(
                  color: acCyan,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () => setState(() => _showHistory = true),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(color: acPurple.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.history_rounded, color: acPurple, size: 14),
                  const SizedBox(width: 6),
                  Text('History (${history.length})',
                      style: GoogleFonts.inter(color: acPurple, fontSize: 11)),
                ])),
          ),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                color: acPurple,
                backgroundColor: Colors.black12)),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Neon.card(themeMode),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: acPurple.withValues(alpha: 0.4), width: 1.5)),
          child: Text(q.question,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 16, color: textColor, height: 1.55)),
        ).animate().fadeIn(),
        const SizedBox(height: 32),
        ...List.generate(q.shuffledOpts.length, (i) {
          Color border = Neon.border(themeMode);
          Color bg = Colors.transparent;
          IconData? icon;
          bool isWrong = false;
          bool isCorrect = false;
          if (_answered && _selected != null) {
            if (i == q.correctIndex) {
              border = isDark ? Neon.lime : Neon.limeL;
              bg = (isDark ? Neon.lime : Neon.limeL).withValues(alpha: 0.10);
              icon = Icons.check_circle_rounded;
              isCorrect = true;
            } else if (i == _selected && i != q.correctIndex) {
              border = Colors.red;
              bg = Colors.red.withValues(alpha: 0.09);
              icon = Icons.cancel_rounded;
              isWrong = true;
            }
          }
          final opt = AnimatedContainer(
            duration: 300.ms,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: 1.5)),
            child: Row(children: [
              CircleAvatar(
                  radius: 13,
                  backgroundColor: acPurple.withValues(alpha: 0.18),
                  child: Text(String.fromCharCode(65 + i),
                      style: GoogleFonts.inter(
                          color: acCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(q.shuffledOpts[i],
                      style: GoogleFonts.inter(
                          color: textColor.withValues(alpha: 0.85),
                          fontSize: 13))),
              if (icon != null)
                Icon(icon,
                    color: isCorrect
                        ? (isDark ? Neon.lime : Neon.limeL)
                        : Colors.red,
                    size: 20),
            ]),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GestureDetector(
                onTap: () => _selectAnswer(i),
                child: isWrong
                    ? AnimatedBuilder(
                        animation: _shakeAnim,
                        builder: (_, child) => Transform.translate(
                            offset: Offset(
                                math.sin(_shakeAnim.value * math.pi * 5) * 6,
                                0),
                            child: child),
                        child: opt)
                    : opt),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
        }),
        const SizedBox(height: 16),
        Text('SCORE: $_localScore pts',
            style: GoogleFonts.inter(
                color: acLime, fontWeight: FontWeight.w700, letterSpacing: 2)),
      ]),
    ));
  }

  Widget _resultUI(List<Map<String, dynamic>> history, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    final pct =
        (_localScore / (_bank.isNotEmpty ? _bank.length * 10 : 100) * 100)
            .round();
    final color = pct >= 70
        ? (isDark ? Neon.lime : Neon.limeL)
        : pct >= 40
            ? (isDark ? Neon.orange : Neon.orangeL)
            : Colors.red;

    return Center(
        child: Padding(
            padding: const EdgeInsets.all(30),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                      pct >= 70
                          ? Icons.verified_rounded
                          : Icons.emoji_events_outlined,
                      size: 80,
                      color: color)
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('QUIZ COMPLETED',
                  style: GoogleFonts.inter(
                      letterSpacing: 5,
                      color: Neon.hint(themeMode),
                      fontSize: 13)),
              const SizedBox(height: 16),
              Text('$_localScore / ${_bank.length * 10}',
                      style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: color))
                  .animate()
                  .fadeIn(delay: 200.ms),
              Text(
                  '$pct% — ${pct >= 70 ? 'Excellent!' : pct >= 40 ? 'Good effort!' : 'Keep practicing!'}',
                  style: GoogleFonts.inter(color: color, fontSize: 14)),
              const SizedBox(height: 40),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? Neon.cyan : Neon.cyanL),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () => setState(() => _showHistory = true),
                  child: Text('HISTORY',
                      style: GoogleFonts.inter(
                          color: isDark ? Neon.cyan : Neon.cyanL)),
                )),
                const SizedBox(width: 14),
                Expanded(
                    child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Neon.purple : Neon.purpleL,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    setState(() {
                      _currentIdx = 0;
                      _localScore = 0;
                      _selected = null;
                      _answered = false;
                      _finished = false;
                    });
                    _loadQuiz();
                  },
                  child: Text('NEW QUIZ',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                )),
              ]),
            ])));
  }

  Widget _historyUI(List<Map<String, dynamic>> history, ThemeMode themeMode) {
    final isDark = themeMode == ThemeMode.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Quiz History',
              style: GoogleFonts.inter(letterSpacing: 3, fontSize: 15)),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_rounded,
                  color: isDark ? Neon.cyan : Neon.cyanL),
              onPressed: () => setState(() => _showHistory = false))),
      body: history.isEmpty
          ? Center(
              child: Text('No quiz history yet.',
                  style: GoogleFonts.inter(color: Neon.hint(themeMode))))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final h = history[history.length - 1 - i];
                final pct =
                    ((h['score'] as int) / (h['total'] as int) * 100).round();
                final c = pct >= 70
                    ? (isDark ? Neon.lime : Neon.limeL)
                    : pct >= 40
                        ? (isDark ? Neon.orange : Neon.orangeL)
                        : Colors.red;
                return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: c.withValues(alpha: 0.22))),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('$pct%',
                              style: GoogleFonts.inter(
                                  color: c,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13))),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text('${h['score']} / ${h['total']} points',
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Neon.text(themeMode))),
                            const SizedBox(height: 4),
                            Text(h['date'] as String,
                                style: GoogleFonts.inter(
                                    color: Neon.hint(themeMode), fontSize: 11)),
                          ])),
                      Icon(
                          pct >= 70
                              ? Icons.verified_rounded
                              : Icons.emoji_events_outlined,
                          color: c,
                          size: 22),
                    ])).animate().fadeIn().slideX(begin: 0.2);
              }),
    );
  }
}

// ─────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _editingProfile = false;
  late TextEditingController _nameCtrl, _degreeCtrl, _goalCtrl;
  final _newPassCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: user['name']);
    _degreeCtrl = TextEditingController(text: user['degree']);
    _goalCtrl = TextEditingController(text: user['goal']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _degreeCtrl.dispose();
    _goalCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (image != null) {
        ref.read(profilePhotoProvider.notifier).setPhoto(image.path);
        _showMsg('Profile photo updated!');
      }
    } catch (e) {
      _showMsg('Could not pick image. Check permissions.', isError: true);
    }
  }

  void _saveProfile() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showMsg('Name cannot be empty.', isError: true);
      return;
    }
    final oldGoal = ref.read(userProvider)['goal'] ?? '';
    final newGoal = _goalCtrl.text.trim();
    final degree = _degreeCtrl.text.trim();
    ref
        .read(userProvider.notifier)
        .updateProfile(_nameCtrl.text.trim(), degree, newGoal);
    setState(() => _editingProfile = false);
    if (oldGoal != newGoal && newGoal.isNotEmpty) {
      ref
          .read(dynamicRoadmapProvider.notifier)
          .generateAndSave(newGoal, degree, 'Flutter, Dart, Firebase');
      _showMsg('Profile updated! AI generating new roadmap...');
    } else {
      _showMsg('Profile updated successfully!');
    }
  }

  void _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      _showMsg('Min 6 characters.', isError: true);
      return;
    }
    final err =
        await ref.read(authProvider.notifier).changePassword(_newPassCtrl.text);
    if (err != null) {
      _showMsg(err, isError: true);
    } else {
      _newPassCtrl.clear();
      _showMsg('Password changed successfully!');
    }
  }

  void _logout() => AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelText: 'Cancel',
      btnCancelOnPress: () {},
      btnOkText: 'Logout',
      btnOkColor: Colors.red,
      btnOkOnPress: () async {
        await ref.read(authProvider.notifier).logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AuthScreen()),
            (_) => false);
      }).show();

  void _showMsg(String msg, {bool isError = false}) => AwesomeDialog(
          context: context,
          dialogType: isError ? DialogType.error : DialogType.success,
          animType: AnimType.bottomSlide,
          title: isError ? 'Error' : 'Done!',
          desc: msg,
          btnOkColor: Neon.purple,
          btnOkOnPress: () {})
      .show();

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final auth = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final photoPath = ref.watch(profilePhotoProvider);
    final isDark = themeMode == ThemeMode.dark;
    final acPurple = isDark ? Neon.purple : Neon.purpleL;
    final acCyan = isDark ? Neon.cyan : Neon.cyanL;
    final acLime = isDark ? Neon.lime : Neon.limeL;
    final acPink = isDark ? Neon.pink : Neon.pinkL;
    final textColor = Neon.text(themeMode);

    return SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('PROFILE', acLime),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Neon.border(themeMode))),
            child: _editingProfile
                ? Column(children: [
                    _settingsField('Name', _nameCtrl, acCyan, themeMode),
                    const SizedBox(height: 10),
                    _settingsField('Degree', _degreeCtrl, acLime, themeMode),
                    const SizedBox(height: 10),
                    _settingsField('Goal', _goalCtrl, acPink, themeMode),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  side:
                                      BorderSide(color: Neon.border(themeMode)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: () =>
                                  setState(() => _editingProfile = false),
                              child: Text('CANCEL',
                                  style: GoogleFonts.inter(
                                      color: Neon.subtext(themeMode),
                                      fontSize: 12)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: acPurple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              onPressed: _saveProfile,
                              child: Text('SAVE',
                                  style:
                                      GoogleFonts.inter(color: Colors.white)))),
                    ]),
                  ])
                : Row(children: [
                    GestureDetector(
                      onTap: () async => await _pickImage(ImageSource.gallery),
                      child: Stack(children: [
                        Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: acPurple.withValues(alpha: 0.6),
                                    width: 2)),
                            child: ClipOval(
                                child: photoPath != null &&
                                        photoPath.isNotEmpty &&
                                        File(photoPath).existsSync()
                                    ? Image.file(File(photoPath),
                                        fit: BoxFit.cover)
                                    : Container(
                                        color: acPurple.withValues(alpha: 0.18),
                                        child: Icon(Icons.person_rounded,
                                            color: acPurple, size: 32)))),
                        Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    color: acPurple,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Neon.bg(themeMode), width: 2)),
                                child: const Icon(Icons.camera_alt_rounded,
                                    size: 11, color: Colors.white))),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(user['name'] ?? '',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: textColor)),
                          const SizedBox(height: 3),
                          Text(
                              auth.email.isNotEmpty
                                  ? auth.email
                                  : 'Not logged in',
                              style: GoogleFonts.inter(
                                  color: Neon.hint(themeMode), fontSize: 11)),
                          const SizedBox(height: 3),
                          Text(user['goal'] ?? '',
                              style: GoogleFonts.inter(
                                  color: acCyan,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic)),
                        ])),
                    IconButton(
                        onPressed: () => setState(() => _editingProfile = true),
                        icon:
                            Icon(Icons.edit_outlined, color: acCyan, size: 20)),
                  ]),
          ),
          const SizedBox(height: 28),
          _sectionTitle('APPEARANCE', acLime),
          const SizedBox(height: 14),
          _settingsTile(
              icon:
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              iconColor: acCyan,
              title: 'Dark Mode',
              subtitle: isDark ? 'Enabled' : 'Disabled',
              themeMode: themeMode,
              trailing: Switch(
                  value: isDark,
                  activeThumbColor: acPurple,
                  onChanged: (_) {
                    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                    ref.read(themeModeProvider.notifier).state = newMode;
                    StorageService.saveTheme(newMode == ThemeMode.dark);
                  })),
          const SizedBox(height: 28),
          _sectionTitle('NOTIFICATIONS', acLime),
          const SizedBox(height: 14),
          _settingsTile(
              icon: Icons.notifications_outlined,
              iconColor: acLime,
              title: 'Push Notifications',
              subtitle: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
              themeMode: themeMode,
              trailing: Switch(
                  value: settings.notificationsEnabled,
                  activeThumbColor: acPurple,
                  onChanged: (_) async {
                    ref.read(settingsProvider.notifier).toggle('notifications');
                    if (!settings.notificationsEnabled) {
                      await NotificationService.showCareerTip();
                    } else {
                      await NotificationService.cancelAll();
                    }
                  })),
          if (auth.isLoggedIn) ...[
            const SizedBox(height: 28),
            _sectionTitle('SECURITY', acLime),
            const SizedBox(height: 14),
            Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Neon.border(themeMode))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change Password',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: textColor)),
                      const SizedBox(height: 16),
                      _settingsField('New Password (min 6 chars)', _newPassCtrl,
                          acCyan, themeMode,
                          obscure: true),
                      const SizedBox(height: 14),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: acPurple.withValues(alpha: 0.7),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14))),
                          onPressed: _changePassword,
                          child: Text('UPDATE PASSWORD',
                              style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  letterSpacing: 2))),
                    ])).animate().fadeIn(),
          ],
          const SizedBox(height: 28),
          _sectionTitle('APP INFO', acLime),
          const SizedBox(height: 14),
          _settingsTile(
              icon: Icons.info_outline_rounded,
              iconColor: acCyan,
              title: 'App Version',
              subtitle: 'v5.1.0 — AI Career Guide (Fixed)',
              themeMode: themeMode),
          const SizedBox(height: 10),
          _settingsTile(
              icon: Icons.auto_awesome,
              iconColor: acLime,
              title: 'AI Features',
              subtitle: 'Chat · Roadmap · Quiz · Resume · Interview · Salary',
              themeMode: themeMode),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.10),
                minimumSize: const Size(double.infinity, 58),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                side: BorderSide(color: Colors.red.withValues(alpha: 0.4))),
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded,
                color: Colors.redAccent, size: 20),
            label: Text('LOGOUT',
                style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3)),
          ).animate().fadeIn(),
          const SizedBox(height: 30),
        ]));
  }

  Widget _sectionTitle(String t, Color c) => Text(t,
      style: GoogleFonts.inter(
          color: c,
          fontSize: 11,
          letterSpacing: 4,
          fontWeight: FontWeight.w700));

  Widget _settingsTile(
          {required IconData icon,
          required Color iconColor,
          required String title,
          String? subtitle,
          required ThemeMode themeMode,
          Widget? trailing,
          VoidCallback? onTap}) =>
      GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Neon.border(themeMode))),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 20)),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Neon.text(themeMode))),
                      if (subtitle != null)
                        Text(subtitle,
                            style: GoogleFonts.inter(
                                color: Neon.hint(themeMode), fontSize: 11)),
                    ])),
                if (trailing != null) trailing,
              ])).animate().fadeIn().slideX(begin: 0.08));

  Widget _settingsField(
          String hint, TextEditingController ctrl, Color col, ThemeMode m,
          {bool obscure = false}) =>
      TextField(
          controller: ctrl,
          obscureText: obscure,
          style: GoogleFonts.inter(color: Neon.text(m), fontSize: 13),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: Neon.hint(m), fontSize: 12),
              filled: true,
              fillColor: Neon.card2(m),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Neon.border(m))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: col, width: 1.5))));
}

// ─────────────────────────────────────────
// QUIZ BANK (fallback)
// ─────────────────────────────────────────

final List<Map<String, dynamic>> _rawQuizBank = [
  {
    'q': "AI mein 'Overfitting' ka kya matlab hai?",
    'opts': [
      'Model fast ho jana',
      'Training data yaad karna, new data par fail',
      'Sahi predictions',
      'Memory kam lena'
    ],
    'correct': 1
  },
  {
    'q': 'LLM ka full form kya hai?',
    'opts': [
      'Long Learning Mode',
      'Linear Layer Machine',
      'Large Language Model',
      'Low Logic Model'
    ],
    'correct': 2
  },
  {
    'q': 'ChatGPT kis architecture par kaam karta hai?',
    'opts': ['RNN', 'LSTM', 'CNN', 'Transformer'],
    'correct': 3
  },
  {
    'q': 'API ka full form kya hai?',
    'opts': [
      'Apple Phone Intel',
      'Application Programming Interface',
      'Auto Program Info',
      'All Power Index'
    ],
    'correct': 1
  },
  {
    'q': 'Deep Learning inspired by kya hai?',
    'opts': ['Solar system', 'Human Brain', 'Plants', 'Waves'],
    'correct': 1
  },
  {
    'q': 'GPU AI training mein kyun use hota hai?',
    'opts': [
      'Sasta hai',
      'Parallel processing',
      'Light kam leta hai',
      'Keyboard fast karta hai'
    ],
    'correct': 1
  },
  {
    'q': 'Hugging Face kya hai?',
    'opts': ['Video Tool', 'Social App', 'AI models ka hub', 'Code editor'],
    'correct': 2
  },
  {
    'q': 'Flutter kis language mein likha jata hai?',
    'opts': ['Python', 'Java', 'Dart', 'Swift'],
    'correct': 2
  },
  {
    'q': 'Firebase kis company ka product hai?',
    'opts': ['Apple', 'Microsoft', 'Google', 'Meta'],
    'correct': 2
  },
  {
    'q': 'Riverpod kya hai Flutter mein?',
    'opts': ['UI library', 'State management', 'Database', 'Animation tool'],
    'correct': 1
  },
];
