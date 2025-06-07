import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _backendHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '10.0.2.2:8000');

Future<String> initializeSession(SharedPreferences prefs, String userId) async {
  var sessionId = prefs.getString('sessionId');
  if (sessionId == null) {
    print('sessionId is null, creating new session');
    try {
      final response = await http.post(
        Uri.parse(
            'http://$_backendHost/apps/learning_agent/users/$userId/sessions'),
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