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
