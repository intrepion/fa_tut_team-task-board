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
      home: TeamTaskBoardPage(api: HttpTeamTaskApi(baseUrl: apiBaseUrl)),
    );
  }
}
