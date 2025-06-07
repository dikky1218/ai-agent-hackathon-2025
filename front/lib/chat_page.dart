import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'api_client.dart';

class CustomBackendProvider extends LlmProvider with ChangeNotifier {
  CustomBackendProvider({required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;
  final _history = <ChatMessage>[];
  final _apiClient = ApiClient();

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
      final reply = await _apiClient.postMessage(
        userId: userId,
        sessionId: sessionId,
        prompt: prompt,
      );
      yield reply;
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
      final reply = await _apiClient.postMessage(
          userId: userId, sessionId: sessionId, prompt: prompt);

      llmMessage.append(reply);
      notifyListeners();
      yield reply;
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
        body: LlmChatView(
          provider: CustomBackendProvider(
              userId: widget.userId, sessionId: widget.sessionId),
        ),
      );
} 