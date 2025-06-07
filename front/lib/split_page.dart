import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'session_list_widget.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Split View'),
          ),
          body: Row(
            children: [
              Expanded(
                child: SessionListWidget(
                  userId: widget.userId,
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
      } else {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Tab View'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Sessions'),
                  Tab(icon: Icon(Icons.chat), text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                SessionListWidget(
                  userId: widget.userId,
                ),
                ChatPage(
                  userId: widget.userId,
                  sessionId: widget.sessionId,
                ),
              ],
            ),
          ),
        );
      }
    });
  }
} 