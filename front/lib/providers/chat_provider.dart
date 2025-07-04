import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:image_picker/image_picker.dart';
import '../api_client.dart';

class ChatProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<ChatMessage> _userMessages = [];
  List<ChatMessage> _aiMessages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;
  XFile? _selectedImage;

  List<ChatMessage> get userMessages => _userMessages;
  List<ChatMessage> get aiMessages => _aiMessages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
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

      _userMessages = messages.where((msg) => msg.origin == MessageOrigin.user).toList();
      _aiMessages = messages.where((msg) => msg.origin == MessageOrigin.llm).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'メッセージ履歴の読み込みに失敗しました: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String userId, String sessionId, String text) async {
    _isSending = true;
    notifyListeners();

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
    final userMessage = ChatMessage.user(text, attachments);
    _userMessages.add(userMessage);
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
      
      _aiMessages.add(llmMessage);
      notifyListeners();
    } catch (e) {
      _aiMessages.add(ChatMessage.llm()..append('エラー: $e'));
      notifyListeners();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}