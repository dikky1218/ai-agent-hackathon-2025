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
    return sessions;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Session>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No sessions found.'));
        } else {
          final sessions = snapshot.data!;
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return ListTile(
                title: Text(session.id),
                onTap: () => widget.onSessionSelected(session.id),
              );
            },
          );
        }
      },
    );
  }
} 