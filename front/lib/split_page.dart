import 'package:flutter/material.dart';
import 'package:front/main.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key, required this.userId, required this.sessionId});
  final String userId;
  final String sessionId;

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split View'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.blueGrey[100],
              child: const Center(
                child: Text('Side Content'),
              ),
            ),
          ),
          Expanded(
            child: ChatPage(
              userId: widget.userId,
              sessionId: widget.sessionId,
            ),
          ),
        ],
      ),
    );
  }
} 