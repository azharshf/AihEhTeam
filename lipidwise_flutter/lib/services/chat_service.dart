import 'dart:convert';
import 'package:http/http.dart' as http;

/// Talks to Azhar's LipidWise AI chatbot backend (FastAPI + RAG).
/// Base URL points at the local dev server by default — update for deployment.
class ChatService {
  static const String baseUrl = 'http://localhost:8000';

  Future<Map<String, dynamic>> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'session_id': sessionId, 'message': message}),
    );

    if (res.statusCode != 200) {
      throw Exception('Chat request failed (${res.statusCode}): ${res.body}');
    }

    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Sends the patient's intake data to the chatbot backend so it can
  /// personalize responses. Safe to call with a partial map.
  Future<void> syncPatientProfile({
    required String sessionId,
    required Map<String, dynamic> profile,
  }) async {
    final body = <String, dynamic>{'session_id': sessionId, ...profile};
    await http.post(
      Uri.parse('$baseUrl/patient/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  Future<List<Map<String, dynamic>>> getHistory(String sessionId) async {
    final res = await http.get(Uri.parse('$baseUrl/chat/history/$sessionId'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['history'] ?? []);
  }
}
