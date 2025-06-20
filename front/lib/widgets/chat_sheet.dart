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