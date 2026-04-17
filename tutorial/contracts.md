# Contracts

From the repository root, run:

```bash
dotnet new classlib --language C# --output workspace/src/TeamTaskBoard.Contracts --name TeamTaskBoard.Contracts
just format
just check-all
git add --all
git commit --message 'dotnet new classlib --language C# --output workspace/src/TeamTaskBoard.Contracts --name TeamTaskBoard.Contracts'
dotnet sln workspace/TeamTaskBoard.sln add workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj
just format
just check-all
git add --all
git commit --message 'dotnet sln workspace/TeamTaskBoard.sln add workspace/src/TeamTaskBoard.Contracts/TeamTaskBoard.Contracts.csproj'
```

Use this file to define the shared contracts that the code layer implements and the adapter layer depends on.

Do not add tests here. Keep this layer limited to interfaces, request and response types, enums, and small shared value objects.

## Core Logic Contract

The shared core contracts are:

```text
parse_team_task_storage(storage_text: string) -> team_task[]
find_task_by_id(task_list: team_task[], task_id: string) -> team_task | null
filter_visible_tasks(task_list: team_task[], principal) -> team_task[]
can_delete_task(task: team_task, principal) -> boolean
remove_task_by_id(task_list: team_task[], task_id: string, principal) -> team_task[]
format_team_task_list(task_list: team_task[]) -> string[]
serialize_team_task_storage(task_list: team_task[]) -> string
```

Where each `team_task` contains:

```text
id
owner_user_id
text
visibility
```

Canonical behavior:

- `parse_team_task_storage`:
  - parses the stored JSON document as an array of task records
  - preserves exact task ids, owner ids, text, and visibility values
  - preserves source order
- `find_task_by_id`:
  - compares `task_id` by exact string match
  - returns the first exact matching task when present
  - returns `null` when no exact matching task is present
- `filter_visible_tasks`:
  - for `anonymous`, returns only tasks whose `visibility` is `public`
  - for `user(user_id)`, returns all public tasks plus any private tasks owned by that `user_id`
  - for `admin(user_id)`, returns all tasks
- `can_delete_task`:
  - returns `false` for `anonymous`
  - returns `true` for `user(user_id)` only when `task.owner_user_id` exactly matches `user_id`
  - returns `true` for `admin(user_id)` for every task
- `remove_task_by_id`:
  - returns a new list
  - removes the first exact matching task only when `can_delete_task` is `true`
  - preserves the relative order of the remaining tasks
  - returns the unchanged list when the task is missing or deletion is not allowed
- `format_team_task_list`:
  - returns one line per task
  - preserves input order
  - formats each line as `<id> | <visibility> | <text>`
- `serialize_team_task_storage`:
  - returns a JSON string equivalent to the input task record array in order
  - preserves exact ids, owner ids, text, and visibility values

Examples:

- `filter_visible_tasks(parse_team_task_storage(canonical_storage_text), anonymous)` returns only:
  - `task-1`
- `filter_visible_tasks(parse_team_task_storage(canonical_storage_text), user("user-alice"))` returns:
  - `task-1`
  - `task-3`
- `filter_visible_tasks(parse_team_task_storage(canonical_storage_text), admin("user-admin"))` returns:
  - `task-1`
  - `task-2`
  - `task-3`
- `can_delete_task(find_task_by_id(parse_team_task_storage(canonical_storage_text), "task-2"), user("user-bob"))` returns `true`
- `can_delete_task(find_task_by_id(parse_team_task_storage(canonical_storage_text), "task-2"), user("user-alice"))` returns `false`
- `format_team_task_list(filter_visible_tasks(parse_team_task_storage(canonical_storage_text), anonymous))` returns:
  - `task-1 | public | Draft release notes`

After the contract files are in place, run:

```bash
just format
just check-all
git add --all
git commit --message "Define contracts"
```
