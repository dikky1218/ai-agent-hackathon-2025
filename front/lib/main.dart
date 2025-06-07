import 'package:flutter/material.dart';
import 'split_page.dart';
import 'services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userId = await getOrCreateUserId();
  print('userId: $userId');

  runApp(MyApp(userId: userId));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ADK Chat',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: SplitPage(userId: userId),
      );
}
