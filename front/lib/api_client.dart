import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';

const host = String.fromEnvironment('BACKEND_HOST', defaultValue: 'http://10.0.2.2:8000');

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
    final partsList = json['parts'] as List<dynamic>? ?? [];
    final parts = partsList
        .where((partJson) => partJson != null)
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
      actions: json['actions'] as Map<String, dynamic>? ?? {},
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
    final eventsData = json['events'] as List<dynamic>? ?? [];
    final events = eventsData
        .where((eventJson) =>
            eventJson != null &&
            (eventJson as Map<String, dynamic>)['content'] != null)
        .map((eventJson) => Event.fromJson(eventJson as Map<String, dynamic>))
        .toList();
    return Session(
      appName: json['appName'] as String,
      events: events,
      id: json['id'] as String,
      lastUpdateTime: (json['lastUpdateTime'] as num).toDouble(),
      state: json['state'] as Map<String, dynamic>? ?? {},
      userId: json['userId'] as String,
    );
  }
}

class ApiClient {
  Future<List<String>> postMessage({
    required String userId,
    required String sessionId,
    required String prompt,
    Iterable<Attachment> attachments = const [],
  }) async {
    final parts = <Map<String, dynamic>>[];
    if (prompt.isNotEmpty) {
      parts.add({'text': prompt});
    }

    for (final attachment in attachments) {
      if (attachment is FileAttachment) {
        parts.add({
          'inlineData': {
            'data': base64Encode(attachment.bytes),
            'mimeType': attachment.mimeType,
          }
        });
      }
    }
    final body = {
      "app_name": "learning_agent",
      "user_id": userId,
      "session_id": sessionId,
      "new_message": {
        "role": "user",
        "parts": parts,
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
      print('decodedBody: $decodedBody');
      if (decodedBody.isNotEmpty) {
        final List<String> texts = [];
        for (final message in decodedBody) {
          final messageMap = message as Map<String, dynamic>;
          if (messageMap.containsKey('content') &&
              messageMap['content'] != null) {
            final content = messageMap['content'] as Map<String, dynamic>;
            if (content.containsKey('parts') && content['parts'] != null) {
              final parts = content['parts'] as List;
              for (final part in parts) {
                if (part != null) {
                  final partMap = part as Map<String, dynamic>;
                  if (partMap.containsKey('text') && partMap['text'] != null) {
                    texts.add(partMap['text'] as String);
                  }
                }
              }
            }
          }
        }

        if (texts.isNotEmpty) {
          return texts;
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

  Future<Session> createSession(String userId) async {
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
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return Session.fromJson(responseBody);
    } else {
      throw Exception('Failed to create session: ${response.statusCode}');
    }
  }
}
