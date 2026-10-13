// ignore_for_file: unused_element

import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import 'package:url_launcher/url_launcher.dart';
import 'package:glassmorphism/glassmorphism.dart';

// ═══════════════════════════════════════════
// PREMIUM DESIGN SYSTEM
// Aesthetic: Dark luxury + Electric accents
// Font: Outfit (display) + DM Sans (body)
// ═══════════════════════════════════════════

class D {
  // Background layers
  static const bg       = Color(0xFF060810);
  static const surface  = Color(0xFF0D1117);
  static const card     = Color(0xFF111827);
  static const card2    = Color(0xFF1A2035);
  static const elevated = Color(0xFF1E2840);

  // Electric accent palette
  static const indigo   = Color(0xFF6366F1);
  static const violet   = Color(0xFF8B5CF6);
  static const fuchsia  = Color(0xFFD946EF);
  static const cyan     = Color(0xFF06B6D4);
  static const emerald  = Color(0xFF10B981);
  static const amber    = Color(0xFFF59E0B);
  static const rose     = Color(0xFFF43F5E);

  // Text hierarchy
  static const t1 = Color(0xFFF1F5F9);
  static const t2 = Color(0xFF94A3B8);
  static const t3 = Color(0xFF475569);
  static const t4 = Color(0xFF1E293B);

  // Borders
  static const b1 = Color(0xFF1E293B);
  static const b2 = Color(0xFF334155);

  // Gradients
  static const grad1 = LinearGradient(colors:[Color(0xFF6366F1),Color(0xFF8B5CF6)], begin:Alignment.topLeft,  end:Alignment.bottomRight);
  static const grad2 = LinearGradient(colors:[Color(0xFF06B6D4),Color(0xFF6366F1)], begin:Alignment.topLeft,  end:Alignment.bottomRight);
  static const grad3 = LinearGradient(colors:[Color(0xFF10B981),Color(0xFF06B6D4)], begin:Alignment.topLeft,  end:Alignment.bottomRight);
  static const grad4 = LinearGradient(colors:[Color(0xFFD946EF),Color(0xFF6366F1)], begin:Alignment.topLeft,  end:Alignment.bottomRight);
  static const grad5 = LinearGradient(colors:[Color(0xFFF59E0B),Color(0xFFF43F5E)], begin:Alignment.topLeft,  end:Alignment.bottomRight);

  // Typography helpers
  static TextStyle display(double sz, {FontWeight fw = FontWeight.w800, Color? color}) =>
    GoogleFonts.outfit(fontSize: sz, fontWeight: fw, color: color ?? t1, letterSpacing: -.5);

  static TextStyle body(double sz, {FontWeight fw = FontWeight.w400, Color? color}) =>
    GoogleFonts.dmSans(fontSize: sz, fontWeight: fw, color: color ?? t2, height: 1.5);
}
// ── THEME AWARE COLORS (Dark + Light) ──────────────────────────
class T {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext c) =>
      isDark(c) ? D.bg : const Color(0xFFF1F5F9);
  static Color surface(BuildContext c) =>
      isDark(c) ? D.surface : Colors.white;
  static Color card(BuildContext c) =>
      isDark(c) ? D.card : Colors.white;
  static Color card2(BuildContext c) =>
      isDark(c) ? D.card2 : const Color(0xFFF8FAFC);

  static Color t1(BuildContext c) =>
      isDark(c) ? D.t1 : const Color(0xFF0F172A);
  static Color t2(BuildContext c) =>
      isDark(c) ? D.t2 : const Color(0xFF475569);
  static Color t3(BuildContext c) =>
      isDark(c) ? D.t3 : const Color(0xFF64748B);

  static Color b1(BuildContext c) =>
      isDark(c) ? D.b1 : const Color(0xFFE2E8F0);
  static Color b2(BuildContext c) =>
      isDark(c) ? D.b2 : const Color(0xFFCBD5E1);
}

// ── WIDGET HELPERS ──────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? border;
  final Gradient? gradient;
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 20,
    this.border,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: gradient == null ? (dark ? D.card : Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: border ?? (dark ? D.b1 : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? 0.25 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  const GradientText(this.text, {super.key, required this.style, required this.gradient});
  @override
  Widget build(BuildContext context) => ShaderMask(
    shaderCallback: (b) => gradient.createShader(b),
    child: Text(text, style: style.copyWith(color: Colors.white)),
  );
}

class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const PillBadge(this.label, {super.key, required this.color, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
      Text(label, style: D.body(10, fw: FontWeight.w700, color: color)),
    ]),
  );
}

class GradientButton extends StatelessWidget {
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool loading;
  final double height;
  final IconData? icon;
  const GradientButton({super.key, required this.label, required this.gradient, required this.onTap, this.loading = false, this.height = 54, this.icon});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        gradient: loading ? null : gradient,
        color: loading ? D.card2 : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: loading ? [] : [BoxShadow(color: (gradient as LinearGradient).colors.first.withOpacity(.35), blurRadius: 20, offset: const Offset(0,6))],
      ),
      child: Center(child: loading
        ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size:18, color: Colors.white), const SizedBox(width:8)],
            Text(label, style: D.display(13, fw: FontWeight.w700, color: Colors.white)),
          ])),
    ),
  );
}

// ══════════════════════════════════════════
// MODELS
// ══════════════════════════════════════════

class RoadmapStep {
  final String title, description, duration;
  final List<String> skills, resources, dailyTasks;
  RoadmapStep({required this.title, required this.description, required this.duration, required this.skills, this.resources = const [], this.dailyTasks = const []});
  factory RoadmapStep.fromJson(Map<String, dynamic> j) => RoadmapStep(title: j['title']??'', description: j['description']??'', duration: j['duration']??'2 weeks', skills: List<String>.from(j['skills']??[]), resources: List<String>.from(j['resources']??[]), dailyTasks: List<String>.from(j['dailyTasks']??[]));
  Map<String, dynamic> toJson() => {'title':title,'description':description,'duration':duration,'skills':skills,'resources':resources,'dailyTasks':dailyTasks};
}

class CareerMatch { final String role, reason; final int percentage; final IconData icon; CareerMatch({required this.role, required this.percentage, required this.reason, required this.icon}); }
class ShuffledQuestion { final String question; final List<String> shuffledOpts; final int correctIndex; ShuffledQuestion({required this.question, required this.shuffledOpts, required this.correctIndex}); }

// ══════════════════════════════════════════
// FIREBASE CONFIG (same as before)
// ══════════════════════════════════════════

const _firebaseOptions = FirebaseOptions(
  apiKey:'AIzaSyAVRy75a0058PCZyXTJSAO2Ip0XW1hywm4',
  authDomain:'ai-career-guide-b03be.firebaseapp.com',
  projectId:'ai-career-guide-b03be',
  storageBucket:'ai-career-guide-b03be.firebasestorage.app',
  messagingSenderId:'429836778807',
  appId:'1:429836778807:web:9cd27d0fe51203d0162eb2',
);

// ══════════════════════════════════════════
// FIREBASE SERVICE
// ══════════════════════════════════════════

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;
  static User?  get currentUser => _auth.currentUser;
  static String get uid         => _auth.currentUser?.uid ?? '';
  static bool   get isLoggedIn  => _auth.currentUser != null;

  static Future<String?> signup(String email, String password, String name) async {
    try {
      if (email.trim().isEmpty) return 'Email cannot be empty.';
      if (password.length < 6)  return 'Password must be at least 6 characters.';
      if (name.trim().isEmpty)  return 'Name cannot be empty.';
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      // Auth account now exists and the user is signed in. From here on, treat
      // profile-document creation as a separate, non-fatal step: a Firestore
      // rules problem must never strand a freshly created account with a
      // scary "permission denied" error and no way forward.
      try { await cred.user?.updateDisplayName(name.trim()); } catch (_) {}
      try {
        await _db.collection('users').doc(cred.user!.uid).set({
          'name': name.trim(),
          'degree': 'Not Set',
          'goal': 'Not Set',
          'email': email.trim().toLowerCase(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Most commonly a Firestore Security Rules problem (permission-denied).
        // The Auth account is already created and the user is signed in, so we
        // let signup succeed; ProfileBuilderScreen will retry writing the
        // profile (with merge:true) once the person finishes onboarding, and
        // it will succeed as soon as the rules are fixed on the Firebase side.
        debugPrint('Profile doc write failed during signup (continuing anyway): $e');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch(e.code) {
        case 'weak-password': return 'Password too weak.';
        case 'email-already-in-use': return 'Account already exists. Please login.';
        case 'invalid-email': return 'Invalid email address.';
        case 'network-request-failed': return 'No internet connection.';
        default: return e.message ?? 'Signup failed.';
      }
    } catch (e) { return e.toString(); }
  }

  static Future<String?> login(String email, String password) async {
    try {
      if (email.trim().isEmpty) return 'Please enter your email.';
      if (password.isEmpty)     return 'Please enter your password.';
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      switch(e.code) {
        case 'user-not-found':     return 'No account found. Please sign up.';
        case 'wrong-password':     return 'Incorrect password.';
        case 'invalid-credential': return 'Invalid email or password.';
        case 'too-many-requests':  return 'Too many attempts. Please wait.';
        case 'network-request-failed': return 'No internet connection.';
        default: return e.message ?? 'Login failed.';
      }
    } catch (e) { return e.toString(); }
  }

  static Future<void> logout() async { try { await _auth.signOut(); await GoogleSignIn().signOut(); } catch (_) {} }

  static Future<String?> signInWithGoogle() async {
    try {
      final gs = GoogleSignIn(scopes:['email','profile']);
      await gs.signOut();
      final gu = await gs.signIn();
      if (gu == null) return 'Cancelled.';
      final ga = await gu.authentication;
      if (ga.accessToken == null || ga.idToken == null) return 'Google auth failed.';
      final cred = await _auth.signInWithCredential(GoogleAuthProvider.credential(accessToken: ga.accessToken, idToken: ga.idToken));
      try {
        final doc = await _db.collection('users').doc(cred.user!.uid).get();
        if (!doc.exists) await _db.collection('users').doc(cred.user!.uid).set({'name':cred.user!.displayName??'User','degree':'Not Set','goal':'Not Set','email':cred.user!.email??'','createdAt':FieldValue.serverTimestamp()});
      } catch (e) {
        debugPrint('Profile doc read/write failed during Google sign-in (continuing anyway): $e');
      }
      return null;
    } on FirebaseAuthException catch (e) { return e.message ?? 'Google sign-in failed.'; }
    catch (e) { return e.toString(); }
  }

  static Future<String?> changePassword(String p) async {
    try {
      if (p.length < 6) return 'Min 6 characters.';
      await _auth.currentUser?.updatePassword(p);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') return 'Please logout and login again.';
      return e.message;
    }
  }

  static Future<void> saveProfile(String n, String d, String g) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'name':n,'degree':d,'goal':g},SetOptions(merge:true)); } catch (_) {} }
  static Future<void> saveFullProfile(String n, String d, String g, String s, String i, String c) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'name':n,'degree':d,'goal':g,'skills':s,'interests':i,'city':c},SetOptions(merge:true)); } catch (_) {} }
  static Future<Map<String,String>> loadProfile() async {
    if (uid.isEmpty) return {'name':'Future Developer','degree':'Not Set','goal':'Not Set'};
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return {'name':'Future Developer','degree':'Not Set','goal':'Not Set'};
      final d = doc.data()!;
      return {'name':d['name']??'Future Developer','degree':d['degree']??'Not Set','goal':d['goal']??'Not Set','skills':d['skills']??'','interests':d['interests']??'','city':d['city']??''};
    } catch (_) { return {'name':'Future Developer','degree':'Not Set','goal':'Not Set'}; }
  }
  static Future<void> saveNotes(List<String> n) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'notes':n},SetOptions(merge:true)); } catch (_) {} }
  static Future<List<String>> loadNotes() async { if (uid.isEmpty) return []; try { final d = await _db.collection('users').doc(uid).get(); return List<String>.from(d.data()?['notes']??[]); } catch (_) { return []; } }
  static Future<void> saveQuizHistory(List<Map<String,dynamic>> h) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'quizHistory':h},SetOptions(merge:true)); } catch (_) {} }
  static Future<List<Map<String,dynamic>>> loadQuizHistory() async { if (uid.isEmpty) return []; try { final d = await _db.collection('users').doc(uid).get(); return List<Map<String,dynamic>>.from(d.data()?['quizHistory']??[]); } catch (_) { return []; } }
  static Future<void> saveQuizScore(int s) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'quizScore':s},SetOptions(merge:true)); } catch (_) {} }
  static Future<int> loadQuizScore() async { if (uid.isEmpty) return 0; try { final d = await _db.collection('users').doc(uid).get(); return (d.data()?['quizScore']??0) as int; } catch (_) { return 0; } }
  static Future<void> saveRoadmap(Map<int,int> m) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'roadmap':m.map((k,v)=>MapEntry(k.toString(),v))},SetOptions(merge:true)); } catch (_) {} }
  static Future<Map<int,int>> loadRoadmap() async { if (uid.isEmpty) return {}; try { final d = await _db.collection('users').doc(uid).get(); final r = Map<String,dynamic>.from(d.data()?['roadmap']??{}); return r.map((k,v)=>MapEntry(int.parse(k),v as int)); } catch (_) { return {}; } }
  static Future<void> saveDynamicRoadmap(List<RoadmapStep> s) async { if (uid.isEmpty) return; try { await _db.collection('users').doc(uid).set({'dynamicRoadmap':s.map((x)=>x.toJson()).toList()},SetOptions(merge:true)); } catch (_) {} }
  static Future<List<RoadmapStep>> loadDynamicRoadmap() async { if (uid.isEmpty) return []; try { final d = await _db.collection('users').doc(uid).get(); final r = d.data()?['dynamicRoadmap'] as List?; if (r==null||r.isEmpty) return []; return r.map((e)=>RoadmapStep.fromJson(Map<String,dynamic>.from(e))).toList(); } catch (_) { return []; } }
}

// ══════════════════════════════════════════
// SERVICES
// ══════════════════════════════════════════

