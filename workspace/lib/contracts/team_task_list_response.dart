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
