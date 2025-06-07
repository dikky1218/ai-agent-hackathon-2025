import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'split_page.dart';
import 'api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? const Uuid().v4();
  await prefs.setString('userId', userId);

  final sessionId = await initializeSession(prefs, userId);
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
