import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'session_list_widget.dart';
import 'api_client.dart';

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
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '今日は何を学びますか？📓🖊️',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: () async {
                    final ApiClient apiClient = ApiClient();
                    final newSession = await apiClient.createSession(widget.userId);
                    setState(() {
                      _selectedSessionId = newSession.id;
                    });
                  },
                  child: const Text('はじめる'),
                ),
              ],
            ),
          )
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
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            title: const Text(
              'プレゼン駆動-勉強アプリ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          drawer: Drawer(
            child: Column(
              children: [
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '今までの学び',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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