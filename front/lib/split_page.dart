import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'session_list_widget.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key, required this.userId});
  final String userId;

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage> {
  String? _selectedSessionId;

  void _onSessionSelected(String sessionId) {
    setState(() {
      _selectedSessionId = sessionId;
    });
    Navigator.of(context).pop(); // Drawerを閉じる
  }

  @override
  Widget build(BuildContext context) {
    final sessionList = SessionListWidget(
      userId: widget.userId,
      onSessionSelected: _onSessionSelected,
    );

    final chatPage = _selectedSessionId == null
        ? const Center(child: Text('Select a session'))
        : ChatPage(
            userId: widget.userId,
            sessionId: _selectedSessionId!,
          );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Split View'),
          ),
          body: Row(
            children: [
              Expanded(
                child: sessionList,
              ),
              Expanded(
                child: chatPage,
              ),
            ],
          ),
        );
      } else {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat'),
          ),
          drawer: Drawer(
            child: Column(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                  child: Text(
                    'Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                Expanded(
                  child: sessionList,
                ),
              ],
            ),
          ),
          body: chatPage,
        );
      }
    });
  }
} 