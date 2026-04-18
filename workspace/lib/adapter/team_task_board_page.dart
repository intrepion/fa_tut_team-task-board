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
            ElevatedButton(onPressed: _addTask, child: const Text('Add task')),
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
