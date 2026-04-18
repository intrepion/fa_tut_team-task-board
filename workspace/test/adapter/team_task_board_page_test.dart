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

    when(() => api.getTasks(principal: 'anonymous', userId: null)).thenAnswer(
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
      () => api.deleteTask('task-2', principal: 'admin', userId: 'user-admin'),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(MaterialApp(home: TeamTaskBoardPage(api: api)));
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
      () => api.deleteTask('task-2', principal: 'admin', userId: 'user-admin'),
    ).called(1);
  });
}
