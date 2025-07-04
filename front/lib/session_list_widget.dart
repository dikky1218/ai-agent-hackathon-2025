import 'package:flutter/material.dart';
import 'api_client.dart';

class SessionListWidget extends StatefulWidget {
  final String userId;
  final Function(String) onSessionSelected;

  const SessionListWidget(
      {super.key, required this.userId, required this.onSessionSelected});

  @override
  State<SessionListWidget> createState() => _SessionListWidgetState();
}

class _SessionListWidgetState extends State<SessionListWidget> {
  late Future<List<Session>> _sessionsFuture;
  final ApiClient _apiClient = ApiClient();

  String _formatDateTime(double timestamp) {
    // Unixタイムスタンプ（秒）をDateTimeに変換
    final dateTime = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
    return '${dateTime.month}月${dateTime.day}日${dateTime.hour}時${dateTime.minute}分';
  }

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _fetchAndCreateSessions();
  }

  Future<List<Session>> _fetchAndCreateSessions() async {
    var sessions = await _apiClient.getSessions(widget.userId);
    if (sessions.isEmpty) {
      await _apiClient.createSession(widget.userId);
      sessions = await _apiClient.getSessions(widget.userId);
    }
    sessions.sort((a, b) => b.lastUpdateTime.compareTo(a.lastUpdateTime));
    return sessions;
  }

  Future<void> _createNewSession() async {
    final newSession = await _apiClient.createSession(widget.userId);
    widget.onSessionSelected(newSession.id);
    setState(() {
      _sessionsFuture = _fetchAndCreateSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _createNewSession,
            child: const Text('新しい勉強をはじめる'),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Session>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('セッションがありません。'));
              } else {
                final sessions = snapshot.data!;
                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return ListTile(
                      title: Text(_formatDateTime(session.lastUpdateTime)),
                      onTap: () => widget.onSessionSelected(session.id),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }
} 