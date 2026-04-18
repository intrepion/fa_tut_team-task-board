# Code

### 1. Red: Load The Board For The Current Principal

Create the first code test file:

```bash
mkdir -p workspace/test/code
touch workspace/test/code/team_task_board_controller_test.dart
just format
git add --all
git commit --message 'touch workspace/test/code/team_task_board_controller_test.dart'
```

Put this exact content in `workspace/test/code/team_task_board_controller_test.dart`:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:team_task_board/code/team_task_board_controller.dart';
import 'package:team_task_board/contracts/team_task.dart';
import 'package:team_task_board/contracts/team_task_api.dart';
import 'package:team_task_board/contracts/team_task_list_response.dart';
import 'package:test/test.dart';

class MockTeamTaskApi extends Mock implements TeamTaskApi {}

void main() {
  test('loads the board for the current principal', () async {
    final api = MockTeamTaskApi();
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
            visibility: 'private',
          ),
        ],
      ),
    );

    final result = await loadBoard(
      principal: 'user',
      actingUserId: 'user-alice',
      api: api,
    );

    expect(result.tasks.map((task) => task.text).toList(), [
      'Draft release notes',
      'Prepare hiring packet',
    ]);
    expect(result.errorMessage, isNull);
  });
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "1. Red: Load The Board For The Current Principal"
```

### 2. Green: Load The Board And Handle Common Errors

Create the first production file:

```bash
mkdir -p workspace/lib/code
touch workspace/lib/code/team_task_board_controller.dart
just format
git add --all
git commit --message 'touch workspace/lib/code/team_task_board_controller.dart'
```

Put this exact content in `workspace/lib/code/team_task_board_controller.dart`:

```dart
import '../contracts/team_task.dart';
import '../contracts/team_task_api.dart';
import '../contracts/team_task_list_response.dart';

class TeamTaskBoardViewModel {
  final List<TeamTask> tasks;
  final String principal;
  final String actingUserId;
  final String? errorMessage;

  const TeamTaskBoardViewModel({
    required this.tasks,
    required this.principal,
    required this.actingUserId,
    this.errorMessage,
  });

  factory TeamTaskBoardViewModel.fromResponse({
    required TeamTaskListResponse response,
    required String principal,
    required String actingUserId,
  }) {
    return TeamTaskBoardViewModel(
      tasks: response.tasks,
      principal: principal,
      actingUserId: actingUserId,
    );
  }
}