class NotificationService {
  static final _p = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _p.initialize(settings: const InitializationSettings(android: android, iOS: ios));
      _init = true;
    } catch (_) {}
  }

  static Future<void> scheduleDailyReminder() async {
    try {
      await _p.cancelAll();
      const androidDetails = AndroidNotificationDetails(
        'daily_quiz', 'Daily Quiz Reminder',
        channelDescription: 'Reminds you to take the daily quiz',
        importance: Importance.high, priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
      await _p.periodicallyShow(
        id: 0,
        title: '🎯 Daily Quiz Time!',
        body: 'Test your AI & tech knowledge — keep your streak going!',
        repeatInterval: RepeatInterval.daily,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
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
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
      await _p.show(id: 1, title: '💡 Career Tip', body: tip, notificationDetails: details);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try { await _p.cancelAll(); } catch (_) {}
  }
}

class StorageService {
  static SharedPreferences? _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();
  static Future<void> savePhotoPath(String v) async => await _p?.setString('photo',v);
  static String? loadPhotoPath() => _p?.getString('photo');
  static Future<void> saveTheme(bool v) async => await _p?.setBool('dark',v);
  static bool loadTheme() => _p?.getBool('dark') ?? true;
  static Future<void> setOnboardingDone() async => await _p?.setBool('onboarding',true);
  static Future<void> clearOnboarding() async => await _p?.setBool('onboarding',false);
  static bool isOnboardingDone() => _p?.getBool('onboarding') ?? false;
}

// ══════════════════════════════════════════
// ANTHROPIC SERVICE
// ══════════════════════════════════════════

class AI {
  static const _key = 'YOUR_ANTHROPIC_API_KEY_HERE';
  static const _url = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-haiku-4-5';
  static bool get _ok => _key != 'YOUR_ANTHROPIC_API_KEY_HERE' && _key.isNotEmpty;
  static Map<String,String> get _h => {'Content-Type':'application/json','x-api-key':_key,'anthropic-version':'2023-06-01'};

  static const _sys = '''You are CareerAI, a professional career advisor for students and professionals in Pakistan and worldwide.

Respond ONLY in clear, natural English. Never use Roman Urdu, Urdu script, or mixed language.

Rules:
- Answer the question directly and concisely.
- Use short paragraphs or simple numbered/bulleted lists when helpful.
- Do not use excessive emojis, special symbols (# @ * _ & \$ ---), markdown headers, or decorative lines.
- Sound like a knowledgeable human mentor, not a generic AI.
- Stay practical and relevant to the user's question and role.
- Add one short actionable tip only when it clearly adds value.
- Keep responses focused. Avoid long filler or repetitive phrases.

Pakistan market awareness (use only when relevant):
- Tech roles: Flutter ~80K-200K PKR/mo, AI/ML higher; remote/freelance often pays more in USD.
- Job platforms: LinkedIn, Rozee.pk, Mustakbil, Upwork, Fiverr.''';

   static Future<String> chat(List<Map<String,String>> history) async {
    if (!_ok) return _fallback(history.last['content']??'');
    try {
      final r = await http.post(Uri.parse(_url), headers: _h,
        body: jsonEncode({'model':_model,'max_tokens':500,'system':_sys,'messages':history}))
        .timeout(const Duration(seconds:20));
      if (r.statusCode == 200) return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
      if (r.statusCode == 429) return 'Rate limit reached. Please wait a moment and try again.';
      return _fallback(history.last['content']??'');
    } on SocketException { return 'No internet connection. Please check your network.'; }
    on Exception catch (e) {
      if (e.toString().contains('XMLHttpRequest') || e.toString().contains('CORS')) {
        return 'AI features work best in the Android app. Web browser has limited support.';
      }
      return _fallback(history.last['content'] ?? '');
    }
    on TimeoutException { return 'Request timed out. Please try again.'; }
    catch (_) { return _fallback(history.last['content']??''); }
  }

  static Future<List<RoadmapStep>> roadmap(String goal, String degree, String skills) async {
    if (!_ok) return _fbRoadmap(goal);
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({'model':_model,'max_tokens':2500,'messages':[{'role':'user','content':'''Generate 5-step personalized roadmap for Pakistani tech student.
Goal: $goal | Degree: $degree | Skills: $skills
Return ONLY JSON array, 5 objects: {"title","description","duration","skills":[],"resources":["URL1","URL2"],"dailyTasks":["task1","task2","task3"]}
For resources use real URLs: flutter.dev, docs.python.org, firebase.google.com/docs, youtube.com/results?search_query=SKILL+tutorial
Return ONLY JSON, no extra text.'''}]}))
        .timeout(const Duration(seconds:45));
      if (r.statusCode == 200) {
        final text = (jsonDecode(r.body)['content'][0]['text'] as String).replaceAll('```json','').replaceAll('```','').trim();
        return (jsonDecode(text) as List).map((e)=>RoadmapStep.fromJson(Map<String,dynamic>.from(e))).toList();
      }
    } catch (_) {}
    return _fbRoadmap(goal);
  }

  static Future<List<CareerMatch>> matches(String degree, String goal, String skills) async {
    if (!_ok) return _fbMatches(goal);
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({
        'model': _model,
        'max_tokens': 500,
        'messages': [{
          'role': 'user',
          'content': '''Based on this profile, suggest the TOP 5 career matches.
Degree: $degree
Goal: $goal
Skills: $skills

Respond in pure English. Return ONLY a JSON array of exactly 5 objects:
{"role":"Job Title","percentage":60-99,"reason":"max 10 words why it fits"}

No extra text, no markdown.'''
        }]
      })).timeout(const Duration(seconds:25));
      if (r.statusCode == 200) {
        final text = (jsonDecode(r.body)['content'][0]['text'] as String).replaceAll('```json','').replaceAll('```','').trim();
        final list = (jsonDecode(text) as List).take(5).map((e) => CareerMatch(
          role: e['role'],
          percentage: e['percentage'],
          reason: e['reason'],
          icon: _icon(e['role']),
        )).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return _fbMatches(goal);
  }

  static Future<String> careerDetail(String role, String degree, String goal, String skills) async {
    if (!_ok) return 'Details unavailable. Please try again later.';
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({
        'model': _model,
        'max_tokens': 450,
        'messages': [{
          'role': 'user',
          'content': '''Explain the career path "$role" for someone with:
Degree: $degree | Goal: $goal | Skills: $skills

Respond in pure English only. No emojis. No special symbols. Use this format:

Overview:
[2-3 sentences]

Key skills needed:
1. ...
2. ...
3. ...

Typical salary in Pakistan:
[PKR monthly range]

How to get started:
1. ...
2. ...
3. ...'''
        }]
      })).timeout(const Duration(seconds:20));
      if (r.statusCode == 200) return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
    } catch (_) {}
    return 'Could not load career details. Please try again.';
  }

  static Future<List<ShuffledQuestion>> quiz(String topic, String diff, String goal) async {
    if (!_ok) return _fbQuiz();
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({'model':_model,'max_tokens':2000,'messages':[{'role':'user','content':'10 MCQ quiz for Pakistani tech student.\nTopic:$topic | Difficulty:$diff | Goal:$goal\nUse clear English only. Return ONLY JSON: {"question","options":["A","B","C","D"],"correct":0}'}]}))
        .timeout(const Duration(seconds:35));
      if (r.statusCode == 200) {
        final text = (jsonDecode(r.body)['content'][0]['text'] as String).replaceAll('```json','').replaceAll('```','').trim();
        return (jsonDecode(text) as List).map((item){
          final cv = item['options'][item['correct']];
          final opts = List<String>.from(item['options'])..shuffle();
          return ShuffledQuestion(question:item['question'],shuffledOpts:opts,correctIndex:opts.indexOf(cv));
        }).toList();
      }
    } catch (_) {}
    return _fbQuiz();
  }

  static Future<String> resume(
    String text, {
    Uint8List? imageBytes,
    String imageMime = 'image/jpeg',
    Uint8List? pdfBytes,
  }) async {
    if (!_ok) return 'API key required for resume analysis.';
    const instruction = '''Review this resume for tech jobs in Pakistan.

Respond in pure English only. No Roman Urdu. No emojis. No decorative symbols.

Use this exact format:

Score: X/10

Strengths:
1. ...
2. ...
3. ...

Improvements:
1. ...
2. ...
3. ...

Missing ATS keywords:
comma-separated list

Action plan:
1. ...
2. ...''';
    try {
      final List<dynamic> content;
      if (imageBytes != null) {
        content = [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': imageMime,
              'data': base64Encode(imageBytes),
            },
          },
          {'type': 'text', 'text': '$instruction\n\nAnalyze the resume shown in the image.'},
        ];
      } else if (pdfBytes != null) {
        content = [
          {
            'type': 'document',
            'source': {
              'type': 'base64',
              'media_type': 'application/pdf',
              'data': base64Encode(pdfBytes),
            },
          },
          {'type': 'text', 'text': '$instruction\n\nAnalyze the resume in this PDF.'},
        ];
      } else {
        if (text.trim().isEmpty) return 'Please provide resume text or upload a file.';
        content = [
          {'type': 'text', 'text': '$instruction\n\nResume:\n$text'},
        ];
      }
      final r = await http
          .post(
            Uri.parse(_url),
            headers: _h,
            body: jsonEncode({
              'model': _model,
              'max_tokens': 700,
              'messages': [
                {'role': 'user', 'content': content},
              ],
            }),
          )
          .timeout(const Duration(seconds: 40));
      if (r.statusCode == 200) {
        return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
      }
    } catch (_) {}
    return 'Could not analyze the resume. Please try again.';
  }

    static Future<String> interview(String role, String diff) async {
    if (!_ok) return 'Question:\nTell me about yourself.\n\nSample Answer:\nBriefly cover your background, key skills, and why you are interested in this role.';
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({
        'model': _model,
        'max_tokens': 350,
        'messages': [{
          'role': 'user',
          'content': '''Generate ONE interview question for the role "$role" (Pakistan job market). Difficulty: $diff.

Respond in pure English only. No Roman Urdu. No emojis. No special symbols.

Use this exact format:

Question:
[clear interview question appropriate for the role and difficulty]

Sample Answer:
[2 to 4 sentences of a strong, professional answer. Direct, natural, and relevant to the role.]'''
        }]
      })).timeout(const Duration(seconds:15));
      if (r.statusCode == 200) return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
    } catch (_) {}
    return 'Could not load question. Please try again.';
  }

  static Future<String> salary(String role, String exp, String city) async {
    if (!_ok) return 'API key required for salary estimates.';
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({
        'model': _model,
        'max_tokens': 280,
        'messages': [{
          'role': 'user',
          'content': '''Estimate salary for "$role" in $city, Pakistan with $exp experience (2026 market rates).

Respond in pure English only. No Roman Urdu. No emojis. No decorative symbols.

Use this exact format:

Monthly Salary (PKR): [realistic range]
Freelance Rate (USD/hour): [realistic range]

Key factors:
- [one short point]
- [one short point]

Tips to earn more:
1. [one practical tip]
2. [one practical tip]'''
        }]
      })).timeout(const Duration(seconds:15));
      if (r.statusCode == 200) return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
    } catch (_) {}
    return 'Could not estimate salary. Please try again.';
  }

  static Future<String> tip(String goal) async {
    if (!_ok) return 'Build one relevant project this week. Real work speaks louder than credentials.';
    try {
      final r = await http.post(Uri.parse(_url), headers: _h, body: jsonEncode({
        'model': _model,
        'max_tokens': 100,
        'messages': [{
          'role': 'user',
          'content': 'Give ONE short actionable career tip for someone whose goal is: $goal. Pure English only. Max 2 sentences. No emojis. No special symbols.'
        }]
      })).timeout(const Duration(seconds:12));
      if (r.statusCode == 200) return _clean(jsonDecode(r.body)['content'][0]['text'] as String);
    } catch (_) {}
    return 'Build one relevant project this week. Real work speaks louder than credentials.';
  }

  static IconData _icon(String r) { final s=r.toLowerCase(); if(s.contains('flutter')||s.contains('mobile')) return Icons.phone_android; if(s.contains('ai')||s.contains('ml')||s.contains('data')) return Icons.auto_awesome; if(s.contains('web')||s.contains('full')) return Icons.web; if(s.contains('backend')) return Icons.storage; return Icons.work_outline; }

  static List<CareerMatch> _fbMatches(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('flutter') || g.contains('mobile')) {
      return [
        CareerMatch(role: 'Flutter Developer', percentage: 95, reason: 'Goal directly matches', icon: Icons.phone_android),
        CareerMatch(role: 'Mobile Developer', percentage: 88, reason: 'Cross-platform demand', icon: Icons.smartphone),
        CareerMatch(role: 'Full Stack Developer', percentage: 75, reason: 'Strong app foundation', icon: Icons.layers),
        CareerMatch(role: 'UI Engineer', percentage: 70, reason: 'Frontend overlap', icon: Icons.web),
        CareerMatch(role: 'Software Engineer', percentage: 65, reason: 'Core engineering path', icon: Icons.code),
      ];
    }
    return [
      CareerMatch(role: 'Software Engineer', percentage: 88, reason: 'Core skills align', icon: Icons.code),
      CareerMatch(role: 'Backend Developer', percentage: 78, reason: 'Strong programming base', icon: Icons.storage),
      CareerMatch(role: 'AI Engineer', percentage: 72, reason: 'High demand field', icon: Icons.auto_awesome),
      CareerMatch(role: 'Full Stack Developer', percentage: 68, reason: 'Versatile path', icon: Icons.layers),
      CareerMatch(role: 'Data Analyst', percentage: 62, reason: 'Growing opportunities', icon: Icons.analytics_outlined),
    ];
  }
  static List<RoadmapStep> _fbRoadmap(String goal) => [RoadmapStep(title:'Foundations',description:'Master core programming concepts.',duration:'3 weeks',skills:['Python/Dart','Data Structures','OOP','Git']),RoadmapStep(title:'Development',description:'Build real projects with modern frameworks.',duration:'4 weeks',skills:['Flutter/React','REST APIs','Firebase','State Mgmt']),RoadmapStep(title:'Backend & DB',description:'Server-side programming and databases.',duration:'3 weeks',skills:['Node.js','SQL','NoSQL','Auth']),RoadmapStep(title:'Professional',description:'Build professional online presence.',duration:'2 weeks',skills:['Resume','GitHub','LinkedIn','Portfolio']),RoadmapStep(title:'Job Ready',description:'Interview preparation and freelance setup.',duration:'2 weeks',skills:['LeetCode','System Design','Upwork','Fiverr'])];

  static List<ShuffledQuestion> _fbQuiz() { final raw=List.from(_qBank)..shuffle(); return raw.take(10).map((item){final cv=item['opts'][item['correct']];final opts=List<String>.from(item['opts'])..shuffle();return ShuffledQuestion(question:item['q'] as String,shuffledOpts:opts,correctIndex:opts.indexOf(cv));}).toList(); }

  static String _clean(String text) {
    var t = text;
    t = t.replaceAll(RegExp(r'#{1,6}\s*'), '');
    t = t.replaceAll(RegExp(r'\*{2,3}([^*]+)\*{2,3}'), r'$1');
    t = t.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    t = t.replaceAll(RegExp(r'`[^`]+`'), '');
    t = t.replaceAll(RegExp(r'_{1,2}([^_]+)_{1,2}'), r'$1');
    t = t.replaceAll(RegExp(r'^[-•●▪➤—–]+\s*', multiLine: true), '');
    t = t.replaceAll(RegExp(r'^---+$', multiLine: true), '');
    t = t.replaceAll(RegExp(r'[━═★☆✦✧◆◇]+'), '');
    t = t.replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '');
    t = t.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return t.trim();
  }

  static String _fallback(String q) {
    final s = q.toLowerCase();
    if (s.contains('flutter')) {
      return 'Flutter remains in high demand in Pakistan. Focus on Riverpod, Firebase, and shipping 2–3 solid apps. That portfolio will open more doors than certificates alone.';
    }
    if (s.contains('salary')) {
      return 'Flutter developers in Pakistan typically earn 80K–200K PKR per month. Remote freelance rates on Upwork often range from \$15–50 per hour. Building a strong profile and consistent delivery is the fastest way to increase earnings.';
    }
    if (s.contains('hello') || s.contains('salam') || s.contains('hi')) {
      return 'Hello. I am your CareerAI advisor. Ask me about careers, skills, interviews, salaries, or any professional topic.';
    }
    return 'Focus on building real projects. Practical experience and a clear portfolio matter more than collecting courses. Pick one skill and apply it this month.';
  }}

// ══════════════════════════════════════════
// STATE PROVIDERS
// ══════════════════════════════════════════

final userProvider = StateNotifierProvider<UserNotifier, Map<String, String>>((ref) => UserNotifier());
class UserNotifier extends StateNotifier<Map<String, String>> {
  UserNotifier() : super({'name':'Future Developer','degree':'Not Set','goal':'Not Set','skills':'','interests':'','city':''});
  Future<void> load() async => state = await FirebaseService.loadProfile();
  void update(String n, String d, String g) { state = {...state,'name':n,'degree':d,'goal':g}; FirebaseService.saveProfile(n,d,g); }
  void updateFull({required String name, required String degree, required String goal, required String skills, required String interests, required String city}) { state = {'name':name,'degree':degree,'goal':goal,'skills':skills,'interests':interests,'city':city}; FirebaseService.saveFullProfile(name,degree,goal,skills,interests,city); }

  void updateProfile(String s, String t, String u) {}
}

final photoProvider = StateNotifierProvider<PhotoNotifier, String?>((ref) => PhotoNotifier());
class PhotoNotifier extends StateNotifier<String?> {
  PhotoNotifier() : super(StorageService.loadPhotoPath());
  void set(String p) { state = p; StorageService.savePhotoPath(p); }
  void clear() { state = null; StorageService.savePhotoPath(''); }
}

final themeProvider = StateProvider<ThemeMode>((ref) => StorageService.loadTheme() ? ThemeMode.dark : ThemeMode.light);

final quizScoreProvider = StateNotifierProvider<QuizScoreNotifier, int>((ref) => QuizScoreNotifier());
class QuizScoreNotifier extends StateNotifier<int> {
  QuizScoreNotifier() : super(0);
  Future<void> load() async => state = await FirebaseService.loadQuizScore();
  void set(int s) { state = s; FirebaseService.saveQuizScore(s); }
}

final quizHistProvider = StateNotifierProvider<QuizHistNotifier, List<Map<String,dynamic>>>((ref) => QuizHistNotifier());
class QuizHistNotifier extends StateNotifier<List<Map<String,dynamic>>> {
  QuizHistNotifier() : super([]);
  Future<void> load() async => state = await FirebaseService.loadQuizHistory();
  void add(int score, String date) { state = [...state,{'score':score,'date':date,'total':100}]; FirebaseService.saveQuizHistory(state); }
}

final notesProvider = StateNotifierProvider<NotesNotifier, List<String>>((ref) => NotesNotifier());
class NotesNotifier extends StateNotifier<List<String>> {
  NotesNotifier() : super([]);
  Future<void> load() async => state = await FirebaseService.loadNotes();
  void add(String n) { if(n.trim().isEmpty) return; state = [...state,n.trim()]; FirebaseService.saveNotes(state); }
  void del(int i) { final u=[...state]; u.removeAt(i); state=u; FirebaseService.saveNotes(state); }
}

final roadmapProgProvider = StateNotifierProvider<RoadmapProgNotifier, Map<int,int>>((ref) => RoadmapProgNotifier());
class RoadmapProgNotifier extends StateNotifier<Map<int,int>> {
  RoadmapProgNotifier() : super({0:0,1:0,2:0,3:0,4:0});
  Future<void> load() async => state = await FirebaseService.loadRoadmap();
  void update(int i, int v) { state = {...state,i:v}; FirebaseService.saveRoadmap(state); }
  void reset(Map<int,int> m) { state = m; FirebaseService.saveRoadmap(m); }
}

final roadmapProvider = StateNotifierProvider<RoadmapNotifier, List<RoadmapStep>>((ref) => RoadmapNotifier());
class RoadmapNotifier extends StateNotifier<List<RoadmapStep>> {
  RoadmapNotifier() : super([]);
  Future<void> load() async { final s = await FirebaseService.loadDynamicRoadmap(); if(s.isNotEmpty) state=s; }
  Future<void> generate(String goal, String degree, String skills, {WidgetRef? ref}) async {
    final s = await AI.roadmap(goal, degree, skills);
    state = s;
    await FirebaseService.saveDynamicRoadmap(s);
    if (ref != null) { final m=<int,int>{}; for(int i=0;i<s.length;i++) {
      m[i]=0;
    } ref.read(roadmapProgProvider.notifier).reset(m); }
  }
}

final matchProvider = StateNotifierProvider<MatchNotifier, List<CareerMatch>>((ref) => MatchNotifier());
class MatchNotifier extends StateNotifier<List<CareerMatch>> {
  MatchNotifier() : super([]);
  Future<void> generate(String d, String g, String s) async => state = await AI.matches(d, g, s);
  void clear() => state = [];
}

final selectedCareerProvider = StateProvider<String?>((ref) => null);

final tipProvider = StateNotifierProvider<TipNotifier, String>((ref) => TipNotifier());
class TipNotifier extends StateNotifier<String> {
  TipNotifier() : super('');
  Future<void> load(String goal) async { if(state.isNotEmpty) return; state = await AI.tip(goal); }
}

class AuthState { final bool isLoggedIn; final String email; const AuthState({this.isLoggedIn=false,this.email=''}); }
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoggedIn:FirebaseService.isLoggedIn,email:FirebaseService.currentUser?.email??''));
  Future<String?> signup(String e, String p, String n) async { final err=await FirebaseService.signup(e,p,n); if(err!=null) return err; state=AuthState(isLoggedIn:true,email:e.trim()); return null; }
  Future<String?> login(String e, String p) async { final err=await FirebaseService.login(e,p); if(err!=null) return err; state=AuthState(isLoggedIn:true,email:e.trim()); return null; }
  Future<void> logout() async { await FirebaseService.logout(); state=const AuthState(); }
  Future<String?> changePass(String p) async => FirebaseService.changePassword(p);
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String,bool>>((ref) => SettingsNotifier());
class SettingsNotifier extends StateNotifier<Map<String,bool>> {
  SettingsNotifier() : super({'notifications':true,'quiz':true});
  void toggle(String k) => state = {...state, k:!(state[k]??true)};
}

