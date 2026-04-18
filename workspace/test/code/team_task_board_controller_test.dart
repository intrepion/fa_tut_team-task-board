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
