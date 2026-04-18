import 'dart:convert';

import 'package:http/http.dart' as http;

import '../contracts/team_task.dart';
import '../contracts/team_task_api.dart';
import '../contracts/team_task_list_response.dart';

class HttpTeamTaskApi implements TeamTaskApi {
  final String baseUrl;
  final http.Client client;

  HttpTeamTaskApi({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  Map<String, String> _principalHeaders(String principal, String? userId) {
    final headers = <String, String>{'X-Team-Task-Principal': principal};
    if (userId != null && userId.isNotEmpty) {
      headers['X-Team-Task-User-ID'] = userId;
    }
    return headers;
  }

  @override
  Future<TeamTaskListResponse> getTasks({
    required String principal,
    String? userId,
  }) async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/tasks'),
      headers: _principalHeaders(principal, userId),
    );
    if (response.statusCode != 200) {
      throw Exception('failed to load team tasks');
    }
    return TeamTaskListResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<TeamTask> createTask({
    required String ownerUserId,
    required String text,
    required String visibility,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/api/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner_user_id': ownerUserId,
        'text': text,
        'visibility': visibility,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('failed to create team task');
    }
    return TeamTask.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTask(
    String taskId, {
    required String principal,
    String? userId,
  }) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/api/tasks/$taskId'),
      headers: _principalHeaders(principal, userId),
    );
    if (response.statusCode != 204) {
      throw Exception('failed to delete team task');
    }
  }
}