// ══════════════════════════════════════════
// MAIN
// ══════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init with web support
  try {
    await Firebase.initializeApp(options: _firebaseOptions);
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // SharedPrefs init
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint('Storage init error: $e');
  }

  // Notifications (Android/iOS only — skip on web)
  try {
    if (!kIsWeb) await NotificationService.init();
  } catch (_) {}

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: mode,
      theme: _theme(false),
      darkTheme: _theme(true),
      home: _home(),
    );
  }

  ThemeData _theme(bool dark) => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: dark ? D.bg : const Color(0xFFF1F5F9),
    colorScheme: ColorScheme.fromSeed(seedColor: D.indigo, brightness: dark ? Brightness.dark : Brightness.light),
    textTheme: GoogleFonts.dmSansTextTheme(dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
    cardColor: dark ? D.card : Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(fontSize:16,fontWeight:FontWeight.w700,letterSpacing:.5,color:dark?D.t1:const Color(0xFF0F172A)),
      iconTheme: IconThemeData(color: dark ? D.t1 : const Color(0xFF0F172A)),
    ),
  );

  Widget _home() {
    try {
      // Web pe Firebase auth check
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) return const _Loader();
      if (StorageService.isOnboardingDone()) return const AuthScreen();
      return const SplashScreen();
    } catch (e) {
      debugPrint('_home error: $e');
      return const AuthScreen();
    }
  }
}

class _Loader extends ConsumerStatefulWidget {
  const _Loader();
  @override
  ConsumerState<_Loader> createState() => _LoaderState();
}

class _LoaderState extends ConsumerState<_Loader> {
  bool _showEscape = false;
  Timer? _escapeTimer;
  bool _navigated = false; // ← prevent double navigation

  @override
  void initState() {
    super.initState();
    _escapeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showEscape = true);
    });
    _load();
  }

  @override
  void dispose() {
    _escapeTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await Future.wait([
        ref.read(userProvider.notifier).load(),
        ref.read(notesProvider.notifier).load(),
        ref.read(quizHistProvider.notifier).load(),
        ref.read(quizScoreProvider.notifier).load(),
        ref.read(roadmapProgProvider.notifier).load(),
        ref.read(roadmapProvider.notifier).load(),
      ]).timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('Firebase timeout — navigating anyway');
        return [];
      });
    } catch (e) {
      debugPrint('Loader error: $e');
    }

    // ← sab se important line
    if (!mounted || _navigated) return;
    _goNext();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    final profile = ref.read(userProvider);
    final goal = profile['goal'] ?? 'Not Set';
    final name = profile['name'] ?? '';
    final isProfileComplete = goal != 'Not Set' &&
        goal.trim().isNotEmpty &&
        name.isNotEmpty &&
        name != 'Future Developer';

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) =>
            isProfileComplete ? const NavHub() : const ProfileBuilderScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: D.grad1,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: D.indigo.withOpacity(.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.psychology_alt_rounded,
                  size: 38, color: Colors.white),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(
                    duration: 1400.ms,
                    colors: [D.indigo, D.cyan, D.violet, D.indigo]),
            const SizedBox(height: 28),
            GradientText('CareerAI', style: D.display(22), gradient: D.grad1),
            const SizedBox(height: 8),
            Text('Setting up your experience...',
                style: D.body(12, color: D.t3)),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  minHeight: 3,
                  color: D.indigo,
                  backgroundColor: D.b1,
                ),
              ),
            ),
            if (_showEscape) ...[
              const SizedBox(height: 28),
              Text('Taking longer than usual.',
                  style: D.body(11, color: D.t3)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _goNext,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: D.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: D.indigo.withOpacity(.4)),
                  ),
                  child: Text('Continue anyway',
                      style: D.body(12, fw: FontWeight.w700, color: D.cyan)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    var _showEscape;
    GestureTapCallback? _goNext;
    return Scaffold(
      backgroundColor: D.bg,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: D.grad1,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: D.indigo.withOpacity(.45), blurRadius: 28, spreadRadius: 2)]),
            child: const Icon(Icons.psychology_alt_rounded, size: 38, color: Colors.white))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1400.ms, colors: [D.indigo, D.cyan, D.violet, D.indigo]),
          const SizedBox(height: 28),
          GradientText('CareerAI', style: D.display(22), gradient: D.grad1),
          const SizedBox(height: 8),
          Text('Setting up your experience...', style: D.body(12, color: D.t3)),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 3, color: D.indigo, backgroundColor: D.b1))),
          if (_showEscape) ...[
            const SizedBox(height: 28),
            Text('Taking longer than usual.', style: D.body(11, color: D.t3)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: D.card, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: D.indigo.withOpacity(.4))),
                child: Text('Continue anyway', style: D.body(12, fw: FontWeight.w700, color: D.cyan)),
              ),
            ),
          ],
        ]),
      ),
    );
  }


// ══════════════════════════════════════════
// SPLASH SCREEN — Premium
// ══════════════════════════════════════════

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}
class _SplashState extends State<SplashScreen> {
  @override
  void initState() { super.initState(); Timer(3500.ms, () { if(mounted) Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder:(_,a,__)=>const AuthScreen(), transitionsBuilder:(_,a,__,child)=>FadeTransition(opacity:a,child:child), transitionDuration:600.ms)); }); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: D.bg,
    body: Stack(children: [
      Positioned(top:-100,left:-80,child:Container(width:300,height:300,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[D.indigo.withOpacity(.3),Colors.transparent])))),
      Positioned(bottom:-80,right:-60,child:Container(width:250,height:250,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[D.fuchsia.withOpacity(.25),Colors.transparent])))),
      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width:90,height:90,decoration:BoxDecoration(gradient:D.grad1,borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:D.indigo.withOpacity(.5),blurRadius:32,spreadRadius:4)]),child:const Icon(Icons.psychology_alt_rounded,size:48,color:Colors.white)).animate().scale(duration:700.ms,curve:Curves.elasticOut),
        const SizedBox(height:28),
        GradientText('CAREER',style:D.display(40,fw:FontWeight.w900),gradient:D.grad1).animate().fadeIn(delay:300.ms),
        Text('GUIDE',style:D.display(40,fw:FontWeight.w900,color:D.t1)).animate().fadeIn(delay:400.ms),
        const SizedBox(height:10),
        Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),decoration:BoxDecoration(gradient:LinearGradient(colors:[D.indigo.withOpacity(.2),D.cyan.withOpacity(.15)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:D.indigo.withOpacity(.4))),child:Text('AI CAREER PLATFORM',style:D.body(10,fw:FontWeight.w700,color:D.indigo))).animate().fadeIn(delay:500.ms),
        const SizedBox(height:12),
        Text('Smart guidance for Pakistani tech professionals',style:D.body(12,color:D.t2)).animate().fadeIn(delay:600.ms),
        const SizedBox(height:48),
        SizedBox(width:160,child:ClipRRect(borderRadius:BorderRadius.circular(4),child:const LinearProgressIndicator(minHeight:3,color:D.indigo,backgroundColor:D.b1))),
      ])),
    ]),
  );
}

// ══════════════════════════════════════════
// AUTH SCREEN — Premium redesign
// ══════════════════════════════════════════

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthState();
}
class _AuthState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _lEmail=TextEditingController(), _lPass=TextEditingController();
  final _sName=TextEditingController(), _sEmail=TextEditingController(), _sPass=TextEditingController(), _sCnf=TextEditingController();
  bool _lVis=false, _sVis=false, _cVis=false, _loading=false;
  String? _lErr, _sErr;

  @override
  void initState() { super.initState(); _tab=TabController(length:2,vsync:this); _tab.addListener(()=>setState((){})); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _login() async {
    setState((){_lErr=null;_loading=true;});
    final err = await ref.read(authProvider.notifier).login(_lEmail.text.trim(), _lPass.text);
    if (!mounted) return;
    setState(()=>_loading=false);
    if (err!=null){setState(()=>_lErr=err);return;}
    // Load Firebase data
    try { await ref.read(userProvider.notifier).load(); } catch (_) {}
    if (!mounted) return;
    // ✅ Check if profile is complete
    final profile = ref.read(userProvider);
    final goal = profile['goal'] ?? 'Not Set';
    final name = profile['name'] ?? '';
    final isProfileComplete = goal != 'Not Set' && goal.trim().isNotEmpty && 
                              name.isNotEmpty && name != 'Future Developer';
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => isProfileComplete ? const NavHub() : const ProfileBuilderScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: 400.ms,
    ));
  }

  void _signup() async {
    setState(()=>_sErr=null);
    if(_sName.text.trim().isEmpty){setState(()=>_sErr='Please enter your name.');return;}
    if(!_sEmail.text.contains('@')){setState(()=>_sErr='Invalid email address.');return;}
    if(_sPass.text.length<6){setState(()=>_sErr='Password must be at least 6 characters.');return;}
    if(_sPass.text!=_sCnf.text){setState(()=>_sErr='Passwords do not match.');return;}
    setState(()=>_loading=true);
    final err = await ref.read(authProvider.notifier).signup(
      _sEmail.text.trim(), _sPass.text, _sName.text.trim());
    if (!mounted) return;
    setState(()=>_loading=false);
    if(err!=null){setState(()=>_sErr=err);return;}
    // ✅ Signup kamyab — clear any old onboarding flag, go to Onboarding
    await StorageService.clearOnboarding();
    if (!mounted) return;
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => const OnboardingScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: 500.ms,
    ));
  }

  void _google() async {
    setState((){_lErr=null;_loading=true;});
    final err = await FirebaseService.signInWithGoogle();
    if (!mounted) return;
    setState(()=>_loading=false);
    if(err!=null){setState(()=>_lErr=err);return;}
    // Load profile and check if complete
    try { await ref.read(userProvider.notifier).load(); } catch (_) {}
    if (!mounted) return;
    final gProfile = ref.read(userProvider);
    final gGoal = gProfile['goal'] ?? 'Not Set';
    final gName = gProfile['name'] ?? '';
    final gComplete = gGoal != 'Not Set' && gGoal.trim().isNotEmpty && 
                      gName.isNotEmpty && gName != 'Future Developer';
    Widget nextScreen;
    if (!gComplete) {
      await StorageService.clearOnboarding();
      nextScreen = const OnboardingScreen();
    } else {
      nextScreen = const NavHub();
    }
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (_, a, __) => nextScreen,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: 400.ms,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(children: [
        Positioned(top:-120,right:-80,child:Container(width:320,height:320,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[D.indigo.withOpacity(.2),Colors.transparent])))),
        Positioned(bottom:-80,left:-60,child:Container(width:260,height:260,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[D.violet.withOpacity(.15),Colors.transparent])))),
        SafeArea(child: SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24,vertical:16),child:Column(children:[
          const SizedBox(height:24),
          Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            Container(width:44,height:44,decoration:BoxDecoration(gradient:D.grad1,borderRadius:BorderRadius.circular(14),boxShadow:[BoxShadow(color:D.indigo.withOpacity(.4),blurRadius:16)]),child:const Icon(Icons.psychology_alt_rounded,size:24,color:Colors.white)),
            const SizedBox(width:12),
            Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('CareerAI',style:D.display(20)),
              Text('AI-Powered Platform',style:D.body(11)),
            ]),
          ]).animate().fadeIn(),
          const SizedBox(height:36),

          // Tab switcher
          Container(
            decoration:BoxDecoration(color:D.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:D.b1)),
            child:TabBar(controller:_tab,
              indicator:BoxDecoration(gradient:D.grad1,borderRadius:BorderRadius.circular(14),boxShadow:[BoxShadow(color:D.indigo.withOpacity(.35),blurRadius:12)]),
              labelColor:Colors.white,unselectedLabelColor:D.t3,
              labelStyle:GoogleFonts.outfit(fontWeight:FontWeight.w700,fontSize:13,letterSpacing:.5),
              dividerColor:Colors.transparent,
              tabs:const[Tab(text:'LOGIN'),Tab(text:'SIGN UP')]),
          ),
          const SizedBox(height:28),

          if(_tab.index==0)...[
            _field('Email Address',Icons.email_outlined,_lEmail,D.cyan,false,false,null),
            const SizedBox(height:12),
            _field('Password',Icons.lock_outline,_lPass,D.indigo,true,_lVis,()=>setState(()=>_lVis=!_lVis)),
            if(_lErr!=null)...[const SizedBox(height:12),_errBox(_lErr!)],
            const SizedBox(height:24),
            GradientButton(label:'SIGN IN',gradient:D.grad1,onTap:_login,loading:_loading,icon:Icons.login_rounded),
            const SizedBox(height:20),
            _divider(),
            const SizedBox(height:20),
            _googleBtn(),
          ],

          if(_tab.index==1)...[
            _field('Full Name',Icons.person_outline,_sName,D.emerald,false,false,null),
            const SizedBox(height:12),
            _field('Email Address',Icons.email_outlined,_sEmail,D.cyan,false,false,null),
            const SizedBox(height:12),
            _field('Password (min 6)',Icons.lock_outline,_sPass,D.indigo,true,_sVis,()=>setState(()=>_sVis=!_sVis)),
            const SizedBox(height:12),
            _field('Confirm Password',Icons.lock_person_outlined,_sCnf,D.fuchsia,true,_cVis,()=>setState(()=>_cVis=!_cVis)),
            const SizedBox(height:8),
            _strengthBar(_sPass.text),
            if(_sErr!=null)...[const SizedBox(height:12),_errBox(_sErr!)],
            const SizedBox(height:24),
            GradientButton(label:'CREATE ACCOUNT',gradient:D.grad4,onTap:_signup,loading:_loading,icon:Icons.rocket_launch_rounded),
          ],
          const SizedBox(height:32),
        ]))),

        if(_loading) Positioned.fill(child:Container(color:Colors.black54,child:Center(child:GlassCard(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const CircularProgressIndicator(color:D.indigo,strokeWidth:2.5),const SizedBox(height:16),Text('Please wait...',style:D.body(13))]),)))),
      ]),
    );
  }

  Widget _field(String hint, IconData icon, TextEditingController ctrl, Color col, bool pass, bool vis, VoidCallback? onVis) =>
    TextField(controller:ctrl, obscureText:pass&&!vis,
      onChanged:(_)=>setState((){_lErr=null;_sErr=null;}),
      style:GoogleFonts.dmSans(color:D.t1,fontSize:14),
      decoration:InputDecoration(
        filled:true, fillColor:D.card,
        hintText:hint, hintStyle:GoogleFonts.dmSans(color:D.t3,fontSize:13),
        prefixIcon:Container(margin:const EdgeInsets.all(12),padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:col.withOpacity(.12),borderRadius:BorderRadius.circular(10)),child:Icon(icon,color:col,size:18)),
        suffixIcon:pass?IconButton(icon:Icon(vis?Icons.visibility_outlined:Icons.visibility_off_outlined,color:D.t3,size:18),onPressed:onVis):null,
        enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:D.b1)),
        focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(color:col,width:1.5)),
        contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:16),
      )).animate().fadeIn(duration:200.ms);

  Widget _errBox(String msg) => Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:D.rose.withOpacity(.1),borderRadius:BorderRadius.circular(12),border:Border.all(color:D.rose.withOpacity(.3))),child:Row(children:[const Icon(Icons.error_outline_rounded,color:D.rose,size:18),const SizedBox(width:8),Expanded(child:Text(msg,style:D.body(12,color:D.rose)))])).animate().fadeIn().slideY(begin:-.1);

  Widget _divider() => Row(children:[const Expanded(child:Divider(color:D.b1)),Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:Text('or',style:D.body(11,color:D.t3))),const Expanded(child:Divider(color:D.b1))]);

  Widget _googleBtn() => OutlinedButton(
    style:OutlinedButton.styleFrom(minimumSize:const Size(double.infinity,52),side:const BorderSide(color:D.b2),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),backgroundColor:D.card),
    onPressed:_loading?null:_google,
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(width:22,height:22,decoration:const BoxDecoration(shape:BoxShape.circle,color:Colors.white),child:const Center(child:Text('G',style:TextStyle(color:Colors.red,fontWeight:FontWeight.w900,fontSize:13)))),
      const SizedBox(width:10),
      Text('Continue with Google',style:D.body(13,fw:FontWeight.w600,color:D.t1)),
    ]));

  Widget _strengthBar(String pass) {
    if(pass.isEmpty) return const SizedBox.shrink();
    int s=0;
    if(pass.length>=6)s++;
    if(pass.contains(RegExp(r'[A-Z]')))s++;
    if(pass.contains(RegExp(r'[0-9]')))s++;
    if(pass.contains(RegExp(r'[!@#$%^&*]')))s++;
    final labels=['','Weak','Fair','Good','Strong'];
    final colors=[Colors.transparent,D.rose,D.amber,D.cyan,D.emerald];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:List.generate(4,(i)=>Expanded(child:AnimatedContainer(duration:300.ms,margin:const EdgeInsets.only(right:4),height:4,decoration:BoxDecoration(color:i<s?colors[s]:D.b1,borderRadius:BorderRadius.circular(2)))))),
      const SizedBox(height:5),
      Text('Strength: ${labels[s]}',style:D.body(10,fw:FontWeight.w600,color:colors[s])),
    ]);
  }
}

