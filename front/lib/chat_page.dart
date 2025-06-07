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

  Future<void> loadHistory() async {
    try {
      final session = await _apiClient.getSession(userId, sessionId);
      final messages = session.events.map<ChatMessage>((event) {
        final text = event.content.parts
            .where((part) => part.text != null)
            .map((part) => part.text)
            .join('\\n');
        if (event.author == 'user') {
          return ChatMessage.user(text, []);
        } else {
          return ChatMessage.llm()..append(text);
        }
      }).toList();
      print('messages: $messages');

      _history.clear();
      _history.addAll(messages);
      notifyListeners();
    } catch (e) {
      // Handle or log error appropriately
      print('Error loading chat history: $e');
      _history.add(ChatMessage.llm()..append('Failed to load chat history.'));
      notifyListeners();
    }
  }

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
  late final CustomBackendProvider _provider;
  late final Future<void> _loadHistoryFuture;

  @override
  void initState() {
    super.initState();
    _provider = CustomBackendProvider(
      userId: widget.userId,
      sessionId: widget.sessionId,
    );
    _loadHistoryFuture = _provider.loadHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: FutureBuilder<void>(
          future: _loadHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return LlmChatView(
                provider: _provider,
              );
            }
          },
        ),
      );
} 