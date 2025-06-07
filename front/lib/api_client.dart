import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _backendHost =
    String.fromEnvironment('BACKEND_HOST', defaultValue: '10.0.2.2:8000');

const host = 'http://$_backendHost';

class FunctionResponse {
  final String id;
  final String name;
  final Map<String, dynamic> response;

  FunctionResponse(
      {required this.id, required this.name, required this.response});

  factory FunctionResponse.fromJson(Map<String, dynamic> json) {
    return FunctionResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      response: json['response'] as Map<String, dynamic>,
    );
  }
}

class FunctionCall {
  final String id;
  final Map<String, dynamic> args;
  final String name;

  FunctionCall({required this.id, required this.args, required this.name});

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      id: json['id'] as String,
      args: json['args'] as Map<String, dynamic>,
      name: json['name'] as String,
    );
  }
}

class Part {
  final String? text;
  final FunctionCall? functionCall;
  final FunctionResponse? functionResponse;

  Part({this.text, this.functionCall, this.functionResponse});

  factory Part.fromJson(Map<String, dynamic> json) {
    return Part(
      text: json['text'] as String?,
      functionCall: json.containsKey('functionCall')
          ? FunctionCall.fromJson(json['functionCall'] as Map<String, dynamic>)
          : null,
      functionResponse: json.containsKey('functionResponse')
          ? FunctionResponse.fromJson(
              json['functionResponse'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Content {
  final List<Part> parts;
  final String role;

  Content({required this.parts, required this.role});

  factory Content.fromJson(Map<String, dynamic> json) {
    final partsList = json['parts'] as List;
    final parts = partsList
        .map((partJson) => Part.fromJson(partJson as Map<String, dynamic>))
        .toList();
    return Content(
      parts: parts,
      role: json['role'] as String,
    );
  }
}

class Event {
  final Content content;
  final String? invocationId;
  final String author;
  final Map<String, dynamic> actions;
  final String id;
  final double timestamp;
  final Map<String, dynamic>? usageMetadata;
  final List<dynamic>? longRunningToolIds;

  Event({
    required this.content,
    this.invocationId,
    required this.author,
    required this.actions,
    required this.id,
    required this.timestamp,
    this.usageMetadata,
    this.longRunningToolIds,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      content: Content.fromJson(json['content'] as Map<String, dynamic>),
      invocationId: json['invocationId'] as String?,
      author: json['author'] as String,
      actions: json['actions'] as Map<String, dynamic>,
      id: json['id'] as String,
      timestamp: (json['timestamp'] as num).toDouble(),
      usageMetadata: json['usageMetadata'] as Map<String, dynamic>?,
      longRunningToolIds: json['longRunningToolIds'] as List<dynamic>?,
    );
  }
}

class Session {
  final String appName;
  final List<Event> events;
  final String id;
  final double lastUpdateTime;
  final Map<String, dynamic> state;
  final String userId;

  Session({
    required this.appName,
    required this.events,
    required this.id,
    required this.lastUpdateTime,
    required this.state,
    required this.userId,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    final eventsData = json['events'] as List<dynamic>;
    final events = eventsData
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
    return Session(
      appName: json['appName'] as String,
      events: events,
      id: json['id'] as String,
      lastUpdateTime: (json['lastUpdateTime'] as num).toDouble(),
      state: json['state'] as Map<String, dynamic>,
      userId: json['userId'] as String,
    );
  }
}

class ApiClient {
  Future<String> postMessage({
    required String userId,
    required String sessionId,
    required String prompt,
  }) async {
    final body = {
      "app_name": "learning_agent",
      "user_id": userId,
      "session_id": sessionId,
      "new_message": {
        "role": "user",
        "parts": [
          {"text": prompt}
        ]
      },
      "streaming": false
    };

    final res = await http.post(
      Uri.parse('$host/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final decodedBody = jsonDecode(res.body) as List;
      if (decodedBody.isNotEmpty) {
        final lastMessage = decodedBody.last as Map<String, dynamic>;
        final parts =
            (lastMessage['content'] as Map<String, dynamic>)['parts'] as List;
        if (parts.isNotEmpty) {
          final part = parts.first as Map<String, dynamic>;
          if (part.containsKey('text')) {
            return part['text'] as String;
          }
        }
      }
      throw Exception('Invalid response format');
    } else {
      throw Exception('Backend error ${res.statusCode}');
    }
  }

  Future<List<Session>> getSessions(String userId) async {
    final res = await http.get(
      Uri.parse('$host/apps/learning_agent/users/$userId/sessions'),
    );

    if (res.statusCode == 200) {
      final decodedBody = jsonDecode(res.body) as List;
      return decodedBody
          .map((sessionJson) =>
              Session.fromJson(sessionJson as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get sessions: ${res.statusCode}');
    }
  }

  Future<Session> getSession(String userId, String sessionId) async {
    final res = await http.get(
      Uri.parse('$host/apps/learning_agent/users/$userId/sessions/$sessionId'),
    );

    if (res.statusCode == 200) {
      final decodedBody = jsonDecode(res.body) as Map<String, dynamic>;
      return Session.fromJson(decodedBody);
    } else {
      throw Exception('Failed to get session: ${res.statusCode}');
    }
  }

  Future<String> createSession(String userId) async {
    final response = await http.post(
      Uri.parse('$host/apps/learning_agent/users/$userId/sessions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'appName': 'learning_agent',
        'events': [],
        'lastUpdateTime': DateTime.now().millisecondsSinceEpoch / 1000,
        'state': {},
        'userId': userId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final sessionId = jsonDecode(response.body)['id'];
      if (sessionId == null) {
        throw Exception('セッションIDの作成に失敗しました。');
      }
      return sessionId;
    } else {
      throw Exception('Failed to create session: ${response.statusCode}');
    }
  }
}

Future<String> initializeSession(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  var sessionId = prefs.getString('sessionId');
  if (sessionId == null) {
    print('sessionId is null, creating new session');
    try {
      final apiClient = ApiClient();
      sessionId = await apiClient.createSession(userId);
      await prefs.setString('sessionId', sessionId);
    } catch (e) {
      throw Exception('セッションIDの作成または取得に失敗しました。');
    }
  } else {
    print('sessionId is not null, using existing session');
  }

  if (sessionId == null) {
    throw Exception('セッションIDの作成または取得に失敗しました。');
  }
  return sessionId;
} 