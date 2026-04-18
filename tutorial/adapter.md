# Adapter

### 1. Red: Add The HTTP Team Task API Test

Create the HTTP adapter test file:

```bash
mkdir -p workspace/test/adapter
touch workspace/test/adapter/http_team_task_api_test.dart
just format
git add --all
git commit --message 'touch workspace/test/adapter/http_team_task_api_test.dart'
```

Put this exact content in `workspace/test/adapter/http_team_task_api_test.dart`:

```dart
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
    final result = await api.getTasks(
      principal: 'user',
      userId: 'user-alice',
    );

    expect(
      capturedRequest.url.toString(),
      'http://localhost:25664/api/tasks',
    );
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
    await api.deleteTask(
      'task-2',
      principal: 'admin',
      userId: 'user-admin',
    );

    expect(
      capturedRequest.url.toString(),
      'http://localhost:25664/api/tasks/task-2',
    );
    expect(capturedRequest.headers['X-Team-Task-Principal'], 'admin');
    expect(capturedRequest.headers['X-Team-Task-User-ID'], 'user-admin');
  });
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "1. Red: Add The HTTP Team Task API Test"
```

### 2. Green: Call The Canonical Team Task API Endpoints

Create the HTTP adapter production file:

```bash
mkdir -p workspace/lib/adapter
touch workspace/lib/adapter/http_team_task_api.dart
just format
git add --all
git commit --message 'touch workspace/lib/adapter/http_team_task_api.dart'
```

Put this exact content in `workspace/lib/adapter/http_team_task_api.dart`:

```dart
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
    final headers = <String, String>{
      'X-Team-Task-Principal': principal,
    };
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
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "2. Green: Call The Canonical Team Task API Endpoints"
```

### 3. Red: Add The Team Task Board Page Widget Test

Create the widget test file:

```bash
mkdir -p workspace/test/adapter
touch workspace/test/adapter/team_task_board_page_test.dart
just format
git add --all
git commit --message 'touch workspace/test/adapter/team_task_board_page_test.dart'
```

Put this exact content in `workspace/test/adapter/team_task_board_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_task_board/adapter/team_task_board_page.dart';
import 'package:team_task_board/contracts/team_task.dart';
import 'package:team_task_board/contracts/team_task_api.dart';
import 'package:team_task_board/contracts/team_task_list_response.dart';

class MockTeamTaskApi extends Mock implements TeamTaskApi {}

void main() {
  testWidgets('loads, adds, and deletes board tasks across principals', (
    tester,
  ) async {
    final api = MockTeamTaskApi();

    when(
      () => api.getTasks(principal: 'anonymous', userId: null),
    ).thenAnswer(
      (_) async => const TeamTaskListResponse(
        tasks: [
          TeamTask(
            id: 'task-1',
            ownerUserId: 'user-alice',
            text: 'Draft release notes',
            visibility: 'public',
          ),
        ],
      ),
    );
    when(
      () => api.createTask(
        ownerUserId: 'user-alice',
        text: 'Prepare hiring packet',
        visibility: 'public',
      ),
    ).thenAnswer(
      (_) async => const TeamTask(
        id: 'task-2',
        ownerUserId: 'user-alice',
        text: 'Prepare hiring packet',
        visibility: 'public',
      ),
    );
    when(
      () => api.getTasks(principal: 'user', userId: 'user-alice'),
    ).thenAnswer(
      (_) async => const TeamTaskListResponse(
        tasks: [
          TeamTask(
            id: 'task-1',
            ownerUserId: 'user-alice',
            text: 'Draft release notes',
            visibility: 'public',
          ),
          TeamTask(
            id: 'task-2',
            ownerUserId: 'user-alice',
            text: 'Prepare hiring packet',
            visibility: 'public',
          ),
        ],
      ),
    );
    when(
      () => api.getTasks(principal: 'admin', userId: 'user-admin'),
    ).thenAnswer(
      (_) async => const TeamTaskListResponse(
        tasks: [
          TeamTask(
            id: 'task-1',
            ownerUserId: 'user-alice',
            text: 'Draft release notes',
            visibility: 'public',
          ),
          TeamTask(
            id: 'task-2',
            ownerUserId: 'user-alice',
            text: 'Prepare hiring packet',
            visibility: 'public',
          ),
        ],
      ),
    );
    when(
      () => api.deleteTask(
        'task-2',
        principal: 'admin',
        userId: 'user-admin',
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: TeamTaskBoardPage(api: api),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Draft release notes'), findsOneWidget);

    await tester.tap(find.byKey(const Key('principal-user')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('acting-user-id-input')),
      'user-alice',
    );
    await tester.pump();
    await tester.tap(find.text('Load board'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('owner-user-id-input')),
      'user-alice',
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('task-text-input')),
      'Prepare hiring packet',
    );
    await tester.pump();
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare hiring packet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('principal-admin')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('acting-user-id-input')),
      'user-admin',
    );
    await tester.pump();
    await tester.tap(find.text('Load board'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('remove-task-2')));
    await tester.pumpAndSettle();

    verify(
      () => api.deleteTask(
        'task-2',
        principal: 'admin',
        userId: 'user-admin',
      ),
    ).called(1);
  });
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "3. Red: Add The Team Task Board Page Widget Test"
```

