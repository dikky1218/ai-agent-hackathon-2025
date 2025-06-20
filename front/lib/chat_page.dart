import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'api_client.dart';
import 'chat_input_widget.dart';
import 'message_item_widget.dart';

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
  XFile? _selectedImage;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _loadMessageHistory();
    _initSpeech();
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
    final List<Attachment> attachments;
    if (_selectedImage != null) {
      final imageBytes = await _selectedImage!.readAsBytes();
      attachments = [
        FileAttachment(
          name: _selectedImage!.name,
          bytes: imageBytes,
          mimeType: 'image/jpeg', // 必要に応じてMIMEタイプを調整
        )
      ];
    } else {
      attachments = [];
    }

    // ユーザーメッセージを即座に追加
    setState(() {
      _messages.add(ChatMessage.user(text, attachments));
      _selectedImage = null; // 送信後に選択をクリア
    });

    try {
      // プレースホルダーテキストはAPIに送信しない
      final promptText = text == '[画像]' ? '' : text;
      final replies = await _apiClient.postMessage(
        userId: widget.userId,
        sessionId: widget.sessionId,
        prompt: promptText,
        attachments: attachments,
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

  void _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    // 画像の品質を50に設定してファイルサイズを削減
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 50,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('ギャラリーから選択'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('カメラで撮影'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          );
        });
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  /// Manually stop the active speech recognition session
  /// Note that there are also timeouts that platform implementations use.
  /// This is a good way to handle user manually stopping the speech recognition.
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
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
                                          return MessageItemWidget(
                                            message: _messages[index],
                                            index: index,
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
          // チャット入力部分
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: ChatInputWidget(
              onSendMessage: (text) {
                _handleSendMessage(text);
                setState(() {
                  _lastWords = '';
                });
              },
              onAttachmentPressed: _showAttachmentPicker,
              selectedImage: _selectedImage,
              onClearAttachment: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              onStartRecording: _startListening,
              onStopRecording: _stopListening,
              isRecording: _isListening,
              text: _lastWords,
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