# Adapter

Both the adapter library and the adapter test library should reference the contracts library. The adapter library should also reference the code library.

From the repository root, run:

```bash
dotnet new console --language C# --output workspace/src/TeamTaskBoard.CommandLine --name TeamTaskBoard.CommandLine
just format
just check-all
git add --all
git commit --message 'dotnet new console --language C# --output workspace/src/TeamTaskBoard.CommandLine --name TeamTaskBoard.CommandLine'
dotnet new xunit --language C# --output workspace/tests/TeamTaskBoard.CommandLine.Tests --name TeamTaskBoard.CommandLine.Tests
just format
just check-all
git add --all
git commit --message 'dotnet new xunit --language C# --output workspace/tests/TeamTaskBoard.CommandLine.Tests --name TeamTaskBoard.CommandLine.Tests'
dotnet sln workspace/TeamTaskBoard.sln add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj
just format
just check-all
git add --all
git commit --message 'dotnet sln workspace/TeamTaskBoard.sln add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj'
dotnet sln workspace/TeamTaskBoard.sln add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj
just format
just check-all
git add --all
git commit --message 'dotnet sln workspace/TeamTaskBoard.sln add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj'
dotnet add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj reference workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj
just format
just check-all
git add --all
git commit --message 'dotnet add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj reference workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj'
dotnet add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj reference workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj
just format
just check-all
git add --all
git commit --message 'dotnet add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj reference workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj'
dotnet add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj reference workspace/src/TeamTaskBoard/TeamTaskBoard.csproj
just format
just check-all
git add --all
git commit --message 'dotnet add workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj reference workspace/src/TeamTaskBoard/TeamTaskBoard.csproj'
dotnet add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj reference workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj
just format
just check-all
git add --all
git commit --message 'dotnet add workspace/tests/TeamTaskBoard.CommandLine.Tests/TeamTaskBoard.CommandLine.Tests.csproj reference workspace/src/TeamTaskBoard.CommandLine/TeamTaskBoard.CommandLine.csproj'
```

Project-specific adapter instruction fragment for the `team-task-board` adapter layer in this repo.

### 1. Red: Prove Anonymous Users Only See Public Tasks

Write a failing adapter test:

```text
given the current principal is anonymous
when the team task board is rendered
then only the public tasks are shown
and no delete action is available
```

### 2. Green: Render The Anonymous View

Make the smallest adapter change that delegates visible-task filtering to `filter_visible_tasks` and list formatting to `format_team_task_list`.

### 3. Red: Prove Normal Users Can Delete Only Their Own Tasks

Write a failing adapter test:

```text
given the current principal is user("user-bob")
when the board includes task-2 owned by user-bob and task-1 owned by user-alice
then delete is allowed for task-2
and delete is not allowed for task-1
```

### 4. Green: Wire Owner Deletion

Make the smallest adapter change that uses `find_task_by_id`, `can_delete_task`, and `remove_task_by_id` for the normal-user path.

### 5. Red: Prove Admins Can Delete Any Task

Write a failing adapter test for the admin path.

### 6. Green: Wire Admin Deletion

Make it pass while keeping the earlier anonymous and normal-user paths green.