### 4. Green: Build The Team Task Board Page

Create the page production file:

```bash
mkdir -p workspace/lib/adapter
touch workspace/lib/adapter/team_task_board_page.dart
just format
git add --all
git commit --message 'touch workspace/lib/adapter/team_task_board_page.dart'
```

Put this exact content in `workspace/lib/adapter/team_task_board_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../code/team_task_board_controller.dart';
import '../contracts/team_task.dart';
import '../contracts/team_task_api.dart';

class TeamTaskBoardPage extends StatefulWidget {
  final TeamTaskApi api;

  const TeamTaskBoardPage({super.key, required this.api});

  @override
  State<TeamTaskBoardPage> createState() => _TeamTaskBoardPageState();
}

class _TeamTaskBoardPageState extends State<TeamTaskBoardPage> {
  final TextEditingController _actingUserIdController = TextEditingController();
  final TextEditingController _ownerUserIdController = TextEditingController();
  final TextEditingController _taskTextController = TextEditingController();

  String _principal = 'anonymous';
  String _visibility = 'public';
  TeamTaskBoardViewModel _viewModel = const TeamTaskBoardViewModel(
    tasks: [],
    principal: 'anonymous',
    actingUserId: '',
  );

  @override
  void initState() {
    super.initState();
    _refreshBoard();
  }

  @override
  void dispose() {
    _actingUserIdController.dispose();
    _ownerUserIdController.dispose();
    _taskTextController.dispose();
    super.dispose();
  }

  Future<void> _refreshBoard() async {
    final nextViewModel = await loadBoard(
      principal: _principal,
      actingUserId: _actingUserIdController.text,
      api: widget.api,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _viewModel = nextViewModel;
    });
  }

  Future<void> _addTask() async {
    final nextViewModel = await addTeamTask(
      principal: _principal,
      actingUserId: _actingUserIdController.text,
      ownerUserId: _ownerUserIdController.text,
      text: _taskTextController.text,
      visibility: _visibility,
      api: widget.api,
    );
    _taskTextController.clear();
    if (!mounted) {
      return;
    }
    setState(() {
      _viewModel = nextViewModel;
    });
  }

  Future<void> _deleteTask(TeamTask task) async {
    final nextViewModel = await deleteTeamTask(
      principal: _principal,
      actingUserId: _actingUserIdController.text,
      taskId: task.id,
      api: widget.api,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _viewModel = nextViewModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Task Board')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Principal'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  key: const Key('principal-anonymous'),
                  label: const Text('anonymous'),
                  selected: _principal == 'anonymous',
                  onSelected: (_) {
                    setState(() {
                      _principal = 'anonymous';
                    });
                  },
                ),
                ChoiceChip(
                  key: const Key('principal-user'),
                  label: const Text('user'),
                  selected: _principal == 'user',
                  onSelected: (_) {
                    setState(() {
                      _principal = 'user';
                    });
                  },
                ),
                ChoiceChip(
                  key: const Key('principal-admin'),
                  label: const Text('admin'),
                  selected: _principal == 'admin',
                  onSelected: (_) {
                    setState(() {
                      _principal = 'admin';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('acting-user-id-input'),
              controller: _actingUserIdController,
              decoration: const InputDecoration(labelText: 'Acting user id'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _refreshBoard,
              child: const Text('Load board'),
            ),
            const Divider(height: 32),
            TextField(
              key: const Key('owner-user-id-input'),
              controller: _ownerUserIdController,
              decoration: const InputDecoration(labelText: 'Owner user id'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('visibility-input'),
              initialValue: _visibility,
              decoration: const InputDecoration(labelText: 'Visibility'),
              items: const [
                DropdownMenuItem(value: 'public', child: Text('public')),
                DropdownMenuItem(value: 'private', child: Text('private')),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _visibility = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('task-text-input'),
              controller: _taskTextController,
              decoration: const InputDecoration(labelText: 'Task text'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _addTask,
              child: const Text('Add task'),
            ),
            if (_viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_viewModel.errorMessage!),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: _viewModel.tasks
                    .map(
                      (task) => ListTile(
                        title: Text(task.text),
                        subtitle: Text(
                          '${task.ownerUserId} | ${task.visibility}',
                        ),
                        trailing: IconButton(
                          key: Key('remove-${task.id}'),
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "4. Green: Build The Team Task Board Page"
```

### 5. Green: Wire The Real Application

Replace `workspace/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';

import 'adapter/http_team_task_api.dart';
import 'adapter/team_task_board_page.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:25664',
);

void main() {
  runApp(const TeamTaskBoardApp());
}

class TeamTaskBoardApp extends StatelessWidget {
  const TeamTaskBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Task Board',
      home: TeamTaskBoardPage(
        api: HttpTeamTaskApi(baseUrl: apiBaseUrl),
      ),
    );
  }
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "5. Green: Wire The Real Application"
```
