# ChatPage リファクタリング作業手順

## 概要
`chat_page.dart`の複雑な処理を複数のファイルに分割し、保守性とテストしやすさを向上させる。

## 作業手順

### 1. フォルダ構造の準備

```
front/lib/
├── services/
│   ├── speech_service.dart
│   └── image_picker_service.dart
├── providers/
│   └── chat_provider.dart
├── widgets/
│   ├── chat_sheet.dart
│   ├── page_view_section.dart
│   └── chat_messages_list.dart
└── (existing files...)
```

### 2. 音声認識サービスの分離

**ファイル**: `lib/services/speech_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastWords = '';

  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<void> initialize() async {
    _speechEnabled = await _speechToText.initialize();
    notifyListeners();
  }

  Future<void> startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    _isListening = true;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    notifyListeners();
  }

  void clearLastWords() {
    _lastWords = '';
    notifyListeners();
  }

  void _onSpeechResult(result) {
    _lastWords = result.recognizedWords;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}
```

### 3. 画像選択サービスの分離

**ファイル**: `lib/services/image_picker_service.dart`

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  static Future<XFile?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(
      source: source,
      imageQuality: 50,
    );
  }

  static void showImageSourcePicker(
    BuildContext context,
    Function(ImageSource) onSourceSelected,
  ) {
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
                  onSourceSelected(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.of(context).pop();
                  onSourceSelected(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 4. チャット状態管理の分離

**ファイル**: `lib/providers/chat_provider.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:image_picker/image_picker.dart';
import '../api_client.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  XFile? _selectedImage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  XFile? get selectedImage => _selectedImage;

  void setSelectedImage(XFile? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  Future<void> loadMessageHistory(String userId, String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _apiClient.getSession(userId, sessionId);
      final messages = session.events.expand<ChatMessage>((event) {
        final text = event.content.parts
            .where((part) => part.text != null)
            .map((part) => part.text!)
            .join('\n');

        if (text.isNotEmpty) {
          if (event.author == 'user') {
            return [ChatMessage.user(text, [])];
          } else {
            final llmMessage = ChatMessage.llm();
            llmMessage.append(text);
            return [llmMessage];
          }
        }
        return <ChatMessage>[];
      }).toList();

      _messages = messages;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'メッセージ履歴の読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String userId, String sessionId, String text) async {
    final List<Attachment> attachments;
    if (_selectedImage != null) {
      final imageBytes = await _selectedImage!.readAsBytes();
      attachments = [
        FileAttachment(
          name: _selectedImage!.name,
          bytes: imageBytes,
          mimeType: 'image/jpeg',
        )
      ];
    } else {
      attachments = [];
    }

    // ユーザーメッセージを即座に追加
    _messages.add(ChatMessage.user(text, attachments));
    _selectedImage = null;
    notifyListeners();

    try {
      final promptText = text == '[画像]' ? '' : text;
      final replies = await _apiClient.postMessage(
        userId: userId,
        sessionId: sessionId,
        prompt: promptText,
        attachments: attachments,
      );
      
      final llmMessage = ChatMessage.llm();
      for (final reply in replies) {
        llmMessage.append(reply);
      }
      
      _messages.add(llmMessage);
      notifyListeners();
    } catch (e) {
      _messages.add(ChatMessage.llm()..append('エラー: $e'));
      notifyListeners();
    }
  }
}
```

### 5. ページビューセクションの分離

**ファイル**: `lib/widgets/page_view_section.dart`

```dart
import 'package:flutter/material.dart';

class PageViewSection extends StatelessWidget {
  final double height;

  const PageViewSection({
    super.key,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: PageView.builder(
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
    );
  }

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
```

### 6. チャットメッセージリストの分離

**ファイル**: `lib/widgets/chat_messages_list.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import '../message_item_widget.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final ScrollController scrollController;
  final VoidCallback onRetry;

  const ChatMessagesList({
    super.key,
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.scrollController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
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
              errorMessage!,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Text(
          'メッセージがありません\n下のテキストボックスからメッセージを送信してください',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageItemWidget(
          message: messages[index],
          index: index,
        );
      },
    );
  }
}
```

### 7. チャットシートの分離

**ファイル**: `lib/widgets/chat_sheet.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'chat_messages_list.dart';

class ChatSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const ChatSheet({
    super.key,
    required this.controller,
    required this.messages,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: controller,
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
                child: ChatMessagesList(
                  messages: messages,
                  isLoading: isLoading,
                  errorMessage: errorMessage,
                  scrollController: scrollController,
                  onRetry: onRetry,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 8. メインファイルの更新

**ファイル**: `lib/chat_page.dart` (リファクタ後)

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'chat_input_widget.dart';
import 'providers/chat_provider.dart';
import 'services/speech_service.dart';
import 'services/image_picker_service.dart';
import 'widgets/chat_sheet.dart';
import 'widgets/page_view_section.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollableController = DraggableScrollableController();
  double _sheetSize = 0.4;
  late ChatProvider _chatProvider;
  late SpeechService _speechService;

  @override
  void initState() {
    super.initState();
    _chatProvider = ChatProvider();
    _speechService = SpeechService();
    _speechService.initialize();
    _chatProvider.loadMessageHistory(widget.userId, widget.sessionId);
    
    _scrollableController.addListener(() {
      if (mounted && _scrollableController.isAttached) {
        setState(() {
          _sheetSize = _scrollableController.size;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollableController.dispose();
    _speechService.dispose();
    _chatProvider.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionId != oldWidget.sessionId) {
      _chatProvider.loadMessageHistory(widget.userId, widget.sessionId);
    }
  }

  void _handleSendMessage(String text) {
    _chatProvider.sendMessage(widget.userId, widget.sessionId, text);
    _speechService.clearLastWords();
  }

  void _pickImage(ImageSource source) async {
    final image = await ImagePickerService.pickImage(source);
    if (image != null) {
      _chatProvider.setSelectedImage(image);
    }
  }

  void _showAttachmentPicker() {
    ImagePickerService.showImageSourcePicker(context, _pickImage);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _chatProvider),
        ChangeNotifierProvider.value(value: _speechService),
      ],
      child: Consumer2<ChatProvider, SpeechService>(
        builder: (context, chatProvider, speechService, child) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          const chatInputAreaHeight = 60.0;
          final bottomAreaHeight = keyboardHeight + chatInputAreaHeight;

          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: LayoutBuilder(builder: (context, constraints) {
              final sheetContainerHeight = constraints.maxHeight - bottomAreaHeight;
              final pageViewHeight = (sheetContainerHeight * (1 - _sheetSize)).clamp(0.0, double.infinity);

              return Stack(
                children: [
                  // 背景
                  Container(color: Colors.grey[200]),
                  // PageView
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: pageViewHeight,
                    child: PageViewSection(height: pageViewHeight),
                  ),
                  // チャットシート
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: bottomAreaHeight,
                    child: ChatSheet(
                      controller: _scrollableController,
                      messages: chatProvider.messages,
                      isLoading: chatProvider.isLoading,
                      errorMessage: chatProvider.errorMessage,
                      onRetry: () => chatProvider.loadMessageHistory(widget.userId, widget.sessionId),
                    ),
                  ),
                  // チャット入力
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: keyboardHeight,
                    child: ChatInputWidget(
                      onSendMessage: _handleSendMessage,
                      onAttachmentPressed: _showAttachmentPicker,
                      selectedImage: chatProvider.selectedImage,
                      onClearAttachment: chatProvider.clearSelectedImage,
                      onStartRecording: speechService.startListening,
                      onStopRecording: speechService.stopListening,
                      isRecording: speechService.isListening,
                      text: speechService.lastWords,
                    ),
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}
```

### 9. 依存関係の追加

**ファイル**: `pubspec.yaml`に以下を追加（まだない場合）

```yaml
dependencies:
  provider: ^6.1.1
```

### 10. 動作確認とテスト

1. 各新しいファイルを作成
2. `chat_page.dart`を新しい実装に置き換え
3. アプリケーションをビルドして動作確認
4. 以下の機能が正常に動作することを確認：
   - メッセージ履歴の読み込み
   - メッセージ送信
   - 画像添付
   - 音声認識
   - DraggableScrollableSheetの動作

## 作業の注意点

- 段階的にリファクタリングを行い、各段階で動作確認する
- 既存の動作を変更しないよう注意
- テストコードも合わせて作成することを推奨
- Providerパターンを使用しているため、`provider`パッケージの追加が必要

## 期待される効果

- コードの可読性向上
- テストしやすさの向上
- 機能の再利用性向上
- 保守性の向上
- 責任の分離による設計品質向上 