// ══════════════════════════════════════════
// ONBOARDING — Premium
// ══════════════════════════════════════════

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnbState();
}
class _OnbState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;
  static const _slides = [
    {'title':'AI CAREER\nMENTOR','sub':'24/7 expert guidance','icon':Icons.forum_outlined,'grad':D.grad1,'tag':'ALWAYS AVAILABLE'},
    {'title':'SMART\nROADMAPS','sub':'Personalized learning paths','icon':Icons.alt_route_outlined,'grad':D.grad3,'tag':'AI GENERATED'},
    {'title':'ADAPTIVE\nQUIZZES','sub':'Test and grow faster','icon':Icons.quiz_outlined,'grad':D.grad2,'tag':'SKILL BASED'},
    {'title':'6 AI\nTOOLS','sub':'Resume · Interview · Salary','icon':Icons.auto_awesome_outlined,'grad':D.grad4,'tag':'AI POWERED'},
  ];

  void _next() {
    if(_page<_slides.length-1){_pc.nextPage(duration:400.ms,curve:Curves.easeInOutCubic);}
    else{StorageService.setOnboardingDone();Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const ProfileBuilderScreen()));}
  }

  @override
  Widget build(BuildContext context) {
    final grad = _slides[_page]['grad'] as LinearGradient;
    final c = grad.colors.first;
    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(children:[
        Positioned(top:-100,right:-80,child:Container(width:300,height:300,decoration:BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[c.withOpacity(.2),Colors.transparent])))),
        PageView.builder(controller:_pc,onPageChanged:(v)=>setState(()=>_page=v),itemCount:_slides.length,
          itemBuilder:(ctx,i){
            final s=_slides[i];
            final g=s['grad'] as LinearGradient;
            final ic=g.colors.first;
            return SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(28,40,28,160),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:6),decoration:BoxDecoration(color:ic.withOpacity(.15),borderRadius:BorderRadius.circular(20),border:Border.all(color:ic.withOpacity(.4))),child:Text(s['tag'] as String,style:D.body(10,fw:FontWeight.w700,color:ic))),
              const SizedBox(height:48),
              Container(width:140,height:140,decoration:BoxDecoration(gradient:g,borderRadius:BorderRadius.circular(40),boxShadow:[BoxShadow(color:ic.withOpacity(.4),blurRadius:40,spreadRadius:4)]),child:Icon(s['icon'] as IconData,size:70,color:Colors.white)),
              const SizedBox(height:40),
              GradientText(s['title'] as String,style:D.display(32,fw:FontWeight.w900),gradient:g),
              const SizedBox(height:10),
              Text(s['sub'] as String,style:D.body(14,fw:FontWeight.w500,color:D.t2)),
            ])));
          }),
        Positioned(bottom:100,left:0,right:0,child:Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(_slides.length,(i)=>AnimatedContainer(duration:300.ms,margin:const EdgeInsets.symmetric(horizontal:4),width:_page==i?28:8,height:8,decoration:BoxDecoration(gradient:_page==i?(_slides[i]['grad'] as LinearGradient):null,color:_page==i?null:D.b2,borderRadius:BorderRadius.circular(4)))))),
        Positioned(bottom:32,left:24,right:24,child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          TextButton(onPressed:()=>_pc.jumpToPage(_slides.length-1),child:Text('SKIP',style:D.body(12,fw:FontWeight.w600,color:D.t3))),
          Container(decoration:BoxDecoration(gradient:grad,borderRadius:BorderRadius.circular(28),boxShadow:[BoxShadow(color:c.withOpacity(.4),blurRadius:16)]),child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.transparent,shadowColor:Colors.transparent,padding:const EdgeInsets.symmetric(horizontal:32,vertical:14),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(28))),onPressed:_next,child:Text(_page==_slides.length-1?'GET STARTED':'NEXT →',style:GoogleFonts.outfit(fontWeight:FontWeight.w700,fontSize:13,color:Colors.white)))),
        ])),
      ]),
    );
  }
}

// ══════════════════════════════════════════
// PROFILE BUILDER — Premium 3-step
// ══════════════════════════════════════════

class ProfileBuilderScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  const ProfileBuilderScreen({super.key, this.isEdit = false});
  @override
  ConsumerState<ProfileBuilderScreen> createState() => _ProfBldState();
}

class _ProfBldState extends ConsumerState<ProfileBuilderScreen> with TickerProviderStateMixin {
  final _pc = PageController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  int _step = 0;

  // Step 1 — Personal
  final _name = TextEditingController();
  String _age = 'Under 18';
  String _gender = 'Male';
  String _city = 'Lahore';

  // Step 2 — Education
  final _degree = TextEditingController();
  String _eduLevel = 'Intermediate / FA / FSc';
  String _field = 'Computer Science / IT';
  String _year = '2025';

  // Step 3 — Career & Interests
  final _goal = TextEditingController();
  final _interests = TextEditingController();
  final _skills = TextEditingController();
  String _workPref = 'Full-time Job';
  String _salaryGoal = 'PKR 50K–100K/mo';

  static const _ages = ['Under 18','18–22','23–27','28–35','35+'];
  static const _genders = ['Male','Female','Other'];
  static const _cities = ['Lahore','Karachi','Islamabad','Rawalpindi','Faisalabad','Peshawar','Multan','Quetta','Other'];
  static const _eduLevels = ['Matric / O-Level','Intermediate / FA / FSc',"Bachelor's Degree","Master's Degree",'PhD / Doctorate','Diploma / Certificate','Self-Taught'];
  static const _fields = ['Computer Science / IT','Engineering (Mech/Elec/Civil)','Medical / Health Sciences','Business / Commerce / MBA','Arts / Design / Media','Law / Legal Studies','Education / Teaching','Science (Physics/Chemistry/Bio)','Social Sciences','Islamic Studies','Other'];
  static const _years = ['2023','2024','2025','2026','2027','2028','2029','Already Graduated'];
  static const _workPrefs = ['Full-time Job','Part-time','Freelancing','Remote Work','Own Business','Internship','Government Job','NGO / Social Work'];
  static const _salaryGoals = ['PKR 30K–50K/mo','PKR 50K–100K/mo','PKR 100K–200K/mo','PKR 200K–500K/mo','PKR 500K+/mo','USD \$500–1K/mo','USD \$1K–3K/mo','USD \$3K+/mo'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: 500.ms);
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    if (widget.isEdit) {
      final u = ref.read(userProvider);
      _name.text = u['name'] ?? '';
      _degree.text = u['degree'] ?? '';
      _goal.text = u['goal'] ?? '';
      _skills.text = u['skills'] ?? '';
      _interests.text = u['interests'] ?? '';
      if ((u['city'] ?? '').isNotEmpty) _city = u['city']!;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pc.dispose();
    _name.dispose();
    _degree.dispose();
    _goal.dispose();
    _interests.dispose();
    _skills.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_name.text.trim().isEmpty) { _toast('Apna naam zaroor likhein.'); return; }
    }
    if (_step == 1) {
      if (_degree.text.trim().isEmpty) { _degree.text = _eduLevel; }
    }
    if (_step == 2) {
      if (_goal.text.trim().isEmpty) { _toast('Apna career goal likhein.'); return; }
      _save(); return;
    }
    setState(() => _step++);
    _animCtrl.reset(); _animCtrl.forward();
    _pc.animateToPage(_step, duration: 400.ms, curve: Curves.easeInOutCubic);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _animCtrl.reset(); _animCtrl.forward();
    _pc.animateToPage(_step, duration: 400.ms, curve: Curves.easeInOutCubic);
  }

  void _save() async {
    final name = _name.text.trim();
    final degree = '$_eduLevel — $_field ($_year)';
    final goal = _goal.text.trim();
    final skills = _skills.text.trim();
    final interests = _interests.text.trim();
    final skillsVal = skills.isEmpty ? 'General' : skills;

    ref.read(userProvider.notifier).updateFull(
      name: name,
      degree: degree,
      goal: goal,
      skills: skillsVal,
      interests: interests.isEmpty ? _workPref : interests,
      city: _city,
    );

    StorageService.setOnboardingDone();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: D.indigo)),
    );
    try {
      await ref.read(matchProvider.notifier).generate(degree, goal, skillsVal);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => CareerSelectScreen(fromEdit: widget.isEdit),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: D.rose, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16)));

  static const _stepGrads = [D.grad2, D.grad1, D.grad3];
  static const _stepTitles = ['Personal Info', 'Education Details', 'Career Goals'];
  static const _stepSubs = ['Apne baare mein batao', 'Aapki education ka background', 'Aap zindagi mein kya karna chahte hain?'];
  static const _stepIcons = [Icons.person_rounded, Icons.school_rounded, Icons.rocket_launch_rounded];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grad = _stepGrads[_step];
    final c = (grad).colors.first;

    return Scaffold(
      backgroundColor: dark ? D.bg : const Color(0xFFF1F5F9),
      body: Stack(children: [
        // Background glow
        Positioned(top: -80, right: -60,
          child: Container(width: 260, height: 260,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.withOpacity(.18), Colors.transparent])))),
        Positioned(bottom: -60, left: -40,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [c.withOpacity(.1), Colors.transparent])))),

        SafeArea(child: Column(children: [

          // ── TOP: Step indicator ──
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(3, (i) {
                final done = i < _step;
                final active = i == _step;
                final ic = (_stepGrads[i]).colors.first;
                return Expanded(child: Row(children: [
                  AnimatedContainer(duration: 300.ms,
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: done || active ? _stepGrads[i] : null,
                      color: done || active ? null : (dark ? D.card : Colors.white),
                      shape: BoxShape.circle,
                      border: Border.all(color: done || active ? ic : D.b1, width: done || active ? 0 : 1.5),
                      boxShadow: active ? [BoxShadow(color: ic.withOpacity(.4), blurRadius: 14)] : []),
                    child: Icon(done ? Icons.check_rounded : _stepIcons[i],
                      size: 17, color: done || active ? Colors.white : D.t3)),
                  if (i < 2) Expanded(child: Container(height: 2,
                    decoration: BoxDecoration(
                      gradient: i < _step ? _stepGrads[i] : null,
                      color: i < _step ? null : D.b1))),
                ]));
              })),
              const SizedBox(height: 18),
              FadeTransition(opacity: _fadeAnim,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Step ${_step + 1} of 3',
                    style: D.body(11, fw: FontWeight.w700, color: c)),
                  const SizedBox(height: 4),
                  Text(_stepTitles[_step], style: D.display(22)),
                  const SizedBox(height: 2),
                  Text(_stepSubs[_step], style: D.body(12, color: D.t2)),
                ])),
            ])),

          const SizedBox(height: 14),

          // ── PAGES ──
          Expanded(child: PageView(
            controller: _pc,
            physics: const NeverScrollableScrollPhysics(),
            children: [_page1(dark, c), _page2(dark, c), _page3(dark, c)],
          )),

          // ── BUTTONS ──
          Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Row(children: [
              if (_step > 0) ...[
                GestureDetector(onTap: _back,
                  child: Container(width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: dark ? D.card : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: D.b1)),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: D.t2))),
                const SizedBox(width: 12),
              ],
              Expanded(child: GestureDetector(onTap: _next,
                child: Container(height: 54,
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: c.withOpacity(.4), blurRadius: 16, offset: const Offset(0, 5))]),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_step == 2 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(_step == 2 ? 'BUILD MY PROFILE' : 'NEXT STEP',
                      style: D.display(13, fw: FontWeight.w700, color: Colors.white)),
                  ])))),
            ])),
        ])),
      ]),
    );
  }

  // ── STEP 1: Personal ──
  Widget _page1(bool dark, Color c) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
    child: _card(dark, children: [
      _lbl('Full Name *'),
      _tf(_name, 'Enter your full name', Icons.person_outline, c),
      const SizedBox(height: 18),
      _lbl('Age Group'),
      _chips(_ages, _age, c, (v) => setState(() => _age = v)),
      const SizedBox(height: 18),
      _lbl('Gender'),
      _chips(_genders, _gender, c, (v) => setState(() => _gender = v)),
      const SizedBox(height: 18),
      _lbl('City / Location'),
      _chips(_cities, _city, c, (v) => setState(() => _city = v)),
    ]));

  // ── STEP 2: Education ──
  Widget _page2(bool dark, Color c) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
    child: _card(dark, children: [
      _lbl('Education Level'),
      _chips(_eduLevels, _eduLevel, c, (v) => setState(() { _eduLevel = v; _degree.text = v; })),
      const SizedBox(height: 18),
      _lbl('Field of Study'),
      _chips(_fields, _field, c, (v) => setState(() => _field = v)),
      const SizedBox(height: 18),
      _lbl('Degree / Program Name (Optional)'),
      _tf(_degree, 'Example: BS Computer Science, FA, FSc Pre-Medical', Icons.school_outlined, c),
      const SizedBox(height: 18),
      _lbl('Graduation Year'),
      _chips(_years, _year, c, (v) => setState(() => _year = v)),
    ]));

  // ── STEP 3: Career ──
  Widget _page3(bool dark, Color c) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
    child: _card(dark, children: [
      _lbl('Career Goal *'),
      _tf(_goal, 'What do you want to become? (Any field)', Icons.star_outline, c),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: [
        'Software Engineer','Doctor','Teacher','Businessman',
        'Lawyer','Designer','Data Scientist','Journalist','Chef',
        'Content Creator','Civil Engineer','Accountant',
      ].map((s) => GestureDetector(
        onTap: () => setState(() => _goal.text = s),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: c.withOpacity(.1), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withOpacity(.3))),
          child: Text(s, style: D.body(11, fw: FontWeight.w600, color: c))))).toList()),
      const SizedBox(height: 18),
      _lbl('Your Interests'),
      _tf(_interests, 'Example: technology, art, medicine, business, sports', Icons.favorite_outline, D.fuchsia),
      const SizedBox(height: 18),
      _lbl('Current Skills (Optional)'),
      _tf(_skills, 'Example: coding, drawing, writing, math, communication', Icons.code_rounded, D.emerald),
      const SizedBox(height: 18),
      _lbl('Work Preference'),
      _chips(_workPrefs, _workPref, c, (v) => setState(() => _workPref = v)),
      const SizedBox(height: 18),
      _lbl('Salary / Income Goal'),
      _chips(_salaryGoals, _salaryGoal, c, (v) => setState(() => _salaryGoal = v)),
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [D.indigo.withOpacity(.1), D.cyan.withOpacity(.06)]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: D.indigo.withOpacity(.25))),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(gradient: D.grad1, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(
            'AI will create a personalized career roadmap, skill plan, and guidance based on your entire profile — for any field!',
            style: D.body(11, color: D.t1))),
        ])),
    ]));

  Widget _card(bool dark, {required List<Widget> children}) =>
    Container(padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? D.card : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: D.b1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 18, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: D.body(11, fw: FontWeight.w700, color: D.t3)));

  Widget _tf(TextEditingController ctrl, String hint, IconData icon, Color col) =>
    TextField(controller: ctrl,
      style: GoogleFonts.dmSans(color: D.t1, fontSize: 14),
      decoration: InputDecoration(
        filled: true, fillColor: D.surface,
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: D.t3, fontSize: 12),
        prefixIcon: Container(margin: const EdgeInsets.all(11),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: col.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: col, size: 17)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: D.b1)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: col, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));

  Widget _chips(List<String> opts, String sel, Color ac, ValueChanged<String> fn) =>
    Wrap(spacing: 8, runSpacing: 8, children: opts.map((o) {
      final s = o == sel;
      return GestureDetector(onTap: () => fn(o),
        child: AnimatedContainer(duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            gradient: s ? LinearGradient(colors: [ac, ac.withOpacity(.75)]) : null,
            color: s ? null : D.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: s ? ac : D.b1, width: s ? 0 : 1),
            boxShadow: s ? [BoxShadow(color: ac.withOpacity(.25), blurRadius: 8)] : []),
          child: Text(o, style: D.body(12, fw: s ? FontWeight.w700 : FontWeight.w400,
            color: s ? Colors.white : D.t2))));
    }).toList());
}

// ══════════════════════════════════════════
// CAREER SELECT SCREEN
// ══════════════════════════════════════════

class CareerSelectScreen extends ConsumerStatefulWidget {
  final bool fromEdit;
  const CareerSelectScreen({super.key, this.fromEdit = false});
  @override
  ConsumerState<CareerSelectScreen> createState() => _CareerSelectState();
}

class _CareerSelectState extends ConsumerState<CareerSelectScreen> {
  String? _selected;
  String? _detail;
  bool _detailLoading = false;
  String? _detailRole;

  Future<void> _showDetail(CareerMatch m) async {
    setState(() {
      _detailRole = m.role;
      _detailLoading = true;
      _detail = null;
    });
    final u = ref.read(userProvider);
    final d = await AI.careerDetail(
      m.role,
      u['degree'] ?? '',
      u['goal'] ?? '',
      u['skills'] ?? '',
    );
    if (!mounted) return;
    setState(() {
      _detail = d;
      _detailLoading = false;
    });
  }

  void _confirm() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please select one career path to continue.'),
        backgroundColor: D.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    ref.read(selectedCareerProvider.notifier).state = _selected;
    final u = ref.read(userProvider);
    ref.read(roadmapProvider.notifier).generate(
      _selected!,
      u['degree'] ?? '',
      u['skills'] ?? '',
      ref: ref,
    );
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const NavHub(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final matches = ref.watch(matchProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grads = [D.grad1, D.grad2, D.grad3, D.grad4, D.grad5];

    return Scaffold(
      backgroundColor: dark ? D.bg : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(
          widget.fromEdit ? 'Update Career Path' : 'Choose Your Career',
          style: D.display(16),
        ),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: widget.fromEdit,
      ),
      body: matches.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: D.indigo),
                const SizedBox(height: 16),
                Text('Finding your best career matches...', style: D.body(13)),
              ]),
            )
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Based on your profile, here are your top 5 career matches. Select one to continue. You can switch paths later from the Roadmap tab.',
                  style: D.body(13, color: D.t2),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: matches.length,
                  itemBuilder: (ctx, i) {
                    final m = matches[i];
                    final g = grads[i % grads.length];
                    final c = g.colors.first;
                    final sel = _selected == m.role;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: dark ? D.card : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sel ? c : D.b1, width: sel ? 2 : 1),
                        boxShadow: sel
                            ? [BoxShadow(color: c.withOpacity(.25), blurRadius: 12)]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => setState(() => _selected = m.role),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: g,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(m.icon, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.role, style: D.display(14)),
                                        Text(m.reason, style: D.body(11)),
                                      ],
                                    ),
                                  ),
                                  Column(children: [
                                    GradientText('${m.percentage}%',
                                        style: D.display(16), gradient: g),
                                    if (sel) Icon(Icons.check_circle, color: c, size: 18),
                                  ]),
                                ]),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: m.percentage / 100,
                                    minHeight: 4,
                                    valueColor: AlwaysStoppedAnimation(c),
                                    backgroundColor: D.b1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(children: [
                                  TextButton.icon(
                                    onPressed: () => _showDetail(m),
                                    icon: Icon(Icons.info_outline, size: 16, color: c),
                                    label: Text('View details',
                                        style: D.body(12, fw: FontWeight.w600, color: c)),
                                  ),
                                  const Spacer(),
                                  if (sel)
                                    Text('Selected',
                                        style: D.body(11, fw: FontWeight.w700, color: c)),
                                ]),
                                if (_detailRole == m.role) ...[
                                  const SizedBox(height: 8),
                                  if (_detailLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: D.indigo),
                                        ),
                                      ),
                                    )
                                  else if (_detail != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: D.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: D.b1),
                                      ),
                                      child: Text(_detail!, style: D.body(12, color: D.t1)),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: GradientButton(
                  label: 'Continue with selected career',
                  gradient: D.grad1,
                  onTap: _confirm,
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ]),
    );
  }
}
class NavHub extends ConsumerStatefulWidget {
  const NavHub({super.key});
  @override
  ConsumerState<NavHub> createState() => _NavHubState();
}

