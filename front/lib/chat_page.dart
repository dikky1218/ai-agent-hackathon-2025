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
                      messages: chatProvider.userMessages.reversed.toList(),
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
                      isSending: chatProvider.isSending,
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