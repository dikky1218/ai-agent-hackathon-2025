import 'package:flutter/material.dart';
import 'chat_page.dart';

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
      } else {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Tab View'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.list), text: 'Side Content'),
                  Tab(icon: Icon(Icons.chat), text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                Container(
                  color: Colors.blueGrey[100],
                  child: const Center(
                    child: Text('Side Content'),
                  ),
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