class _NavHubState extends ConsumerState<NavHub> {
  int _idx = 0;

  final _tabs = const [
    DashScreen(),
    RoadmapScreen(),
    ChatScreen(),
    QuizScreen(),
    SettingsScreen(),
  ];

  final _titles = const [
    'Dashboard',
    'My Roadmap',
    'AI Chat',
    'Skill Quiz',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? D.bg : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_titles[_idx]),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: D.cyan,
            ),
            onPressed: () {
              final m = dark ? ThemeMode.light : ThemeMode.dark;
              ref.read(themeProvider.notifier).state = m;
              StorageService.saveTheme(m == ThemeMode.dark);
            },
          ),
        ],
      ),
      // ====================== BODY (full size force) ======================
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey<int>(_idx),
                child: _tabs[_idx],
              ),
            ),
          );
        },
      ),
      // ====================== BOTTOM NAV (fixed height) ======================
      bottomNavigationBar: Container(
        height: 72, // ← fixed height (yeh bahut zaroori hai)
        decoration: BoxDecoration(
          color: dark ? D.card : Colors.white,
          border: const Border(top: BorderSide(color: D.b1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _navItem(0, Icons.grid_view_rounded, 'Home', D.indigo),
              _navItem(1, Icons.map_outlined, 'Roadmap', D.emerald),
              _navItem(2, Icons.psychology_outlined, 'Chat', D.cyan),
              _navItem(3, Icons.quiz_outlined, 'Quiz', D.amber),
              _navItem(4, Icons.settings_outlined, 'Settings', D.t2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color color) {
    final on = _idx == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _idx = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: on ? color : D.t3,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: D.body(
                10,
                fw: on ? FontWeight.w700 : FontWeight.w400,
                color: on ? color : D.t3,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: on ? 18 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: on ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════
// DASHBOARD SCREEN
// ══════════════════════════════════════════

class DashScreen extends ConsumerStatefulWidget {
  const DashScreen({super.key});
  @override
  ConsumerState<DashScreen> createState() => _DashState();
}

class _DashState extends ConsumerState<DashScreen> {
  final _noteCtrl = TextEditingController();
  Timer? _quoteTimer;
  int _quoteIdx = 0;

  static const _quotes = [
    'Progress over perfection.',
    'Show up every day.',
    'Skills compound over time.',
    'Build something real today.',
    'Consistency beats intensity.',
    'Start small. Stay steady.',
    'Your future self is watching.',
    'Action creates clarity.',
    'Discipline opens doors.',
    'Keep learning. Keep shipping.',
  ];

  @override
  void initState() {
    super.initState();
    _quoteIdx = DateTime.now().second % _quotes.length;
    _quoteTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      setState(() => _quoteIdx = (_quoteIdx + 1) % _quotes.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final u = ref.read(userProvider);
      if ((u['name'] == 'Future Developer' || (u['name'] ?? '').isEmpty) ||
          (u['goal'] == 'Not Set' || (u['goal'] ?? '').isEmpty)) {
        ref.read(userProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(userProvider);
    final photo = ref.watch(photoProvider);
    final notes = ref.watch(notesProvider);
    final qs = ref.watch(quizScoreProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final quote = _quotes[_quoteIdx % _quotes.length];
    final prog = ref.watch(roadmapProgProvider);
    final roadmap = ref.watch(roadmapProvider);
    final overallProg = prog.values.isEmpty
        ? 0
        : (prog.values.reduce((a, b) => a + b) / (roadmap.isEmpty ? 5 : roadmap.length)).round();

    // ← Scaffold hata diya (nested Scaffold black screen ka main reason tha)
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ══ HERO CARD ══
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF2D3A8C), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Colors.white.withOpacity(.07),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: 0,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFFD946EF).withOpacity(.2),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _badge('AI Active', const Color(0xFF10B981), Icons.circle, size: 6),
                        const SizedBox(width: 8),
                        _badge('Career Mode', const Color(0xFFF59E0B), Icons.local_fire_department_rounded),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: D.grad1,
                            border: Border.all(color: Colors.white.withOpacity(.25), width: 2),
                            boxShadow: [
                              BoxShadow(color: D.indigo.withOpacity(.4), blurRadius: 12)
                            ],
                          ),
                          child: ClipOval(
                            // ← !kIsWeb check add kiya (web pe crash nahi hoga)
                            child: (photo != null &&
                                    photo.isNotEmpty &&
                                    !kIsWeb &&
                                    File(photo).existsSync())
                                ? Image.file(File(photo), fit: BoxFit.cover)
                                : const Icon(Icons.person_rounded, color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white54),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                u['name'] ?? 'Future Developer',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      u['goal'] ?? 'Set your career goal',
                      style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _stat('$qs pts', 'Quiz', const Color(0xFFF59E0B)),
                        _divider(),
                        _stat('${notes.length}', 'Notes', const Color(0xFFD946EF)),
                        _divider(),
                        _stat('$overallProg%', 'Progress', const Color(0xFF10B981)),
                        _divider(),
                        _stat('6', 'AI Tools', const Color(0xFF06B6D4)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -.02),

          const SizedBox(height: 14),

          // ══ ROADMAP PROGRESS ══
          if (roadmap.isNotEmpty)
            _card(
              dark,
              child: Column(
                children: [
                  Row(
                    children: [
                      _iconBox(D.grad3, Icons.map_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Roadmap Progress', style: D.display(13))),
                      Text(
                        '$overallProg%',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (overallProg / 100).clamp(0.0, 1.0),
                      minHeight: 8,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
                      backgroundColor: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 80.ms),

          const SizedBox(height: 12),
          // ══ DAILY MOTIVATION (one line, auto-rotates) ══
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFFF59E0B).withOpacity(.12),
                const Color(0xFFF43F5E).withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: D.grad5,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.format_quote_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      quote,
                      key: ValueKey(quote),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms),

          const SizedBox(height: 18),

          // ══ AI TOOLS ══
          _secTitle('AI TOOLS'),
          const SizedBox(height: 10),
          Row(
            children: [
              _toolCard(
                dark,
                'Resume\nAnalyzer',
                Icons.description_outlined,
                D.grad2,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeScreen())),
              ),
              const SizedBox(width: 10),
              _toolCard(
                dark,
                'Interview\nCoach',
                Icons.record_voice_over_outlined,
                D.grad1,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterviewScreen())),
              ),
              const SizedBox(width: 10),
              _toolCard(
                dark,
                'Salary\nEstimator',
                Icons.attach_money_rounded,
                D.grad3,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen())),
              ),
            ],
          ).animate().fadeIn(delay: 160.ms),

          const SizedBox(height: 18),

          // ══ CAREER MATCHES ══
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _secTitle('CAREER MATCHES', margin: false),
              GestureDetector(
                onTap: () {
                  final u2 = ref.read(userProvider);
                  ref.read(matchProvider.notifier).generate(
                        u2['degree'] ?? '',
                        u2['goal'] ?? '',
                        u2['skills'] ?? '',
                      );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: D.grad1,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _MatchCards(),

          const SizedBox(height: 18),

          // ══ QUICK NOTES ══
          _secTitle('QUICK NOTES'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  style: GoogleFonts.dmSans(
                    color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: GoogleFonts.dmSans(color: D.t3, fontSize: 12),
                    filled: true,
                    fillColor: dark ? const Color(0xFF111827) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (_noteCtrl.text.trim().isNotEmpty) {
                    ref.read(notesProvider.notifier).add(_noteCtrl.text);
                    _noteCtrl.clear();
                  }
                },
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: D.grad1,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(.4),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No notes yet. Add one above.',
                  style: GoogleFonts.dmSans(fontSize: 12, color: D.t3),
                ),
              ),
            )
          else
            ...notes.asMap().entries.map(
                  (e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: D.grad1,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: dark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref.read(notesProvider.notifier).del(e.key),
                          child: const Icon(Icons.close_rounded, color: Color(0xFF475569), size: 16),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: .04),
                ),
        ],
      ),
    );
  }

  Widget _secTitle(String t, {bool margin = true}) => Text(
        t,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF475569),
          letterSpacing: 1.5,
        ),
      );

  Widget _badge(String label, Color col, IconData icon, {double size = 14}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: col, size: size),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );

  Widget _stat(String val, String label, Color col) => Column(
        children: [
          Text(
            val,
            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: col),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: Colors.white.withOpacity(.15),
        margin: const EdgeInsets.symmetric(horizontal: 12),
      );

  Widget _card(bool dark, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
          ],
        ),
        child: child,
      );

  Widget _iconBox(Gradient grad, IconData icon) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(gradient: grad, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 16),
      );

  Widget _toolCard(bool dark, String label, IconData icon, Gradient grad, VoidCallback fn) =>
      Expanded(
        child: GestureDetector(
          onTap: fn,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF111827) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (grad as LinearGradient).colors.first.withOpacity(.3),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: grad,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: grad.colors.first.withOpacity(.35),
                        blurRadius: 12,
                      )
                    ],
                  ),
                  child: Icon(icon, size: 22, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: grad.colors.first,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MatchCards extends ConsumerStatefulWidget {
  const _MatchCards();
  @override
  ConsumerState<_MatchCards> createState() => _MatchCardsState();
}

class _MatchCardsState extends ConsumerState<_MatchCards> {
  bool _loading = false;
  String? _detailRole;
  String? _detail;
  bool _detailLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (ref.read(matchProvider).isNotEmpty) return;
    final u = ref.read(userProvider);
    if (u['goal'] == 'Not Set' || (u['goal'] ?? '').isEmpty) return;
    setState(() => _loading = true);
    await ref.read(matchProvider.notifier).generate(
          u['degree'] ?? '',
          u['goal'] ?? '',
          u['skills'] ?? '',
        );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showDetail(CareerMatch m) async {
    setState(() {
      _detailRole = m.role;
      _detailLoading = true;
      _detail = null;
    });
    final u = ref.read(userProvider);
    final d = await AI.careerDetail(
      m.role, u['degree'] ?? '', u['goal'] ?? '', u['skills'] ?? '',
    );
    if (!mounted) return;
    setState(() {
      _detail = d;
      _detailLoading = false;
    });
  }

  void _select(CareerMatch m) {
    ref.read(selectedCareerProvider.notifier).state = m.role;
    final u = ref.read(userProvider);
    ref.read(roadmapProvider.notifier).generate(
      m.role, u['degree'] ?? '', u['skills'] ?? '', ref: ref,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Selected: ${m.role}. Roadmap is updating.'),
      backgroundColor: D.emerald,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final ms = ref.watch(matchProvider);
    final selected = ref.watch(selectedCareerProvider);
    if (_loading) {
      return GlassCard(
        child: Row(children: [
          const SizedBox(
            width: 18, height: 18,
            child: CircularProgressIndicator(color: D.indigo, strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text('Finding career matches...', style: D.body(12)),
        ]),
      );
    }
    if (ms.isEmpty) {
      return GestureDetector(
        onTap: _load,
        child: GlassCard(
          child: Row(children: [
            const Icon(Icons.auto_awesome, color: D.indigo, size: 18),
            const SizedBox(width: 10),
            Text('Tap to generate career matches', style: D.body(13)),
          ]),
        ),
      );
    }
    final grads = [D.grad3, D.grad2, D.grad1, D.grad4, D.grad5];
    return Column(
      children: ms.map((m) {
        final g = grads[ms.indexOf(m) % grads.length];
        final c = g.colors.first;
        final sel = selected == m.role;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: D.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sel ? c : c.withOpacity(.2), width: sel ? 2 : 1),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(gradient: g, borderRadius: BorderRadius.circular(12)),
                child: Icon(m.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.role, style: D.display(13)),
                    Text(m.reason, style: D.body(11)),
                  ],
                ),
              ),
              GradientText('${m.percentage}%', style: D.display(16), gradient: g),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: m.percentage / 100,
                minHeight: 4,
                valueColor: AlwaysStoppedAnimation(c),
                backgroundColor: D.b1,
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              TextButton(
                onPressed: () => _showDetail(m),
                child: Text('Details', style: D.body(11, fw: FontWeight.w700, color: c)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _select(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: sel ? g : null,
                    color: sel ? null : c.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withOpacity(.4)),
                  ),
                  child: Text(
                    sel ? 'Selected' : 'Select & build roadmap',
                    style: D.body(11, fw: FontWeight.w700, color: sel ? Colors.white : c),
                  ),
                ),
              ),
            ]),
            if (_detailRole == m.role) ...[
              const SizedBox(height: 8),
              if (_detailLoading)
                const SizedBox(
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: D.indigo),
                    ),
                  ),
                )
              else if (_detail != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: D.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: D.b1),
                  ),
                  child: Text(_detail!, style: D.body(12, color: D.t1)),
                ),
            ],
          ]),
        ).animate().slideX(begin: .1, duration: 350.ms);
      }).toList(),
    );
  }
}
// ══════════════════════════════════════════
// ROADMAP SCREEN
// ══════════════════════════════════════════

