import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'session_list_widget.dart';

class SplitPage extends StatefulWidget {
  const SplitPage({super.key, required this.userId});
  final String userId;

  @override
  State<SplitPage> createState() => _SplitPageState();
}

class _SplitPageState extends State<SplitPage>
    with SingleTickerProviderStateMixin {
  String? _selectedSessionId;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onSessionSelected(String sessionId) {
    setState(() {
      _selectedSessionId = sessionId;
    });
    if (_tabController != null) {
      _tabController!.animateTo(1);
    }
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
            title: const Text('Tab View'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.list), text: 'Sessions'),
                Tab(icon: Icon(Icons.chat), text: 'Chat'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              sessionList,
              chatPage,
            ],
          ),
        );
      }
    });
  }
} 