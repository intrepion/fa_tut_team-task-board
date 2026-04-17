# Contracts

Create the shared contract files:

```bash
mkdir -p workspace/lib/contracts
touch workspace/lib/contracts/team_task.dart
just format
git add --all
git commit --message 'touch workspace/lib/contracts/team_task.dart'
touch workspace/lib/contracts/team_task_list_response.dart
just format
git add --all
git commit --message 'touch workspace/lib/contracts/team_task_list_response.dart'
touch workspace/lib/contracts/team_task_api.dart
just format
git add --all
git commit --message 'touch workspace/lib/contracts/team_task_api.dart'
```

Put this exact content in `workspace/lib/contracts/team_task.dart`:

```dart
class TeamTask {
  final String id;
  final String ownerUserId;
  final String text;
  final String visibility;

  const TeamTask({
    required this.id,
    required this.ownerUserId,
    required this.text,
    required this.visibility,
  });

  factory TeamTask.fromJson(Map<String, dynamic> json) {
    return TeamTask(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      text: json['text'] as String,
      visibility: json['visibility'] as String,
    );
  }
}
```

Put this exact content in `workspace/lib/contracts/team_task_list_response.dart`:

```dart
import 'team_task.dart';

class TeamTaskListResponse {
  final List<TeamTask> tasks;

  const TeamTaskListResponse({required this.tasks});

  factory TeamTaskListResponse.fromJson(Map<String, dynamic> json) {
    return TeamTaskListResponse(
      tasks: (json['tasks'] as List<dynamic>)
          .map(
            (taskJson) => TeamTask.fromJson(taskJson as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
```

Put this exact content in `workspace/lib/contracts/team_task_api.dart`:

```dart
import 'team_task.dart';
import 'team_task_list_response.dart';

abstract class TeamTaskApi {
  Future<TeamTaskListResponse> getTasks({
    required String principal,
    String? userId,
  });

  Future<TeamTask> createTask({
    required String ownerUserId,
    required String text,
    required String visibility,
  });

  Future<void> deleteTask(
    String taskId, {
    required String principal,
    String? userId,
  });
}
```

Do not add tests here. Keep this layer limited to interfaces and small shared types.

Then run:

```bash
just format
just check-all
git add --all
git commit --message "Define team-task-board Flutter contracts"
```