class RoadmapScreen extends ConsumerStatefulWidget {
  const RoadmapScreen({super.key});
  @override
  ConsumerState<RoadmapScreen> createState() => _RoadmapState();
}
class _RoadmapState extends ConsumerState<RoadmapScreen> {
  bool _gen=false;
  @override
  Widget build(BuildContext context) {
    final u = ref.watch(userProvider);
    final steps = ref.watch(roadmapProvider);
    final prog = ref.watch(roadmapProgProvider);
    final matches = ref.watch(matchProvider);
    final selected = ref.watch(selectedCareerProvider) ?? u['goal'] ?? 'Your path';
    final total = prog.values.isEmpty
        ? 0
        : prog.values.reduce((a, b) => a + b) ~/ (steps.isEmpty ? 5 : steps.length);
    final dark3 = Theme.of(context).brightness == Brightness.dark;
    return Stack(children: [
      Positioned.fill(
        child: Opacity(
          opacity: dark3 ? 0.05 : 0.03,
          child: Image.network(
            'https://images.unsplash.com/photo-1484417894907-623942c8ee29?w=800&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: dark3 ? D.bg : const Color(0xFFF1F5F9)),
          ),
        ),
      ),
      SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [

          // STEP 7: pick any of the 5 matched careers → separate roadmap
          if (matches.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose a career path',
                style: D.body(11, fw: FontWeight.w700, color: D.t3),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: matches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final m = matches[i];
                  final on = selected == m.role;
                  return GestureDetector(
                    onTap: () async {
                      ref.read(selectedCareerProvider.notifier).state = m.role;
                      setState(() => _gen = true);
                      await ref.read(roadmapProvider.notifier).generate(
                            m.role,
                            u['degree'] ?? '',
                            u['skills'] ?? '',
                            ref: ref,
                          );
                      if (mounted) setState(() => _gen = false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: on ? D.grad1 : null,
                        color: on ? null : D.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: on ? D.indigo : D.b1),
                      ),
                      child: Text(
                        m.role,
                        style: D.body(
                          12,
                          fw: FontWeight.w600,
                          color: on ? Colors.white : D.t2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Progress header — shows SELECTED career
          GlassCard(
            gradient: LinearGradient(colors: [
              D.emerald.withOpacity(.12),
              D.cyan.withOpacity(.07),
            ]),
            border: D.emerald.withOpacity(.25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected,
                  style: D.body(11, fw: FontWeight.w600, color: D.emerald),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  GradientText('$total%', style: D.display(32), gradient: D.grad3),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${steps.where((s) => (prog[steps.indexOf(s)] ?? 0) == 100).length}/${steps.length} done',
                        style: D.body(11, color: D.t2),
                      ),
                      Text('Keep going', style: D.body(10, color: D.emerald)),
                    ],
                  ),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total / 100,
                    minHeight: 8,
                    valueColor: const AlwaysStoppedAnimation(D.emerald),
                    backgroundColor: D.b1,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 12),

          GradientButton(
            label: _gen
                ? 'Generating...'
                : (steps.isEmpty ? 'Generate roadmap' : 'Regenerate roadmap'),
            gradient: D.grad1,
            onTap: _gen
                ? () {}
                : () async {
                    setState(() => _gen = true);
                    final role = ref.read(selectedCareerProvider) ??
                        u['goal'] ??
                        'Software Engineer';
                    await ref.read(roadmapProvider.notifier).generate(
                          role,
                          u['degree'] ?? '',
                          u['skills'] ?? '',
                          ref: ref,
                        );
                    if (mounted) setState(() => _gen = false);
                  },
            loading: _gen,
            icon: Icons.auto_awesome,
          ).animate().fadeIn(),

          const SizedBox(height: 18),

      if(steps.isNotEmpty) ListView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:steps.length,itemBuilder:(ctx,i){
        final s=steps[i], p=prog[i]??0;
        final done=p==100;
        final gradients=[D.grad2,D.grad1,D.grad3,D.grad4,D.grad5];
        final g=gradients[i%gradients.length];
        final c=(g).colors.first;
        return GestureDetector(onTap:()=>_progDialog(ctx,i,s.title),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Column(children:[
            Container(width:34,height:34,decoration:BoxDecoration(gradient:done?g:null,color:done?null:D.card,shape:BoxShape.circle,border:Border.all(color:done?c:D.b2,width:done?0:1.5),boxShadow:done?[BoxShadow(color:c.withOpacity(.3),blurRadius:10)]:null),child:Icon(done?Icons.check_rounded:Icons.circle,size:done?16:8,color:done?Colors.white:c)),
            if(i<steps.length-1)Container(width:2,height:20,margin:const EdgeInsets.symmetric(vertical:3),decoration:BoxDecoration(gradient:done?g:null,color:done?null:D.b1)),
          ]),
          const SizedBox(width:14),
          Expanded(child:Container(margin:const EdgeInsets.only(bottom:14),decoration:BoxDecoration(color:D.card,borderRadius:BorderRadius.circular(16),border:Border.all(color:done?c.withOpacity(.3):D.b1)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(gradient:LinearGradient(colors:[c.withOpacity(.1),Colors.transparent]),borderRadius:const BorderRadius.vertical(top:Radius.circular(16))),child:Row(children:[
              Expanded(child:Text(s.title,style:D.display(13))),
              Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(gradient:done?g:null,color:done?null:c.withOpacity(.12),borderRadius:BorderRadius.circular(8)),child:Text('$p%',style:D.body(11,fw:FontWeight.w700,color:done?Colors.white:c))),
            ])),
            Padding(padding:const EdgeInsets.fromLTRB(14,0,14,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(s.description,style:D.body(11)),
              const SizedBox(height:8),
              Wrap(spacing:5,runSpacing:5,children:s.skills.map((sk)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),decoration:BoxDecoration(color:c.withOpacity(.1),borderRadius:BorderRadius.circular(8),border:Border.all(color:c.withOpacity(.25))),child:Text(sk,style:D.body(10,fw:FontWeight.w600,color:c)))).toList()),
              Row(children:[const Icon(Icons.schedule_rounded,color:D.t3,size:12),const SizedBox(width:4),Text(s.duration,style:D.body(10,color:D.t3)),const Spacer(),Text('tap to update',style:D.body(9,color:D.t3))]),
              if(p>0&&p<100)...[const SizedBox(height:8),ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:p/100,minHeight:6,valueColor:AlwaysStoppedAnimation(c),backgroundColor:D.b1))],

              // Daily Tasks
              if(s.dailyTasks.isNotEmpty)...[const SizedBox(height:12),Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:D.emerald.withOpacity(.07),borderRadius:BorderRadius.circular(12),border:Border.all(color:D.emerald.withOpacity(.2))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[const Icon(Icons.checklist_rounded,color:D.emerald,size:12),const SizedBox(width:5),Text('DAILY TASKS',style:D.body(9,fw:FontWeight.w800,color:D.emerald))]),
                const SizedBox(height:7),
                ...s.dailyTasks.asMap().entries.map((e)=>Padding(padding:const EdgeInsets.only(bottom:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:17,height:17,margin:const EdgeInsets.only(top:1),decoration:BoxDecoration(color:D.emerald.withOpacity(.2),shape:BoxShape.circle),child:Center(child:Text('${e.key+1}',style:D.body(9,fw:FontWeight.w700,color:D.emerald)))),const SizedBox(width:7),Expanded(child:Text(e.value,style:D.body(11,color:D.t1)))]))),
              ]))],

              // Resources
              if(s.resources.isNotEmpty)...[const SizedBox(height:10),Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:D.cyan.withOpacity(.06),borderRadius:BorderRadius.circular(12),border:Border.all(color:D.cyan.withOpacity(.2))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Row(children:[const Icon(Icons.link_rounded,color:D.cyan,size:12),const SizedBox(width:5),Text('RESOURCES',style:D.body(9,fw:FontWeight.w800,color:D.cyan))]),
                const SizedBox(height:7),
                ...s.resources.map((res)=>GestureDetector(onTap:()async{try{final url=res.startsWith('http')?res:'https://www.youtube.com/results?search_query=${Uri.encodeComponent(res)}';await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);}catch(_){}},child:Padding(padding:const EdgeInsets.only(bottom:5),child:Row(children:[const Icon(Icons.open_in_new_rounded,color:D.cyan,size:12),const SizedBox(width:6),Expanded(child:Text(res,style:D.body(11,fw:FontWeight.w500,color:D.cyan,).copyWith(decoration:TextDecoration.underline,decorationColor:D.cyan.withOpacity(.5))))])))),
              ]))],
            ])),
          ]))),
        ])).animate().fadeIn(delay:Duration(milliseconds:i*60));
      }),
    ])),  // SingleChildScrollView
    ]);   // Stack
  }

  void _progDialog(BuildContext ctx, int idx, String title) {
    double val=(ref.read(roadmapProgProvider)[idx]??0).toDouble();
    showGeneralDialog(context:ctx,barrierDismissible:true,barrierLabel:'',barrierColor:Colors.black54,transitionDuration:300.ms,
      transitionBuilder:(_,anim,__,child)=>ScaleTransition(scale:CurvedAnimation(parent:anim,curve:Curves.easeOutBack),child:FadeTransition(opacity:anim,child:child)),
      pageBuilder:(c,_,__)=>StatefulBuilder(builder:(c,ss)=>Center(child:Material(color:Colors.transparent,child:Container(margin:const EdgeInsets.symmetric(horizontal:24),padding:const EdgeInsets.all(26),decoration:BoxDecoration(color:D.card,borderRadius:BorderRadius.circular(28),border:Border.all(color:D.b2),boxShadow:const [BoxShadow(color:Colors.black54,blurRadius:24)]),child:Column(mainAxisSize:MainAxisSize.min,children:[
        Container(padding:const EdgeInsets.all(14),decoration:const BoxDecoration(gradient:D.grad3,shape:BoxShape.circle),child:const Icon(Icons.track_changes_rounded,color:Colors.white,size:28)),
        const SizedBox(height:14),
        Text('Update Progress',style:D.body(11,fw:FontWeight.w700,color:D.t3)),
        const SizedBox(height:4),
        Text(title,textAlign:TextAlign.center,style:D.display(16)),
        const SizedBox(height:18),
        TweenAnimationBuilder<double>(tween:Tween(begin:0,end:val/100),duration:500.ms,curve:Curves.easeOutCubic,builder:(_,v,__)=>Stack(alignment:Alignment.center,children:[
          SizedBox(width:90,height:90,child:CircularProgressIndicator(value:v,strokeWidth:8,backgroundColor:D.b1,valueColor:const AlwaysStoppedAnimation(D.emerald))),
          GradientText('${val.round()}%',style:D.display(20),gradient:D.grad3),
        ])),
        const SizedBox(height:16),
        SliderTheme(data:SliderThemeData(activeTrackColor:D.emerald,inactiveTrackColor:D.b1,thumbColor:D.emerald,overlayColor:D.emerald.withOpacity(.15),trackHeight:5,thumbShape:const RoundSliderThumbShape(enabledThumbRadius:10)),child:Slider(value:val,min:0,max:100,divisions:20,onChanged:(v)=>ss(()=>val=v))),
        const SizedBox(height:16),
        Row(children:[
          Expanded(child:OutlinedButton(style:OutlinedButton.styleFrom(side:const BorderSide(color:D.b2),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(vertical:14)),onPressed:()=>Navigator.pop(c),child:Text('CANCEL',style:D.body(12,fw:FontWeight.w700)))),
          const SizedBox(width:10),
          Expanded(child:GradientButton(label:'SAVE',gradient:D.grad3,height:48,onTap:(){ref.read(roadmapProgProvider.notifier).update(idx,val.round());Navigator.pop(c);})),
        ]),
      ]))))));
  }
}

// ══════════════════════════════════════════
// CHAT SCREEN
// ══════════════════════════════════════════

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatState();
}
class _ChatState extends ConsumerState<ChatScreen> {
  final List<Map<String,dynamic>> _msgs=[
    {'text': "Assalam-o-Alaikum! 👋 I'm your AI Career Chatbot. Ask anything!",'isU':false,'time':_t()}
  ];
  final List<Map<String,String>> _hist=[];
  final _tc=TextEditingController(), _sc=ScrollController();
  bool _loading=false;
  static String _t(){final n=DateTime.now();return '${n.hour.toString().padLeft(2,'0')}:${n.minute.toString().padLeft(2,'0')}';}

  void _send() async {
    if(_tc.text.trim().isEmpty||_loading) return;
    final text=_tc.text.trim();
    setState((){_msgs.add({'text':text,'isU':true,'time':_t()});_loading=true;_tc.clear();});
    _scroll();
    _hist.add({'role':'user','content':text});
    final r=await AI.chat(List.from(_hist));
    _hist.add({'role':'assistant','content':r});
    if(!mounted) return;
    setState((){_msgs.add({'text':r,'isU':false,'time':_t()});_loading=false;});
    _scroll();
  }
  void _scroll(){Future.delayed(100.ms,(){if(_sc.hasClients)_sc.animateTo(_sc.position.maxScrollExtent,duration:300.ms,curve:Curves.easeOut);});}

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(children:[
      // Chat background
      Positioned.fill(child: Opacity(opacity: dark ? 0.06 : 0.04,
        child: Image.network(
          'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800&q=80',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [D.indigo.withOpacity(.12), D.bg],
                begin: Alignment.topLeft, end: Alignment.bottomRight)))))),
      Column(children:[
      // Quick chips
      Container(height:44,margin:const EdgeInsets.fromLTRB(16,4,16,0),child:ListView(scrollDirection:Axis.horizontal,children:['Career Path','Coding Help','Resume Tips','Salary','Interview','General Q','Freelance','Study Tips'].map((l)=>GestureDetector(onTap:(){if(!_loading){_tc.text='Tell me about $l for Pakistani tech professionals';_send();}},child:Container(margin:const EdgeInsets.only(right:7),padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(gradient:LinearGradient(colors:[D.indigo.withOpacity(.2),D.violet.withOpacity(.15)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:D.indigo.withOpacity(.35))),child:Text(l,style:D.body(11,fw:FontWeight.w600,color:D.indigo))))).toList())),
      const SizedBox(height:6),
      Expanded(child:ListView.builder(controller:_sc,padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),itemCount:_msgs.length,itemBuilder:(ctx,i)=>_bubble(_msgs[i]))),
      if(_loading)Padding(padding:const EdgeInsets.fromLTRB(16,4,16,4),child:Align(alignment:Alignment.centerLeft,child:Row(mainAxisSize:MainAxisSize.min,children:[Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:D.card,borderRadius:BorderRadius.circular(12),border:Border.all(color:D.b1)),child:Row(mainAxisSize:MainAxisSize.min,children:[...List.generate(3,(i)=>Container(width:6,height:6,margin:const EdgeInsets.symmetric(horizontal:2),decoration:const BoxDecoration(color:D.indigo,shape:BoxShape.circle)).animate(onPlay:(c)=>c.repeat()).fadeIn(delay:Duration(milliseconds:i*150),duration:300.ms).then().fadeOut(duration:300.ms)),const SizedBox(width:8),Text('Thinking...',style:D.body(10,color:D.indigo))]))]))),
      Padding(padding:const EdgeInsets.fromLTRB(14,4,14,14),child:Container(height:56,decoration:BoxDecoration(color:D.card,borderRadius:BorderRadius.circular(28),border:Border.all(color:D.indigo.withOpacity(.3)),boxShadow:[BoxShadow(color:D.indigo.withOpacity(.1),blurRadius:16)]),child:Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Row(children:[
        Expanded(child:TextField(controller:_tc,onSubmitted:(_)=>_send(),style:GoogleFonts.dmSans(color:D.t1,fontSize:13),decoration:InputDecoration(hintText:'Ask anything...',border:InputBorder.none,hintStyle:GoogleFonts.dmSans(fontSize:12,color:D.t3)))),
        GestureDetector(onTap:_send,child:AnimatedContainer(duration:200.ms,width:36,height:36,decoration:BoxDecoration(gradient:_loading?null:D.grad1,color:_loading?D.b1:null,borderRadius:BorderRadius.circular(18),boxShadow:_loading?[]:[BoxShadow(color:D.indigo.withOpacity(.4),blurRadius:10)]),child:Icon(_loading?Icons.hourglass_empty_rounded:Icons.arrow_upward_rounded,color:Colors.white,size:18))),
      ])))),
      ]),  // Column
    ]);   // Stack
  }

  Widget _bubble(Map<String,dynamic> m) {
    final isU=m['isU'] as bool;
    return Align(alignment:isU?Alignment.centerRight:Alignment.centerLeft,child:Container(
      margin:const EdgeInsets.only(bottom:12),
      padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
      constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.8),
      decoration:BoxDecoration(
        gradient:isU?LinearGradient(colors:[D.indigo.withOpacity(.25),D.violet.withOpacity(.15)]):null,
        color: isU ? null : T.card(context),
        borderRadius:BorderRadius.only(topLeft:const Radius.circular(18),topRight:const Radius.circular(18),bottomLeft:isU?const Radius.circular(18):Radius.zero,bottomRight:isU?Radius.zero:const Radius.circular(18)),
        border:Border.all(color:isU?D.indigo.withOpacity(.35):T.b1(context)),
      ),
      child:Column(crossAxisAlignment:isU?CrossAxisAlignment.end:CrossAxisAlignment.start,children:[
        if(!isU)Row(children:[Container(width:22,height:22,decoration:BoxDecoration(gradient:D.grad1,borderRadius:BorderRadius.circular(7)),child:const Icon(Icons.psychology_alt_rounded,size:12,color:Colors.white)),const SizedBox(width:7),Text('CareerAI',style:D.body(9,fw:FontWeight.w700,color:D.indigo))]),
        if(!isU)const SizedBox(height:6),
        Text(m['text'] as String, style: D.body(13, color: T.t1(context))),        const SizedBox(height:4),
        Text(m['time'] as String,style:D.body(9,color:D.t3)),
      ]),
    )).animate().fadeIn(duration:220.ms).slideY(begin:.1);
  }
}

// ══════════════════════════════════════════
// QUIZ SCREEN
// ══════════════════════════════════════════

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});
  @override
  ConsumerState<QuizScreen> createState() => _QuizState();
}
class _QuizState extends ConsumerState<QuizScreen> with SingleTickerProviderStateMixin {
  List<ShuffledQuestion> _bank=[];
  int _idx=0,_score=0;
  int? _sel;
  bool _answered=false,_done=false,_loading=true,_hist=false;
  late AnimationController _shake;
  late Animation<double> _shakeAnim;
  @override
  void initState(){super.initState();_shake=AnimationController(vsync:this,duration:400.ms);_shakeAnim=Tween<double>(begin:0,end:1).animate(CurvedAnimation(parent:_shake,curve:Curves.elasticOut));WidgetsBinding.instance.addPostFrameCallback((_)=>_load());}
  @override
  void dispose(){_shake.dispose();super.dispose();}

  Future<void> _load() async {
    if(mounted) setState(()=>_loading=true);
    try{final u=ref.read(userProvider),h=ref.read(quizHistProvider),r=ref.read(roadmapProvider);final goal=u['goal']??'Software Development';final topic=r.isNotEmpty?r[0].title:goal;final diff=h.isEmpty?'beginner':h.length>=3&&(h.last['score'] as int)>70?'advanced':'intermediate';final qs=await AI.quiz(topic,diff,goal);if(mounted) setState((){_bank=qs;_loading=false;});}catch(_){if(mounted) setState(()=>_loading=false);}
  }

  void _answer(int s){
    if(_answered) return;
    setState((){_sel=s;_answered=true;});
    if(s!=_bank[_idx].correctIndex) _shake.forward(from:0);
    Future.delayed(900.ms,(){
      if(!mounted) return;
      if(s==_bank[_idx].correctIndex){_score+=10;ref.read(quizScoreProvider.notifier).set(_score);}
      setState((){if(_idx<_bank.length-1){_idx++;_sel=null;_answered=false;}else{_done=true;final n=DateTime.now();ref.read(quizHistProvider.notifier).add(_score,'${n.day}/${n.month}/${n.year}');}});
    });
  }

