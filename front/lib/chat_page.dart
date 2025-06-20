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
      final messages = session.events.expand<ChatMessage>((event) {
        final text = event.content.parts
            .where((part) => part.text != null)
            .map((part) => part.text!)
            .join('\\n');

        if (event.author == 'user') {
          return [ChatMessage.user(text, [])];
        } else if (text.isNotEmpty) {
          return [ChatMessage.llm()..append(text)];
        }
        return [];
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
      final replies = await _apiClient.postMessage(
        userId: userId,
        sessionId: sessionId,
        prompt: prompt,
        attachments: attachments,
      );
      for (final reply in replies) {
        yield reply;
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
      final replies = await _apiClient.postMessage(
          userId: userId,
          sessionId: sessionId,
          prompt: prompt,
          attachments: attachments);

      for (final reply in replies) {
        llmMessage.append(reply);
        notifyListeners();
        yield reply;
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
  late CustomBackendProvider _provider;
  late Future<void> _loadHistoryFuture;

  @override
  void initState() {
    super.initState();
    _resetChat();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionId != oldWidget.sessionId) {
      setState(() {
        _resetChat();
      });
    }
  }

  void _resetChat() {
    _provider = CustomBackendProvider(
      userId: widget.userId,
      sessionId: widget.sessionId,
    );
    _loadHistoryFuture = _provider.loadHistory();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: FutureBuilder<void>(
          future: _loadHistoryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.3,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.3, 0.6, 0.9],
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ドラッグハンドル
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // チャットビュー
                        Expanded(
                          child: LlmChatView(
                            provider: _provider,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      );
} 