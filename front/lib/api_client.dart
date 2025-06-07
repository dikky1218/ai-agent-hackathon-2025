import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _backendHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '10.0.2.2:8000');

const host = 'http://$_backendHost';

class Session {
  final String appName;
  final List<dynamic> events;
  final String id;
  final double lastUpdateTime;
  final Map<String, dynamic> state;
  final String userId;

  Session({
    required this.appName,
    required this.events,
    required this.id,
    required this.lastUpdateTime,
    required this.state,
    required this.userId,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      appName: json['appName'] as String,
      events: json['events'] as List<dynamic>,
      id: json['id'] as String,
      lastUpdateTime: (json['lastUpdateTime'] as num).toDouble(),
      state: json['state'] as Map<String, dynamic>,
      userId: json['userId'] as String,
    );
  }
}

class ApiClient {
  Future<String> postMessage({
    required String userId,
    required String sessionId,
    required String prompt,
  }) async {
    final body = {
      "app_name": "learning_agent",
      "user_id": userId,
      "session_id": sessionId,
      "new_message": {
        "role": "user",
        "parts": [
          {"text": prompt}
        ]
      },
      "streaming": false
    };

    final res = await http.post(
      Uri.parse('$host/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final decodedBody = jsonDecode(res.body) as List;
      if (decodedBody.isNotEmpty) {
        final lastMessage = decodedBody.last as Map<String, dynamic>;
        final parts =
            (lastMessage['content'] as Map<String, dynamic>)['parts'] as List;
        if (parts.isNotEmpty) {
          final part = parts.first as Map<String, dynamic>;
          if (part.containsKey('text')) {
            return part['text'] as String;
          }
        }
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Backend error ${res.statusCode}');
    }
  }

  Future<List<Session>> getSessions(String userId) async {
    final res = await http.get(
      Uri.parse('$host/apps/learning_agent/users/$userId/sessions'),
    );

    if (res.statusCode == 200) {
      final decodedBody = jsonDecode(res.body) as List;
      return decodedBody
          .map((sessionJson) =>
              Session.fromJson(sessionJson as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get sessions: ${res.statusCode}');
    }
  }
}

Future<String> initializeSession(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  var sessionId = prefs.getString('sessionId');
  if (sessionId == null) {
    print('sessionId is null, creating new session');
    try {
      final response = await http.post(
        Uri.parse(
            '$host/apps/learning_agent/users/$userId/sessions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'appName': 'learning_agent',
          'events': [],
          'lastUpdateTime': DateTime.now().millisecondsSinceEpoch / 1000,
          'state': {},
          'userId': userId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        sessionId = jsonDecode(response.body)['id'];
        if (sessionId == null) {
          throw Exception('セッションIDの作成に失敗しました。');
        }
        await prefs.setString('sessionId', sessionId);
      }
    } catch (e) {
      // Session creation failed. The app will not start if session ID is null.
      print('Failed to create session on server: $e');
    }
  } else {
    print('sessionId is not null, using existing session');
    sessionId = prefs.getString('sessionId');
  }

  if (sessionId == null) {
    throw Exception('セッションIDの作成または取得に失敗しました。');
  }
  return sessionId;
} 