  @override
  Widget build(BuildContext context) {
    final h=ref.watch(quizHistProvider);
    if(_hist) return _histUI(h);
    if(_loading) return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const CircularProgressIndicator(color:D.indigo),const SizedBox(height:14),Text('AI preparing quiz...', style: D.body(13, color: T.t2(context)))]));
    if(_done) return _doneUI(h);
    if(_bank.isEmpty) return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline,color:D.cyan,size:48),const SizedBox(height:14),Text('Could not load quiz.', style: D.body(13, color: T.t2(context))),const SizedBox(height:14),GradientButton(label:'Retry',gradient:D.grad1,onTap:_load)]));

    final q=_bank[_idx];
    return SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        PillBadge('Q${_idx+1}/${_bank.length}',color:D.cyan),
        GestureDetector(onTap:()=>setState(()=>_hist=true),child:PillBadge('History (${h.length})',color:D.violet,icon:Icons.history_rounded)),
      ]),
      const SizedBox(height:10),
      ClipRRect(borderRadius:BorderRadius.circular(4),child:LinearProgressIndicator(value:(_idx+1)/_bank.length,minHeight:4,valueColor:const AlwaysStoppedAnimation(D.indigo),backgroundColor:D.b1)),
      const SizedBox(height:20),
      GlassCard(
  gradient: LinearGradient(colors: [D.indigo.withOpacity(.12), D.violet.withOpacity(.08)]),
  border: D.indigo.withOpacity(.3),
  padding: const EdgeInsets.all(22),
  child: Text(
    q.question,
    textAlign: TextAlign.center,
style: D.display(15, fw: FontWeight.w500, color: T.t1(context)),  ),
).animate().fadeIn(),
      const SizedBox(height:20),
      ...List.generate(q.shuffledOpts.length,(i){
        Color border = T.b1(context);Color bg=Colors.transparent;IconData? icon;bool wrong=false,correct=false;
        if(_answered&&_sel!=null){if(i==q.correctIndex){border=D.emerald;bg=D.emerald.withOpacity(.08);icon=Icons.check_circle_rounded;correct=true;}else if(i==_sel){border=D.rose;bg=D.rose.withOpacity(.08);icon=Icons.cancel_rounded;wrong=true;}}
        final opt=AnimatedContainer(duration:280.ms,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:bg,borderRadius:BorderRadius.circular(14),border:Border.all(color:border,width:1.5)),child:Row(children:[
          Container(width:28,height:28,decoration:BoxDecoration(gradient:correct?D.grad3:null,color: correct ? null : T.card(context),shape:BoxShape.circle),child:Center(child:Text(String.fromCharCode(65+i),style:D.body(11,fw:FontWeight.w700,color:correct?Colors.white:D.cyan)))),
          const SizedBox(width:12),
Expanded(child: Text(q.shuffledOpts[i], style: D.body(13, color: T.t1(context)))),          if(icon!=null)Icon(icon,color:correct?D.emerald:D.rose,size:20),
        ]));
        return Padding(padding:const EdgeInsets.only(bottom:10),child:GestureDetector(onTap:()=>_answer(i),child:wrong?AnimatedBuilder(animation:_shakeAnim,builder:(_,child)=>Transform.translate(offset:Offset(math.sin(_shakeAnim.value*math.pi*5)*6,0),child:child),child:opt):opt)).animate().fadeIn(delay:Duration(milliseconds:i*50));
      }),
      const SizedBox(height:12),
      Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),decoration:BoxDecoration(gradient:LinearGradient(colors:[D.amber.withOpacity(.15),D.rose.withOpacity(.1)]),borderRadius:BorderRadius.circular(12),border:Border.all(color:D.amber.withOpacity(.3))),child:GradientText('SCORE: $_score pts',style:D.display(13),gradient:D.grad5)),
    ])));  // SingleChildScrollView + SafeArea
  }

  Widget _doneUI(List h){
    final pct=(_score/(_bank.isNotEmpty?_bank.length*10:100)*100).round();
    final color=pct>=70?D.emerald:pct>=40?D.amber:D.rose;
    final grad=pct>=70?D.grad3:pct>=40?D.grad5:const LinearGradient(colors:[D.rose,D.fuchsia]);
    return Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Container(width:100,height:100,decoration:BoxDecoration(gradient:grad,shape:BoxShape.circle,boxShadow:[BoxShadow(color:color.withOpacity(.4),blurRadius:24)]),child:Icon(pct>=70?Icons.verified_rounded:Icons.emoji_events_outlined,size:52,color:Colors.white)).animate().scale(duration:600.ms,curve:Curves.elasticOut),
      const SizedBox(height:20),
      GradientText('$_score/${_bank.length*10}',style:D.display(52),gradient:grad).animate().fadeIn(delay:200.ms),
      const SizedBox(height:8),
      Text('$pct% — ${pct>=70?"Excellent! 🎉":pct>=40?"Good effort! 💪":"Keep going! 📚"}',style:D.body(14,fw:FontWeight.w600,color:color)),
      const SizedBox(height:36),
      Row(children:[
        Expanded(child:OutlinedButton(style:OutlinedButton.styleFrom(padding:const EdgeInsets.symmetric(vertical:14),side:const BorderSide(color:D.b2),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),onPressed:()=>setState(()=>_hist=true),child:Text('HISTORY',style:D.body(13,fw:FontWeight.w700)))),
        const SizedBox(width:12),
        Expanded(child:GradientButton(label:'NEW QUIZ',gradient:D.grad1,onTap:(){setState((){_idx=0;_score=0;_sel=null;_answered=false;_done=false;});_load();})),
      ]),
    ])));
  }

  Widget _histUI(List h) => Scaffold(backgroundColor:Theme.of(context).scaffoldBackgroundColor,appBar:AppBar(backgroundColor:Colors.transparent,title:Text('Quiz History',style:D.display(15)),leading:IconButton(icon:const Icon(Icons.arrow_back_ios_rounded,color:D.cyan),onPressed:()=>setState(()=>_hist=false))),body:h.isEmpty?Center(child:Text('No history yet.',style:D.body(13))):ListView.builder(padding:const EdgeInsets.all(18),itemCount:h.length,itemBuilder:(ctx,i){final e=h[h.length-1-i];final pct=((e['score'] as int)/(e['total'] as int)*100).round();final c=pct>=70?D.emerald:pct>=40?D.amber:D.rose;final g=pct>=70?D.grad3:pct>=40?D.grad5:const LinearGradient(colors:[D.rose,D.fuchsia]);return GlassCard(padding:const EdgeInsets.all(14),child:Row(children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(gradient:g,borderRadius:BorderRadius.circular(12)),child:Text('$pct%',style:D.display(13,color:Colors.white))),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${e['score']}/${e['total']} points',style:D.display(13)),Text(e['date'] as String,style:D.body(11))])),Icon(pct>=70?Icons.verified_rounded:Icons.emoji_events_outlined,color:c,size:20)])).animate().fadeIn().slideX(begin:.1);}));
}

// ══════════════════════════════════════════
// SETTINGS SCREEN
// ══════════════════════════════════════════

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}
class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _editing=false;
  late TextEditingController _n,_d,_g,_s,_int,_c;
  final _np=TextEditingController();
  final _picker=ImagePicker();
  @override
  void initState(){super.initState();final u=ref.read(userProvider);_n=TextEditingController(text:u['name']);_d=TextEditingController(text:u['degree']);_g=TextEditingController(text:u['goal']);_s=TextEditingController(text:u['skills']);_int=TextEditingController(text:u['interests']);_c=TextEditingController(text:u['city']);}
  @override
  void dispose(){_n.dispose();_d.dispose();_g.dispose();_s.dispose();_int.dispose();_c.dispose();_np.dispose();super.dispose();}

  Future<void> _pickImg() async { try { final img=await _picker.pickImage(source:ImageSource.gallery,maxWidth:512,maxHeight:512,imageQuality:85); if(img!=null){ref.read(photoProvider.notifier).set(img.path);_msg('Photo updated!');} } catch(_){_msg('Could not pick image.',err:true);} }

  void _save(){
    if(_n.text.trim().isEmpty){_msg('Name cannot be empty.',err:true);return;}
    final oldGoal=ref.read(userProvider)['goal']??'';
    final newGoal=_g.text.trim();
    ref.read(userProvider.notifier).updateFull(name:_n.text.trim(),degree:_d.text.trim(),goal:newGoal,skills:_s.text.trim(),interests:_int.text.trim(),city:_c.text.trim());
    setState(()=>_editing=false);
    if(oldGoal!=newGoal&&newGoal.isNotEmpty){ref.read(roadmapProvider.notifier).generate(newGoal,_d.text.trim(),_s.text.trim(),ref:ref);_msg('Profile updated! AI generating new roadmap...');}
    else {
      _msg('Profile updated!');
    }
  }

  void _changePass() async { if(_np.text.length<6){_msg('Min 6 characters.',err:true);return;} final err=await ref.read(authProvider.notifier).changePass(_np.text); if(err!=null) {
    _msg(err,err:true);
  } else{_np.clear();_msg('Password changed!');} }

  void _logout() => AwesomeDialog(context:context,dialogType:DialogType.warning,animType:AnimType.scale,title:'Logout',desc:'Are you sure?',btnCancelText:'Cancel',btnCancelOnPress:(){},btnOkText:'Logout',btnOkColor:D.rose,btnOkOnPress:()async{await ref.read(authProvider.notifier).logout();if(!mounted)return;Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const AuthScreen()),(_)=>false);}).show();

  void _msg(String m,{bool err=false}) => AwesomeDialog(context:context,dialogType:err?DialogType.error:DialogType.success,animType:AnimType.bottomSlide,title:err?'Error':'Done!',desc:m,btnOkColor:D.indigo,btnOkOnPress:(){}..call()).show();

  @override
  Widget build(BuildContext context) {
    final u=ref.watch(userProvider),auth=ref.watch(authProvider),photo=ref.watch(photoProvider),settings=ref.watch(settingsProvider);
    final dark2 = Theme.of(context).brightness == Brightness.dark;
    return Stack(children:[
      Positioned.fill(child: Opacity(opacity: dark2 ? 0.05 : 0.03,
        child: Image.network(
          'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&q=80',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: dark2 ? D.bg : const Color(0xFFF1F5F9))))),
      SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      _sec('PROFILE'),
      const SizedBox(height:10),
      GlassCard(child:_editing
        ? Column(children:[
            _sf('Full Name',_n,D.cyan),const SizedBox(height:8),_sf('Degree',_d,D.emerald),const SizedBox(height:8),_sf('Career Goal',_g,D.fuchsia),const SizedBox(height:8),_sf('Skills',_s,D.cyan),const SizedBox(height:8),_sf('Interests',_int,D.amber),const SizedBox(height:8),_sf('City',_c,D.violet),
            const SizedBox(height:14),
            Row(children:[Expanded(child:OutlinedButton(style:OutlinedButton.styleFrom(side:const BorderSide(color:D.b2),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),onPressed:()=>setState(()=>_editing=false),child:Text('CANCEL',style:D.body(12,fw:FontWeight.w700)))),const SizedBox(width:10),Expanded(child:GradientButton(label:'SAVE',gradient:D.grad1,height:46,onTap:_save))]),
          ])
        : Row(children:[
            GestureDetector(onTap:_pickImg,child:Stack(children:[
              Container(width:64,height:64,decoration:BoxDecoration(gradient:D.grad1,shape:BoxShape.circle,boxShadow:[BoxShadow(color:D.indigo.withOpacity(.3),blurRadius:16)]),child:ClipOval(child:photo!=null&&photo.isNotEmpty&&File(photo).existsSync()?Image.file(File(photo),fit:BoxFit.cover):const Icon(Icons.person_rounded,color:Colors.white,size:32))),
              Positioned(bottom:0,right:0,child:Container(width:22,height:22,decoration:BoxDecoration(gradient:D.grad2,shape:BoxShape.circle,border:Border.all(color:D.bg,width:2)),child:const Icon(Icons.camera_alt_rounded,size:11,color:Colors.white))),
            ])),
            const SizedBox(width:14),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(u['name']??'', style: D.display(16, color: T.t1(context))),
              Text(auth.email.isNotEmpty?auth.email:'',style:D.body(11)),
              Text(u['goal']??'',style:D.body(11,color:D.cyan)),
              if((u['skills']??'').isNotEmpty)Text('🛠 ${u['skills']}',style:D.body(10)),
              if((u['city']??'').isNotEmpty)Text('📍 ${u['city']}',style:D.body(10)),
            ])),
  GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileBuilderScreen(isEdit: true),
      ),
    );
  },
  child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: D.indigo.withOpacity(.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: D.indigo.withOpacity(.25)),
    ),
    child: const Icon(Icons.edit_outlined, color: D.cyan, size: 18),
  ),
),          ])),

      const SizedBox(height:20),_sec('APPEARANCE'),const SizedBox(height:10),
      _tile(Theme.of(context).brightness==Brightness.dark?Icons.light_mode_outlined:Icons.dark_mode_outlined,D.cyan,'Dark Mode',Theme.of(context).brightness==Brightness.dark?'Enabled':'Disabled',trailing:Switch(value:Theme.of(context).brightness==Brightness.dark,activeColor:D.indigo,onChanged:(_){final m=Theme.of(context).brightness==Brightness.dark?ThemeMode.light:ThemeMode.dark;ref.read(themeProvider.notifier).state=m;StorageService.saveTheme(m==ThemeMode.dark);})),

      const SizedBox(height:20),_sec('NOTIFICATIONS'),const SizedBox(height:10),
      _tile(Icons.notifications_outlined,D.emerald,'Push Notifications',(settings['notifications']??true)?'Enabled':'Disabled',trailing:Switch(value:settings['notifications']??true,activeColor:D.indigo,onChanged:(_) async{ref.read(settingsProvider.notifier).toggle('notifications');if(!(settings['notifications']??true)){await NotificationService.showCareerTip();}else{await NotificationService.cancelAll();}})),

      if(auth.isLoggedIn)...[
        const SizedBox(height:20),_sec('SECURITY'),const SizedBox(height:10),
        GlassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('Change Password',style:D.display(14)),const SizedBox(height:14),
          _sf('New Password (min 6 chars)',_np,D.cyan,obscure:true),const SizedBox(height:12),
          GradientButton(label:'UPDATE PASSWORD',gradient:D.grad4,height:48,onTap:_changePass),
        ])).animate().fadeIn(),
      ],

      const SizedBox(height:20),_sec('APP INFO'),const SizedBox(height:10),
      _tile(Icons.info_outline_rounded,D.cyan,'Version','v6.0.0 — AI Career Guide Pro'),
      const SizedBox(height:8),
      _tile(Icons.auto_awesome,D.amber,'AI Features','Chat · Roadmap · Quiz · Resume · Interview · Salary'),

      const SizedBox(height:24),
      GestureDetector(onTap:_logout,child:Container(width:double.infinity,height:54,decoration:BoxDecoration(color:D.rose.withOpacity(.06),borderRadius:BorderRadius.circular(16),border:Border.all(color:D.rose.withOpacity(.25))),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.logout_rounded,color:D.rose,size:18),const SizedBox(width:10),Text('LOGOUT',style:D.body(13,fw:FontWeight.w800,color:D.rose))]))).animate().fadeIn(),
      const SizedBox(height:24),
    ])),  // SingleChildScrollView
    ]);   // Stack
  }

  Widget _sec(String t) => Text(t,style:D.body(10,fw:FontWeight.w800,color:D.t3));
  Widget _tile(IconData icon, Color col, String title, String sub, {Widget? trailing}) => GlassCard(padding:const EdgeInsets.symmetric(horizontal:16,vertical:13),child:Row(children:[Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:col.withOpacity(.12),borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:col,size:19)),const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title, style: D.body(13, fw: FontWeight.w600, color: T.t1(context))),Text(sub,style:D.body(11))])),if(trailing!=null)trailing])).animate().fadeIn().slideX(begin:.05);
  Widget _sf(String hint, TextEditingController ctrl, Color col, {bool obscure = false}) => TextField(
  controller: ctrl,
  obscureText: obscure,
  style: GoogleFonts.dmSans(color: T.t1(context), fontSize: 13),
  decoration: InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.dmSans(color: T.t3(context), fontSize: 12),
    filled: true,
    fillColor: T.surface(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: T.b1(context)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: col, width: 1.5),
    ),
  ),
);
}

// ══════════════════════════════════════════
// AI TOOL SCREENS
// ══════════════════════════════════════════

class ResumeScreen extends ConsumerStatefulWidget {
  const ResumeScreen({super.key});
  @override
  ConsumerState<ResumeScreen> createState() => _ResumeState();
}

