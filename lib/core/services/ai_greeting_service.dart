import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/secure_config.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class AIGreetingService {
  static const String _cacheKey = 'ai_greeting_cache';
  static const String _cacheTimestampKey = 'ai_greeting_timestamp';
  static const Duration _cacheDuration = Duration(hours: 4);

  Future<String> getPersonalizedGreeting(UserProfile? user) async {
    if (user == null) {
      return _getFallbackGreeting();
    }

    final cachedGreeting = await _getCachedGreeting();
    if (cachedGreeting != null) {
      return cachedGreeting;
    }

    try {
      final greeting = await _generateAIGreeting(user);
      await _cacheGreeting(greeting);
      return greeting;
    } catch (e) {
      logger.e('Error generating AI greeting', error: e);
      return _getFallbackGreeting();
    }
  }

  Future<String?> _getCachedGreeting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();

        if (now.difference(cacheTime) < _cacheDuration) {
          return prefs.getString(_cacheKey);
        }
      }
    } catch (e) {
      logger.w('Error reading cached greeting', error: e);
    }
    return null;
  }

  Future<void> _cacheGreeting(String greeting) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, greeting);
      await prefs.setInt(
          _cacheTimestampKey, DateTime.now().millisecondsSinceEpoch,);
    } catch (e) {
      logger.w('Error caching greeting', error: e);
    }
  }

  Future<String> _generateAIGreeting(UserProfile user) async {
    final openAIKey = SecureConfig.openAIApiKey;

    final prompt = _buildPrompt(user);

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $openAIKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                "You are a friendly, enthusiastic contests companion that creates personalized greetings. Keep greetings under 8 words, upbeat, and relevant to the user's contests journey.",
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'max_tokens': 30,
        'temperature': 0.9,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final greeting =
          (data['choices'] as List<dynamic>)[0]['message']['content'] as String;
      return greeting.trim();
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  String _buildPrompt(UserProfile user) {
    final parts = <String>[];

    parts.add('Create a personalized greeting for ${user.name}.');

    if (user.streak > 0) {
      parts.add('They have a ${user.streak}-day login streak.');
    }

    if (user.contestsEntered > 0) {
      parts.add("They've entered ${user.contestsEntered} contests.");
    }

    if (user.tier != 'Rookie') {
      parts.add("They're a ${user.tier} tier member.");
    }

    final hour = DateTime.now().hour;
    final timeOfDay = hour < 12
        ? 'morning'
        : hour < 17
            ? 'afternoon'
            : 'evening';
    parts.add("It's $timeOfDay time.");

    parts.add('Make it encouraging about winning contests.');

    return parts.join(' ');
  }

  String _getFallbackGreeting() {
    final hour = DateTime.now().hour;

    final morningGreetings = [
      "Let's Win",
      'Rise Up',
      'Game On',
      'Get It',
      "Let's Go",
    ];

    final afternoonGreetings = [
      'Crushing It',
      'On Fire',
      'Unstoppable',
      'Keep Going',
      'Beast Mode',
    ];

    final eveningGreetings = [
      'Prime Time',
      "Let's Win",
      'Still Going',
      'Own It',
      'Win Big',
    ];

    final lateNightGreetings = [
      'Night Owl',
      'Keep Going',
      'Hustle On',
      'Never Stop',
    ];

    List<String> greetings;
    if (hour >= 5 && hour < 12) {
      greetings = morningGreetings;
    } else if (hour >= 12 && hour < 17) {
      greetings = afternoonGreetings;
    } else if (hour >= 17 && hour < 22) {
      greetings = eveningGreetings;
    } else {
      greetings = lateNightGreetings;
    }

    final index = DateTime.now().day % greetings.length;
    return greetings[index];
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      logger.w('Error clearing greeting cache', error: e);
    }
  }
}
