import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onAttachmentPressed,
    this.hintText = 'メッセージを入力...',
    this.selectedImage,
    this.onClearAttachment,
    this.onStartRecording,
    this.onStopRecording,
    this.isRecording = false,
    this.text,
  });

  final Function(String) onSendMessage;
  final VoidCallback? onAttachmentPressed;
  final String hintText;
  final XFile? selectedImage;
  final VoidCallback? onClearAttachment;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final bool isRecording;
  final String? text;

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  late TextEditingController _controller;
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isComposing = _controller.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text && widget.text != null) {
      final oldSelection = _controller.selection;
      _controller.text = widget.text!;
      // カーソルを末尾に移動
      _controller.selection =
          TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || widget.selectedImage != null) {
      // テキストが空で画像がある場合は、プレースホルダーテキストを送信
      final messageToSend =
          text.isEmpty && widget.selectedImage != null ? '[画像]' : text;
      widget.onSendMessage(messageToSend);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8.0,
        8.0,
        8.0,
        8.0 + MediaQuery.of(context).viewPadding.bottom,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.selectedImage != null) _buildThumbnail(),
            Row(
              children: [
                // 添付ボタン
                IconButton(
                  onPressed: widget.onAttachmentPressed ??
                      () {
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
                      controller: _controller,
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // マイク or 送信ボタン
                if (_isComposing || widget.selectedImage != null)
                  // 送信ボタン
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  )
                else
                  // マイクボタン
                  IconButton(
                    onPressed: widget.isRecording
                        ? widget.onStopRecording
                        : widget.onStartRecording,
                    icon: Icon(
                      widget.isRecording ? Icons.stop : Icons.mic,
                      color: widget.isRecording ? Colors.red : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file(
              File(widget.selectedImage!.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(Icons.cancel, color: Colors.black54),
              onPressed: widget.onClearAttachment,
            ),
          ),
        ],
      ),
    );
  }
} 