class _ResumeState extends ConsumerState<ResumeScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  String _result = '';
  bool _loading = false;
  String? _fileName;
  Uint8List? _fileBytes;
  String _imageMime = 'image/jpeg';
  String _mode = 'text'; // 'text', 'image', 'pdf'
  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: 1500.ms)..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _ctrl.dispose(); super.dispose(); }
  Future<void> _pickImage() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 2000,
        imageQuality: 90,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        final name = img.name.isNotEmpty ? img.name : 'resume.jpg';
        final lower = name.toLowerCase();
        final mime = lower.endsWith('.png')
            ? 'image/png'
            : lower.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        setState(() {
          _fileName = name;
          _fileBytes = bytes;
          _imageMime = mime;
          _mode = 'image';
          _result = '';
        });
      }
    } catch (e) {
      _snack('Could not load image. Please try again.');
    }
  }

  Future<void> _pickPdf() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 2000,
        imageQuality: 92,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() {
          _fileName = img.name.isNotEmpty ? img.name : 'resume_page.jpg';
          _fileBytes = bytes;
          _imageMime = 'image/jpeg';
          _mode = 'pdf';
          _result = '';
        });
        return;
      }
    } catch (_) {}
    _snack('Could not open file. Try Image mode or paste text instead.');
  }

  Future<void> _analyze() async {
    if (_mode == 'text') {
      final text = _ctrl.text.trim();
      if (text.isEmpty) {
        _snack('Paste your resume text, or upload an image of your resume.');
        return;
      }
      setState(() => _loading = true);
      final r = await AI.resume(text);
      if (mounted) setState(() { _result = r; _loading = false; });
      return;
    }

    if (_fileBytes == null) {
      _snack('Please upload a file first.');
      return;
    }

    setState(() => _loading = true);
    final r = await AI.resume(
      _ctrl.text.trim(),
      imageBytes: _fileBytes,
      imageMime: _imageMime,
    );
    if (mounted) setState(() { _result = r; _loading = false; });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: D.rose,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16)));

  void _clear() => setState(() { _fileName = null; _fileBytes = null; _mode = 'text'; _result = ''; });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? D.bg : const Color(0xFFF1F5F9),
      appBar: AppBar(title: const Text('Resume Analyzer'), backgroundColor: Colors.transparent,
        actions: [if (_result.isNotEmpty || _fileName != null)
          IconButton(icon: const Icon(Icons.refresh_rounded, color: D.cyan), onPressed: _clear)]),
      body: Stack(children: [
        Positioned.fill(child: Opacity(opacity: dark ? 0.05 : 0.03,
          child: Image.network('https://images.unsplash.com/photo-1586281380349-632531db7ed4?w=800&q=80',
            fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()))),
        SingleChildScrollView(padding: const EdgeInsets.all(18), child: Column(children: [

          // ── Mode Tabs ──
          Container(
            decoration: BoxDecoration(color: dark ? D.card : Colors.white,
              borderRadius: BorderRadius.circular(18), border: Border.all(color: D.b1)),
            child: Row(children: [
              _tab('text', Icons.edit_note_rounded, 'Paste Text', D.indigo),
              _tab('image', Icons.image_outlined, 'Image', D.cyan),
              _tab('pdf', Icons.picture_as_pdf_rounded, 'PDF', D.rose),
            ])),

          const SizedBox(height: 16),

          // ── INPUT AREA ──
          if (_mode == 'text') ...[
            Container(
              decoration: BoxDecoration(color: dark ? D.card : Colors.white,
                borderRadius: BorderRadius.circular(18), border: Border.all(color: D.indigo.withOpacity(.25))),
              child: TextField(controller: _ctrl, maxLines: 10,
                style: GoogleFonts.dmSans(color: dark ? D.t1 : const Color(0xFF1E293B), fontSize: 13),
                decoration: InputDecoration(
                  hintText: '''Paste your full resume text here...

Example:
Name: Your Name
Experience: 2 years 
Skills: Dart, Firebase, Riverpod
Education: BS Computer Science — 2024
...''',
                  hintStyle: GoogleFonts.dmSans(color: D.t3, fontSize: 12),
                  filled: true, fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16)))),
          ],

          if (_mode == 'image') ...[
            GestureDetector(onTap: _fileBytes != null ? null : _pickImage,
              child: AnimatedContainer(duration: 300.ms,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: _fileBytes != null ? D.cyan.withOpacity(.08) : (dark ? D.card : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _fileBytes != null ? D.cyan : D.b1, width: _fileBytes != null ? 2 : 1)),
                child: Column(children: [
                  if (_fileBytes != null) ...[
                    ClipRRect(borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_fileBytes!, height: 220, width: double.infinity, fit: BoxFit.contain)),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.check_circle_rounded, color: D.cyan, size: 18),
                      const SizedBox(width: 6),
                      Text(_fileName ?? 'resume.jpg', style: D.body(12, fw: FontWeight.w600, color: D.cyan)),
                    ]),
                    const SizedBox(height: 8),
                    TextButton.icon(onPressed: _pickImage,
                      icon: const Icon(Icons.swap_horiz_rounded, color: D.t2, size: 16),
                      label: Text('Change Image', style: D.body(12, color: D.t2))),
                  ] else ...[
                    Container(padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: D.cyan.withOpacity(.1), shape: BoxShape.circle),
                      child: const Icon(Icons.image_search_rounded, size: 44, color: D.cyan)),
                    const SizedBox(height: 14),
                    Text('Upload resume image', style: D.display(14)),
                    const SizedBox(height: 6),
                    Text('JPG or PNG from your gallery', style: D.body(12, color: D.t2)),
                  ],
                ]))),
          ],

          if (_mode == 'pdf') ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _fileName != null ? D.rose.withOpacity(.08) : (dark ? D.card : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _fileName != null ? D.rose : D.b1, width: _fileName != null ? 2 : 1)),
              child: Column(children: [
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [D.rose, D.fuchsia]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: D.rose.withOpacity(.35), blurRadius: 20)]),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 44, color: Colors.white)),
                const SizedBox(height: 16),
                Text('PDF / Document page', style: D.display(16)),
                const SizedBox(height: 8),
                Text('Upload a clear photo of your PDF resume page for AI analysis', style: D.body(12, color: D.t2), textAlign: TextAlign.center),                const SizedBox(height: 16),
                // PDF Tips
                Container(padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: D.rose.withOpacity(.06),
                    borderRadius: BorderRadius.circular(14), border: Border.all(color: D.rose.withOpacity(.2))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How to analyze a PDF:', style: D.body(11, fw: FontWeight.w700, color: D.rose)),                    const SizedBox(height: 8),
                    ...[
                      'Describe your full resume content or paste text in the text field',
                      'Or tap the "Analyze" button — AI will provide general PDF feedback',
                      'For best results: Paste your resume in the text field',
                    ].map((tip) => Padding(padding: const EdgeInsets.only(bottom: 4),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('• ', style: D.body(11, color: D.rose)),
                        Expanded(child: Text(tip, style: D.body(11, color: T.t1(context)))),
                      ]))),
                  ])),
                const SizedBox(height: 14),
                // Additional text for PDF
                TextField(controller: _ctrl, maxLines: 5,
                  style: GoogleFonts.dmSans(color: dark ? D.t1 : const Color(0xFF1E293B), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Optional: paste extra resume text for better analysis...',      
                    hintStyle: GoogleFonts.dmSans(color: D.t3, fontSize: 12),
                    filled: true, fillColor: dark ? D.surface : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: D.b1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: D.rose, width: 1.5)),
                    contentPadding: const EdgeInsets.all(14))),
              ])),
          ],

          const SizedBox(height: 16),

          // ── Analyze Button ──
          GestureDetector(
            onTap: _loading ? null : _analyze,
            child: AnimatedContainer(duration: 200.ms,
              height: 54, width: double.infinity,
              decoration: BoxDecoration(
                gradient: _loading ? null : D.grad1,
                color: _loading ? D.card : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _loading ? [] : [BoxShadow(color: D.indigo.withOpacity(.4), blurRadius: 18, offset: const Offset(0, 6))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_loading)
                  const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else ...[
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                ],
                const SizedBox(width: 8),
                Text(_loading ? 'Analyzing Resume...' : 'Analyze My Resume',
                  style: D.display(13, fw: FontWeight.w700, color: Colors.white)),
              ]))),

          // ── Result ──
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: dark ? D.card : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: D.indigo.withOpacity(.25)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 16)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(gradient: D.grad1, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 18)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Analysis Complete', style: D.display(14)),
                    Text('AI Resume Review', style: D.body(11, color: D.t2)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(gradient: D.grad3, borderRadius: BorderRadius.circular(10)),
                    child: Text('DONE', style: D.body(10, fw: FontWeight.w800, color: Colors.white))),
                ]),
                const Divider(color: D.b1, height: 24),
                Text(_result, style: D.body(13, color: dark ? D.t1 : const Color(0xFF1E293B))),
              ])).animate().fadeIn().slideY(begin: .08),
          ],
          const SizedBox(height: 40),
        ])),
      ]),
    );
  }

  Widget _tab(String mode, IconData icon, String label, Color col) {
    final sel = _mode == mode;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() { _mode = mode; _result = ''; _fileName = null; _fileBytes = null; }),
      child: AnimatedContainer(duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: sel ? LinearGradient(colors: [col, col.withOpacity(.75)]) : null,
          borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Icon(icon, size: 18, color: sel ? Colors.white : D.t2),
          const SizedBox(height: 3),
          Text(label, style: D.body(10, fw: sel ? FontWeight.w700 : FontWeight.w400,
            color: sel ? Colors.white : D.t2)),
        ]))));
  }
}

class InterviewScreen extends ConsumerStatefulWidget {
  const InterviewScreen({super.key});
  @override
  ConsumerState<InterviewScreen> createState() => _InterviewState();
}
class _InterviewState extends ConsumerState<InterviewScreen> {
  String _result='', _diff='Beginner'; bool _loading=false;
  static const _diffs=['Beginner','Intermediate','Advanced'];
  @override
  Widget build(BuildContext context) {
    final u=ref.watch(userProvider);
    return Scaffold(backgroundColor: T.bg(context), appBar: AppBar(title: const Text('AI Interview Coach')),body:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(children:[
      GlassCard(gradient:LinearGradient(colors:[D.indigo.withOpacity(.1),D.violet.withOpacity(.07)]),border:D.indigo.withOpacity(.25),child:Row(children:[Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(gradient:D.grad1,borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.work_outline,color:Colors.white,size:18)),const SizedBox(width:12),Expanded(child:Text('Role: ${u['goal']}', style: D.display(14, color: T.t1(context))))])),
      const SizedBox(height:14),
      Row(children:_diffs.map((d){final s=d==_diff;return Expanded(child:GestureDetector(onTap:()=>setState(()=>_diff=d),child:AnimatedContainer(duration:200.ms,margin:const EdgeInsets.symmetric(horizontal:4),padding:const EdgeInsets.symmetric(vertical:12),decoration:BoxDecoration(gradient:s?D.grad1:null,color: s ? null : T.card(context),borderRadius:BorderRadius.circular(12),border:Border.all(color:s?D.indigo:D.b1)),child:Text(d,textAlign:TextAlign.center,style:D.body(12,fw:FontWeight.w700,color:s?Colors.white:D.t2)))));}).toList()),
      const SizedBox(height:14),
      GradientButton(label:_loading?'Generating...':'Get Question',gradient:D.grad1,loading:_loading,icon:Icons.record_voice_over_outlined,onTap:()async{setState(()=>_loading=true);final r=await AI.interview(u['goal']??'Software Engineer',_diff);if(mounted)setState((){_result=r;_loading=false;});}),
      if(_result.isNotEmpty)...[const SizedBox(height:16),GlassCard(border:D.cyan.withOpacity(.2),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_result, style: D.body(14, color: T.t1(context))),const SizedBox(height:12),TextButton.icon(onPressed:()async{setState(()=>_loading=true);final r=await AI.interview(u['goal']??'Software Engineer',_diff);if(mounted)setState((){_result=r;_loading=false;});},icon:const Icon(Icons.refresh_rounded,color:D.cyan,size:16),label:Text('Next Question',style:D.body(12,color:D.cyan)))])).animate().fadeIn()],
    ])));
  }
}

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});
  @override
  ConsumerState<SalaryScreen> createState() => _SalaryState();
}
class _SalaryState extends ConsumerState<SalaryScreen> {
  final _role=TextEditingController(); String _exp='0-1 Year',_city='Lahore',_result=''; bool _loading=false;
  static const _exps=['0-1 Year','1-2 Years','2-3 Years','3-5 Years','5+ Years'];
  static const _cities=['Lahore','Karachi','Islamabad','Rawalpindi','Remote'];
  @override
  void initState(){super.initState();_role.text=ref.read(userProvider)['goal']??'';}
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: T.bg(context), appBar: AppBar(title: const Text('AI Salary Estimator')),body:SingleChildScrollView(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Job Role',style:D.body(11,fw:FontWeight.w700,color:D.t3)),const SizedBox(height:8),
    TextField(controller: _role, style: GoogleFonts.dmSans(color: T.t1(context), fontSize: 14), decoration: InputDecoration(hintText: 'e.g. Flutter Developer', filled: true, fillColor: T.card(context),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:D.emerald,width:1.5)),hintStyle:GoogleFonts.dmSans(color:D.t3,fontSize:13))),
    const SizedBox(height:16),Text('Experience',style:D.body(11,fw:FontWeight.w700,color:D.t3)),const SizedBox(height:8),
    Wrap(spacing:8,runSpacing:8,children:_exps.map((e){final s=e==_exp;return GestureDetector(onTap:()=>setState(()=>_exp=e),child:AnimatedContainer(duration:200.ms,padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color: s ? D.emerald.withOpacity(.15) : T.card(context),borderRadius:BorderRadius.circular(20),border:Border.all(color:s?D.emerald:D.b1)),child:Text(e,style:D.body(12,fw:s?FontWeight.w700:FontWeight.w400,color:s?D.emerald:D.t2))));}).toList()),
    const SizedBox(height:16),Text('City',style:D.body(11,fw:FontWeight.w700,color:D.t3)),const SizedBox(height:8),
    Wrap(spacing:8,runSpacing:8,children:_cities.map((c){final s=c==_city;return GestureDetector(onTap:()=>setState(()=>_city=c),child:AnimatedContainer(duration:200.ms,padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color: s ? D.indigo.withOpacity(.15) : T.card(context),borderRadius:BorderRadius.circular(20),border: Border.all(color: s ? D.indigo : T.b1(context))),child:Text(c,style:D.body(12,fw:s?FontWeight.w700:FontWeight.w400,color:s?D.indigo:D.t2))));}).toList()),
    const SizedBox(height:20),
    GradientButton(label:_loading?'Estimating...':'Estimate Salary',gradient:D.grad3,loading:_loading,icon:Icons.attach_money_rounded,onTap:()async{setState(()=>_loading=true);final r=await AI.salary(_role.text.trim().isEmpty?'Software Engineer':_role.text.trim(),_exp,_city);if(mounted)setState((){_result=r;_loading=false;});}),
    if(_result.isNotEmpty)...[const SizedBox(height:16),GlassCard(border:D.emerald.withOpacity(.2),child:Text(_result, style: D.body(13, color: T.t1(context)))).animate().fadeIn()],
  ])));
}

// ══════════════════════════════════════════
// QUIZ BANK (fallback)
// ══════════════════════════════════════════

final List<Map<String,dynamic>> _qBank=[
  {'q':'What does LLM stand for in Artificial Intelligence?','opts':['Long Learning Mode','Large Language Model','Linear Logic Machine','Low Level Memory'],'correct':1},
  {'q':'What is overfitting in machine learning?','opts':['When a model trains too fast','When a model performs well on new data','When a model memorizes training data but fails on new data','When a model uses too much memory'],'correct':2},
  {'q':'Which architecture does ChatGPT use?','opts':['CNN','RNN','LSTM','Transformer'],'correct':3},
  {'q':'What is the main purpose of Prompt Engineering?','opts':['To write better code','To get the best output from an LLM','To train AI models faster','To reduce API costs'],'correct':1},
  {'q':'What does API stand for?','opts':['Apple Phone Interface','Application Programming Interface','Auto Program Index','All Power Integration'],'correct':1},
  {'q':'What is Flutter primarily used for?','opts':['Backend development','Database management','Cross-platform mobile app development','Machine learning'],'correct':2},
  {'q':'Which language is used to write Flutter apps?','opts':['Python','Java','Kotlin','Dart'],'correct':3},
  {'q':'What is Firebase Firestore?','opts':['A relational SQL database','A NoSQL cloud database by Google','An image storage service','A machine learning platform'],'correct':1},
  {'q':'What does Riverpod provide in Flutter?','opts':['UI animations','HTTP networking','State management','Database queries'],'correct':2},
  {'q':'What is the purpose of Git in software development?','opts':['UI design','Version control and code collaboration','Database management','API testing'],'correct':1},
  {'q':'What does REST stand for in web development?','opts':['Remote Execution Standard Technology','Representational State Transfer','Real-time Event Streaming Technology','Resource Encoding Standard Transfer'],'correct':1},
  {'q':'In a REST API, which HTTP method is used to retrieve data?','opts':['POST','PUT','DELETE','GET'],'correct':3},
  {'q':'What is the purpose of async/await in Dart?','opts':['To speed up the CPU','To handle asynchronous operations without blocking the UI','To manage database connections','To compress images'],'correct':1},
  {'q':'What is Supervised Learning?','opts':['Learning without any data','Learning from labeled training data','Learning by trial and error','Learning from unlabeled data'],'correct':1},
  {'q':'What is Unsupervised Learning?','opts':['Learning from labeled data','Learning with a teacher','Finding patterns in unlabeled data','Reinforcement-based learning'],'correct':2},
  {'q':'What does GPU stand for and why is it used in AI training?','opts':['General Processing Unit — for display','Graphics Processing Unit — for parallel computation','Global Processing Utility — for networking','General Purpose Utility — for storage'],'correct':1},
  {'q':'What is Docker used for in software development?','opts':['Designing UI mockups','Containerizing applications for consistent environments','Managing databases','Tracking code versions'],'correct':1},
  {'q':'What is the difference between AI and Machine Learning?','opts':['They are exactly the same','AI is a subset of Machine Learning','Machine Learning is a subset of AI','Neither is related to computers'],'correct':2},
  {'q':'What is a Neural Network inspired by?','opts':['Solar systems','The human brain','Plant root systems','Ocean wave patterns'],'correct':1},
  {'q':'What does NLP stand for in AI?','opts':['Network Layer Protocol','Natural Language Processing','Neural Learning Program','Numeric Logic Processing'],'correct':1},
  {'q':'What is the purpose of a StatefulWidget in Flutter?','opts':['To show static content only','To handle UI that changes over time based on state','To make network requests','To store data in a database'],'correct':1},
  {'q':'What is Firebase Authentication used for?','opts':['Storing images','Managing user login and signup securely','Running backend logic','Hosting websites'],'correct':1},
  {'q':'What does the term Deployment mean in software development?','opts':['Writing the initial code','Releasing the application for real users','Testing the application locally','Designing the database schema'],'correct':1},
  {'q':'What is a Pull Request (PR) in Git?','opts':['Downloading code from a server','Requesting to merge code changes into a main branch','Deleting a branch','Creating a new repository'],'correct':1},
  {'q':'What is Computer Vision in AI?','opts':['A way to improve monitor displays','AI technology that enables machines to interpret visual data','A programming language for graphics','A database for storing images'],'correct':1},
  {'q':'What is the role of a Data Scientist?','opts':['Only writing code','Designing mobile apps','Analyzing data to extract insights and build predictive models','Managing server infrastructure'],'correct':2},
  {'q':'What is Sentiment Analysis in NLP?','opts':['Translating text to another language','Detecting the emotional tone of text','Summarizing long documents','Generating new text content'],'correct':1},
  {'q':'What is Edge Computing?','opts':['Computing done only in data centers','Processing data closer to its source to reduce latency','A new type of CPU architecture','Cloud storage optimization'],'correct':1},
  {'q':'What does the term Fine-tuning mean in AI?','opts':['Adjusting hardware components','Further training a pre-trained model on specific data','Deleting unnecessary model weights','Compressing a model for mobile devices'],'correct':1},
  {'q':'What is a Vector Database used for in AI applications?','opts':['Storing traditional tabular data','Efficient similarity search for AI embeddings and memory','Running SQL queries','Hosting web applications'],'correct':1},
  {'q':'What is RAG (Retrieval Augmented Generation)?','opts':['A type of neural network','Combining a language model with real-time data retrieval for accurate answers','A database indexing method','A UI design framework'],'correct':1},
  {'q':'What does AGI stand for?','opts':['Advanced Graphics Interface','Automated General Intelligence','Artificial General Intelligence','Applied GPU Infrastructure'],'correct':2},
  {'q':'What is the purpose of an Activity Diagram in UML?','opts':['To show database tables','To model the workflow or flow of control in a system','To describe class relationships','To design UI screens'],'correct':1},
  {'q':'What is a Software Requirement Specification (SRS)?','opts':['A marketing document','A document that describes what a software system should do','A list of programming languages used','A database schema document'],'correct':1},
  {'q':'What is the purpose of Unit Testing in software development?','opts':['Testing the entire application at once','Testing individual components or functions in isolation','Testing the network connection','Testing the database performance'],'correct':1},
];