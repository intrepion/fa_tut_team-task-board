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
