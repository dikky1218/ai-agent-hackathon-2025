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
  void dispose() {
    super.dispose();
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
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // キーボードによる自動リサイズを無効化
      body: FutureBuilder<void>(
        future: _loadHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Stack(
              children: [
                // 背景のPageView
                PageView.builder(
                  itemCount: 3, // ページ数を指定
                  itemBuilder: (context, index) {
                    return Container(
                      color: _getPageColor(index),
                      child: Center(
                        child: Text(
                          'Page ${index + 1}',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
                // DraggableScrollableSheet（チャット入力の分のスペースを確保）
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 80 + keyboardHeight, // チャット入力とキーボードの分のスペースを確保
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.1,
                    maxChildSize: 1.0,
                    snap: true,
                    snapSizes: const [0.1, 0.4, 1.0],
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
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                            // チャットビュー
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: 20,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text('${index + 1}'),
                                    ),
                                    title: Text('メッセージ ${index + 1}'),
                                    subtitle: Text('これはテスト用のメッセージです。'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // チャット入力部分（画面下部に独立して固定）
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: keyboardHeight, // キーボードの上に配置
                  child: _buildChatInput(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // ヘルパーメソッド
  Color _getPageColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // チャット入力ウィジェット
  Widget _buildChatInput() {
    final TextEditingController controller = TextEditingController();
    
    return Container(
      padding: EdgeInsets.fromLTRB(
        8.0, 
        8.0, 
        8.0, 
        8.0 + MediaQuery.of(context).viewPadding.bottom
      ), // セーフエリアを考慮したパディング
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 添付ボタン
            IconButton(
              onPressed: () {
                // 添付機能の実装
                print('添付ボタンが押されました');
              },
              icon: const Icon(Icons.add, color: Colors.grey),
            ),
            // テキスト入力フィールド
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'メッセージを入力...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 送信ボタン
            Container(
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // 送信機能の実装
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    print('送信: $text');
                    controller.clear();
                  }
                },
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 