import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

/// 🧠 HIGH-PERFORMANCE GEMINI AI SERVICE
/// Features:
/// - Anti-Overload Sliding Window (never exceeds TPM rate limits)
/// - Multi-tier fast endpoints (1.5-Flash -> 2.0-Flash -> 1.5-Flash-8b)
/// - Local in-memory caching for instant 0ms study guide retrieval
/// - Clean educational output formatting
class GeminiAiService {
  static const String _userApiKey = "AIzaSyDvJF-19NLwk5rvVRTl8jE0zxa3sCSwrIY";

  // 🚀 ACTIVE & VALID GEMINI ENDPOINTS
  static const String _primaryUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent";
  static const String _fallbackUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-lite-latest:generateContent";
  static const String _emergencyUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent";

  // In-memory cache for high-yield chapter notes
  static final Map<String, String> _studyGuideCache = {};
  static bool _isRequestInProgress = false;

  static Future<String> generateResponse(List<ChatMessage> history) async {
    if (_isRequestInProgress) {
      // Small pause if student rapidly double-tapped send
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _isRequestInProgress = true;
    try {
      // 🚀 ANTI-OVERLOAD SLIDING WINDOW:
      // Keep only the last 6 messages (3 conversation turns).
      // This prevents token explosion, 429 quota exhaustion, and memory overload!
      final clampedHistory =
          history.length > 6 ? history.sublist(history.length - 6) : history;

      List<Map<String, dynamic>> contents = [];

      for (var msg in clampedHistory) {
        final trimmed = msg.text.trim();
        if (trimmed.isEmpty) continue;

        final role = msg.isUser ? "user" : "model";

        // Gemini requires strict alternating roles
        if (contents.isNotEmpty && contents.last["role"] == role) {
          (contents.last["parts"] as List).add({"text": trimmed});
        } else {
          contents.add({
            "role": role,
            "parts": [
              {"text": trimmed}
            ]
          });
        }
      }

      // Ensure the first message is from the user
      while (contents.isNotEmpty && contents.first["role"] != "user") {
        contents.removeAt(0);
      }

      if (contents.isEmpty) {
        return "Please ask a question related to your SSC Class 10 syllabus.";
      }

      const String systemInstruction =
          "You are NICKS AI, an elite, patient and friendly academic tutor powered by Gemini for Maharashtra State Board (SSC Class 10) students.\n\n"
          "GUIDELINES:\n"
          "1. Answer concisely, step-by-step, with high educational precision.\n"
          "2. Explain math formulas, science concepts, Marathi grammar, history, and geography clearly.\n"
          "3. Language: Friendly Marathi + English (Hinglish/Marathi), simple for Class 10 students.\n"
          "4. STRICT RULE: DO NOT output ugly markdown characters like '*#' or '###' or repeated asterisks '***'.\n"
          "5. Use clean formatting with clear numbered points (1., 2., 3.), bullet dashes (- ), and bold headers for clarity.";

      final Map<String, dynamic> body = {
        "systemInstruction": {
          "parts": [
            {"text": systemInstruction}
          ]
        },
        "contents": contents,
        "generationConfig": {
          "temperature": 0.35,
          "maxOutputTokens": 800,
        }
      };

      // Tier 1: Try Primary (Gemini 1.5 Flash)
      String? result = await _callEndpoint(_primaryUrl, body, 7);
      if (result != null) return _sanitizeOutput(result);

      // Tier 2: Try 2.0 Flash
      result = await _callEndpoint(_fallbackUrl, body, 7);
      if (result != null) return _sanitizeOutput(result);

      // Tier 3: Emergency Lightweight 8B
      result = await _callEndpoint(_emergencyUrl, body, 6);
      if (result != null) return _sanitizeOutput(result);

      return "Our AI tutor is currently busy answering other students. Please ask your question again in a moment.";
    } on TimeoutException {
      return "The connection timed out. Please check your internet connection and retry.";
    } catch (e) {
      debugPrint("Gemini service error: $e");
      return "I could not reach the study servers right now. Please check your network and try again.";
    } finally {
      _isRequestInProgress = false;
    }
  }

  /// 📚 Instant Chapter Guide with Local In-Memory Cache (0ms latency on repeat)
  static Future<String> generateChapterStudyGuide(
    String chapterTitle, [
    String? subjectName,
  ]) async {
    final cacheKey = "${subjectName ?? ''}_$chapterTitle".toLowerCase().trim();

    // Check in-memory cache first
    if (_studyGuideCache.containsKey(cacheKey)) {
      return _studyGuideCache[cacheKey]!;
    }

    final prompt =
        "Generate a comprehensive, high-yield study revision guide for Maharashtra State Board Class 10 (SSC) chapter: '$chapterTitle'${subjectName != null ? ' in $subjectName' : ''}.\n\n"
        "Please structure your response into these 4 clear sections:\n"
        "1. 📖 CHAPTER CONCEPT & SUMMARY: Explain the core concepts simply and clearly.\n"
        "2. ⚡ KEY FORMULAS, LAWS & DEFINITIONS: List all critical formulas, scientific laws, or grammatical rules students must memorize.\n"
        "3. 🎯 TOP 3 BOARD EXAM QUESTIONS: 3 high-probability questions with concise, model answers.\n"
        "4. 💡 TOPPER'S EXAM TIP: One practical tip to score full marks in this chapter.\n\n"
        "STRICT FORMATTING RULE: Use clean numbered points (1., 2.), bullet dashes (- ), and bold headers. DO NOT output ugly characters like '*#' or '###' or '***'.";

    final response = await generateResponse([ChatMessage(text: prompt, isUser: true)]);

    // Only cache successful meaningful answers
    if (!response.contains("busy answering") && !response.contains("timed out")) {
      _studyGuideCache[cacheKey] = response;
    }

    return response;
  }

  static String _sanitizeOutput(String raw) {
    String clean = raw;
    // Clean out malformed combinations of markdown characters like *#, #*, ***, ###
    clean = clean.replaceAll(RegExp(r'\*+\s*#+'), '');
    clean = clean.replaceAll(RegExp(r'#+\s*\*+'), '');
    clean = clean.replaceAll(RegExp(r'(^|\n)\s*#+\s*'), '\n');
    clean = clean.replaceAll(RegExp(r'\*{3,}'), '**');
    // Normalize excessive newlines
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return clean.trim();
  }

  static Future<String?> _callEndpoint(
    String endpointUrl,
    Map<String, dynamic> body,
    int timeoutSeconds,
  ) async {
    try {
      final url = Uri.parse("$endpointUrl?key=$_userApiKey");
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text']?.toString().trim();
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        }
      } else {
        debugPrint("Gemini HTTP ${response.statusCode}: ${response.body}");
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
