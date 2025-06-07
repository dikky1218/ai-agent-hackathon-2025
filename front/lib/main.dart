import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'split_page.dart';
import 'api_client.dart';
import 'services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userId = await getOrCreateUserId();
  final sessionId = await initializeSession(userId);
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
