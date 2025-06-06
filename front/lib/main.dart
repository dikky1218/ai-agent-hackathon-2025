import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _backendHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '10.0.2.2:8000');
const backendUrl = 'http://$_backendHost/run'; // エミュレータ↔ローカル

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
        home: ChatPage(userId: userId, sessionId: sessionId),
      );
}

class CustomBackendProvider extends LlmProvider with ChangeNotifier {
  CustomBackendProvider({required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;
  final _history = <ChatMessage>[];

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> history) {
    _history.clear();
    _history.addAll(history);
    notifyListeners();
  }

  @override
  Stream<String> generateStream(String prompt,
      {Iterable<Attachment> attachments = const []}) async* {
    try {
      final res = await http.post(Uri.parse(backendUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "appName": "learning_agent",
            "userId": userId,
            "sessionId": sessionId,
            "newMessage": {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            },
            "streaming": false
          }));

      if (res.statusCode == 200) {
        final decodedBody = jsonDecode(res.body) as List;
        if (decodedBody.isNotEmpty) {
          final lastMessage = decodedBody.last as Map<String, dynamic>;
          final parts =
              (lastMessage['content'] as Map<String, dynamic>)['parts'] as List;
          if (parts.isNotEmpty) {
            final part = parts.first as Map<String, dynamic>;
            if (part.containsKey('text')) {
              final reply = part['text'] as String;
              yield reply;
            }
          }
        }
      } else {
        throw Exception('Backend error ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  @override
  Stream<String> sendMessageStream(String prompt,
      {Iterable<Attachment> attachments = const []}) async* {
    final userMessage = ChatMessage.user(prompt, attachments);
    final llmMessage = ChatMessage.llm();
    _history.addAll([userMessage, llmMessage]);
    notifyListeners();

    try {
      final res = await http.post(Uri.parse(backendUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "appName": "multi_tool_agent",
            "userId": userId,
            "sessionId": sessionId,
            "newMessage": {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            },
            "streaming": false
          }));

      if (res.statusCode == 200) {
        final decodedBody = jsonDecode(res.body) as List;
        if (decodedBody.isNotEmpty) {
          final lastMessage = decodedBody.last as Map<String, dynamic>;
          final parts =
              (lastMessage['content'] as Map<String, dynamic>)['parts'] as List;
          if (parts.isNotEmpty) {
            final part = parts.first as Map<String, dynamic>;
            if (part.containsKey('text')) {
              final reply = part['text'] as String;
              llmMessage.append(reply);
              notifyListeners();
              yield reply;
            }
          }
        }
      } else {
        final error = 'Backend error ${res.statusCode}';
        llmMessage.append(error);
        notifyListeners();
        throw Exception(error);
      }
    } catch (e) {
      final error = 'Error: $e';
      llmMessage.append(error);
      notifyListeners();
      throw Exception(error);
    }
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ADK Chat Demo')),
        body: LlmChatView(
          provider: CustomBackendProvider(
              userId: widget.userId, sessionId: widget.sessionId),
        ),
      );
}
