import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class ApiClient {
  Future<AuthUser> register({
    required String displayName,
    required String email,
    required String password,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await http.post(
      AppConfig.api('/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'displayName': displayName,
        'email': email,
        'password': password,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      }),
    );
    return _decodeAuth(response);
  }

  Future<AuthUser> login(String email, String password) async {
    final response = await http.post(
      AppConfig.api('/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decodeAuth(response);
  }

  Future<List<AppUser>> users(String token) async {
    final response = await http.get(
      AppConfig.api('/api/users'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((x) => AppUser.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> incomingCalls(String token) async {
    final response = await http.get(
      AppConfig.api('/api/calls/sessions/incoming'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((x) => Map<String, dynamic>.from(x as Map)).toList();
  }

  Future<String> createCall({
    required String token,
    required String startedByUserId,
    required String participantUserId,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final response = await http.post(
      AppConfig.api('/api/calls/sessions'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'startedByUserId': startedByUserId,
        'participantUserId': participantUserId,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      }),
    );
    if (response.statusCode >= 400) throw Exception(response.body);
    return jsonDecode(response.body)['callSessionId'];
  }

  Future<void> endCall(String token, String callSessionId) async {
    await http.post(
      AppConfig.api('/api/calls/sessions/end'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'callSessionId': callSessionId}),
    );
  }

  AuthUser _decodeAuth(http.Response response) {
    if (response.statusCode >= 400) throw Exception(response.body);
    return AuthUser.fromJson(jsonDecode(response.body));
  }
}
