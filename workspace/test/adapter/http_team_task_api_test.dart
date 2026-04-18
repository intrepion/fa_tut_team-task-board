import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:team_task_board/adapter/http_team_task_api.dart';
import 'package:test/test.dart';

void main() {
  test('loads the current board with principal headers', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        '{"tasks":[{"id":"task-1","owner_user_id":"user-alice","text":"Draft release notes","visibility":"public"}]}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = HttpTeamTaskApi(
      baseUrl: 'http://localhost:25664',
      client: client,
    );
    final result = await api.getTasks(principal: 'user', userId: 'user-alice');

    expect(capturedRequest.url.toString(), 'http://localhost:25664/api/tasks');
    expect(capturedRequest.headers['X-Team-Task-Principal'], 'user');
    expect(capturedRequest.headers['X-Team-Task-User-ID'], 'user-alice');
    expect(result.tasks.single.visibility, 'public');
  });

  test('posts a new team task resource', () async {
    late String requestBody;
    final client = MockClient((request) async {
      requestBody = request.body;
      return http.Response(
        '{"id":"task-2","owner_user_id":"user-alice","text":"Prepare hiring packet","visibility":"private"}',
        201,
        headers: {'content-type': 'application/json'},
      );
    });

    final api = HttpTeamTaskApi(
      baseUrl: 'http://localhost:25664',
      client: client,
    );
    final createdTask = await api.createTask(
      ownerUserId: 'user-alice',
      text: 'Prepare hiring packet',
      visibility: 'private',
    );

    expect(
      requestBody,
      '{"owner_user_id":"user-alice","text":"Prepare hiring packet","visibility":"private"}',
    );
    expect(createdTask.ownerUserId, 'user-alice');
    expect(createdTask.visibility, 'private');
  });

  test('deletes a task with principal headers', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response('', 204);
    });

    final api = HttpTeamTaskApi(
      baseUrl: 'http://localhost:25664',
      client: client,
    );
    await api.deleteTask('task-2', principal: 'admin', userId: 'user-admin');

    expect(
      capturedRequest.url.toString(),
      'http://localhost:25664/api/tasks/task-2',
    );
    expect(capturedRequest.headers['X-Team-Task-Principal'], 'admin');
    expect(capturedRequest.headers['X-Team-Task-User-ID'], 'user-admin');
  });
}