String? normalizedUserId(String principal, String actingUserId) {
  final trimmed = actingUserId.trim();
  if (principal == 'anonymous' || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Future<TeamTaskBoardViewModel> loadBoard({
  required String principal,
  required String actingUserId,
  required TeamTaskApi api,
}) async {
  try {
    final response = await api.getTasks(
      principal: principal,
      userId: normalizedUserId(principal, actingUserId),
    );
    return TeamTaskBoardViewModel.fromResponse(
      response: response,
      principal: principal,
      actingUserId: actingUserId,
    );
  } catch (_) {
    return TeamTaskBoardViewModel(
      tasks: const [],
      principal: principal,
      actingUserId: actingUserId,
      errorMessage: 'Sorry, the team task API is unavailable right now.',
    );
  }
}

Future<TeamTaskBoardViewModel> addTeamTask({
  required String principal,
  required String actingUserId,
  required String ownerUserId,
  required String text,
  required String visibility,
  required TeamTaskApi api,
}) async {
  final trimmedText = text.trim();
  if (trimmedText.isEmpty) {
    return TeamTaskBoardViewModel(
      tasks: const [],
      principal: principal,
      actingUserId: actingUserId,
      errorMessage: 'Task must not be blank.',
    );
  }

  try {
    await api.createTask(
      ownerUserId: ownerUserId.trim(),
      text: trimmedText,
      visibility: visibility,
    );
    return loadBoard(
      principal: principal,
      actingUserId: actingUserId,
      api: api,
    );
  } catch (_) {
    return TeamTaskBoardViewModel(
      tasks: const [],
      principal: principal,
      actingUserId: actingUserId,
      errorMessage: 'Sorry, the team task API is unavailable right now.',
    );
  }
}

Future<TeamTaskBoardViewModel> deleteTeamTask({
  required String principal,
  required String actingUserId,
  required String taskId,
  required TeamTaskApi api,
}) async {
  try {
    await api.deleteTask(
      taskId,
      principal: principal,
      userId: normalizedUserId(principal, actingUserId),
    );
    return loadBoard(
      principal: principal,
      actingUserId: actingUserId,
      api: api,
    );
  } catch (_) {
    return TeamTaskBoardViewModel(
      tasks: const [],
      principal: principal,
      actingUserId: actingUserId,
      errorMessage: 'Sorry, the team task API is unavailable right now.',
    );
  }
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "2. Green: Load The Board And Handle Common Errors"
```

### 3. Red: Reject Blank Task Text Before Calling The API

Replace `workspace/test/code/team_task_board_controller_test.dart` with:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:team_task_board/code/team_task_board_controller.dart';
import 'package:team_task_board/contracts/team_task.dart';
import 'package:team_task_board/contracts/team_task_api.dart';
import 'package:team_task_board/contracts/team_task_list_response.dart';
import 'package:test/test.dart';

class MockTeamTaskApi extends Mock implements TeamTaskApi {}

void main() {
  test('loads the board for the current principal', () async {
    final api = MockTeamTaskApi();
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
            visibility: 'private',
          ),
        ],
      ),
    );

    final result = await loadBoard(
      principal: 'user',
      actingUserId: 'user-alice',
      api: api,
    );

    expect(result.tasks.map((task) => task.text).toList(), [
      'Draft release notes',
      'Prepare hiring packet',
    ]);
    expect(result.errorMessage, isNull);
  });

  test('rejects blank task text before calling the API', () async {
    final api = MockTeamTaskApi();

    final result = await addTeamTask(
      principal: 'user',
      actingUserId: 'user-alice',
      ownerUserId: 'user-alice',
      text: '   ',
      visibility: 'public',
      api: api,
    );

    expect(result.errorMessage, 'Task must not be blank.');
    verifyNever(
      () => api.createTask(
        ownerUserId: any(named: 'ownerUserId'),
        text: any(named: 'text'),
        visibility: any(named: 'visibility'),
      ),
    );
  });
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "3. Red: Reject Blank Task Text Before Calling The API"
```

### 4. Green: Reload After Create And Delete

Replace `workspace/test/code/team_task_board_controller_test.dart` with:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:team_task_board/code/team_task_board_controller.dart';
import 'package:team_task_board/contracts/team_task.dart';
import 'package:team_task_board/contracts/team_task_api.dart';
import 'package:team_task_board/contracts/team_task_list_response.dart';
import 'package:test/test.dart';

class MockTeamTaskApi extends Mock implements TeamTaskApi {}

void main() {
  test('loads the board for the current principal', () async {
    final api = MockTeamTaskApi();
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
            visibility: 'private',
          ),
        ],
      ),
    );

    final result = await loadBoard(
      principal: 'user',
      actingUserId: 'user-alice',
      api: api,
    );

    expect(result.tasks.map((task) => task.text).toList(), [
      'Draft release notes',
      'Prepare hiring packet',
    ]);
    expect(result.errorMessage, isNull);
  });

  test('rejects blank task text before calling the API', () async {
    final api = MockTeamTaskApi();

    final result = await addTeamTask(
      principal: 'user',
      actingUserId: 'user-alice',
      ownerUserId: 'user-alice',
      text: '   ',
      visibility: 'public',
      api: api,
    );

    expect(result.errorMessage, 'Task must not be blank.');
    verifyNever(
      () => api.createTask(
        ownerUserId: any(named: 'ownerUserId'),
        text: any(named: 'text'),
        visibility: any(named: 'visibility'),
      ),
    );
  });

  test('reloads the board after creating a task', () async {
    final api = MockTeamTaskApi();
    when(
      () => api.createTask(
        ownerUserId: 'user-alice',
        text: 'Draft release notes',
        visibility: 'public',
      ),
    ).thenAnswer(
      (_) async => const TeamTask(
        id: 'task-1',
        ownerUserId: 'user-alice',
        text: 'Draft release notes',
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
        ],
      ),
    );

    final result = await addTeamTask(
      principal: 'user',
      actingUserId: 'user-alice',
      ownerUserId: 'user-alice',
      text: 'Draft release notes',
      visibility: 'public',
      api: api,
    );

    expect(result.tasks.single.text, 'Draft release notes');
    expect(result.errorMessage, isNull);
  });

  test('reloads the board after deleting a task', () async {
    final api = MockTeamTaskApi();
    when(
      () => api.deleteTask(
        'task-1',
        principal: 'admin',
        userId: 'user-admin',
      ),
    ).thenAnswer((_) async {});
    when(
      () => api.getTasks(principal: 'admin', userId: 'user-admin'),
    ).thenAnswer((_) async => const TeamTaskListResponse(tasks: []));

    final result = await deleteTeamTask(
      principal: 'admin',
      actingUserId: 'user-admin',
      taskId: 'task-1',
      api: api,
    );

    expect(result.tasks, isEmpty);
    expect(result.errorMessage, isNull);
  });
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "4. Green: Reload After Create And Delete"
```
