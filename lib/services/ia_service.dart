import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class IAService {
  static const _url = 'https://llamaria-2o5lsg4hxa-uc.a.run.app';

  static Future<String?> llamar(String prompt, {int maxTokens = 2000}) async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'maxTokens': maxTokens,
          }
        }),
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['result']?['content'] as List?)?.first['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> chat(
      List<Map<String, String>> historial, String sistemaPrompt) async {
    final token = await _token();
    if (token == null) return null;
    final messages = [
      {'role': 'user', 'content': sistemaPrompt},
      ...historial.map((m) => {'role': m['role']!, 'content': m['text']!}),
    ];
    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {'messages': messages, 'maxTokens': 1500}
        }),
      );
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (body['result']?['content'] as List?)?.first['text'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> llamarJSON(String prompt) async {
    final texto = await llamar(prompt, maxTokens: 3000);
    if (texto == null) return null;
    try {
      String limpio = texto.trim();
      final ini = limpio.indexOf('{');
      final fin = limpio.lastIndexOf('}');
      if (ini != -1 && fin != -1) limpio = limpio.substring(ini, fin + 1);
      return jsonDecode(limpio) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _token() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      try {
        final c = await FirebaseAuth.instance.signInAnonymously();
        user = c.user;
      } catch (_) {
        return null;
      }
    }
    try {
      return await user?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
