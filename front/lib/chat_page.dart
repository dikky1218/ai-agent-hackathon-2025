import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'api_client.dart';
import 'chat_input_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _apiClient = ApiClient();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessageHistory();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionId != oldWidget.sessionId) {
      _loadMessageHistory();
    }
  }

  Future<void> _loadMessageHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await _apiClient.getSession(widget.userId, widget.sessionId);
      final messages = session.events.expand<ChatMessage>((event) {
        final text = event.content.parts
            .where((part) => part.text != null)
            .map((part) => part.text!)
            .join('\n');

        if (text.isNotEmpty) {
          if (event.author == 'user') {
            return [ChatMessage.user(text, [])];
          } else {
            // LLMメッセージの場合
            final llmMessage = ChatMessage.llm();
            llmMessage.append(text);
            return [llmMessage];
          }
        }
        return <ChatMessage>[];
      }).toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'メッセージ履歴の読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSendMessage(String text) async {
    print('送信: $text');
    
    // ユーザーメッセージを即座に追加
    setState(() {
      _messages.add(ChatMessage.user(text, []));
    });

    try {
      final replies = await _apiClient.postMessage(
        userId: widget.userId,
        sessionId: widget.sessionId,
        prompt: text,
        attachments: [],
      );
      
      // AI応答を追加
      final llmMessage = ChatMessage.llm();
      for (final reply in replies) {
        llmMessage.append(reply);
      }
      
      setState(() {
        _messages.add(llmMessage);
      });
    } catch (e) {
      // エラーメッセージを追加
      setState(() {
        _messages.add(ChatMessage.llm()..append('エラー: $e'));
      });
    }
  }

  void _handleAttachmentPressed() {
    print('添付ボタンが押されました');
    // TODO: ここで添付機能を実装
  }

  Widget _buildMessageItem(ChatMessage message, int index) {
    // ChatMessageがuserメッセージかどうかを判定
    // 作成時にどちらのコンストラクタが使われたかでruntimeTypeが異なることを利用
    final isUser = message.runtimeType.toString().contains('User') || 
                   message.toString().contains('user');
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // アバター
          CircleAvatar(
            backgroundColor: isUser ? Colors.blue : Colors.green,
            child: Icon(
              isUser ? Icons.person : Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // メッセージ内容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 送信者名
                Text(
                  isUser ? 'あなた' : 'AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUser ? Colors.blue : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                // メッセージテキスト
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUser ? Colors.blue[200]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    message.text ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 背景のPageView
          PageView.builder(
            itemCount: 3,
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
          // DraggableScrollableSheet
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 80 + keyboardHeight,
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
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessage != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: Colors.red[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red[600],
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadMessageHistory,
                                          child: const Text('再試行'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _messages.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'メッセージがありません\n下のテキストボックスからメッセージを送信してください',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        itemCount: _messages.length,
                                        itemBuilder: (context, index) {
                                          return _buildMessageItem(_messages[index], index);
                                        },
                                      ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // チャット入力部分
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: ChatInputWidget(
              onSendMessage: _handleSendMessage,
              onAttachmentPressed: _handleAttachmentPressed,
            ),
          ),
        ],
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
} 