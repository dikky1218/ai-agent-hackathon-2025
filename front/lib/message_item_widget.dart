import 'package:flutter/material.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

class MessageItemWidget extends StatelessWidget {
  const MessageItemWidget({
    super.key,
    required this.message,
    required this.index,
  });

  final ChatMessage message;
  final int index;

  @override
  Widget build(BuildContext context) {
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
} 