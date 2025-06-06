import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:http/http.dart' as http;

const backendUrl = 'http://10.0.2.2:8000/run'; // エミュレータ↔ローカル

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'ADK Chat',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
        home: const ChatPage(),
      );
}

class CustomBackendProvider extends LlmProvider with ChangeNotifier {
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
            "appName": "multi_tool_agent",
            "userId": "user",
            "sessionId": "d02dd388-8469-4705-b262-1f6897c03846",
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
            "userId": "user",
            "sessionId": "d02dd388-8469-4705-b262-1f6897c03846",
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
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ADK Chat Demo')),
        body: LlmChatView(
          provider: CustomBackendProvider(),
        ),
      );
}
