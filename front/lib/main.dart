import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'split_page.dart';

const _backendHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '10.0.2.2:8000');

Future<String> _initializeSession(SharedPreferences prefs, String userId) async {
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? const Uuid().v4();
  await prefs.setString('userId', userId);

  final sessionId = await _initializeSession(prefs, userId);
  print('sessionId: $sessionId');
  print('userId: $userId');

  runApp(MyApp(userId: userId, sessionId: sessionId));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ADK Chat',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: SplitPage(userId: userId, sessionId: sessionId),
      );
}
