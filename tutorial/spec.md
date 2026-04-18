# Spec

Canonical project contract for the `team-task-board` project.

## Goal

Build a small project app that introduces:

- persisting team task records in a durable storage mechanism
- distinguishing anonymous, normal-user, and admin principals
- filtering task visibility by principal and task visibility
- authorizing deletion by ownership or admin role
- parsing and serializing a canonical JSON task-board representation
- test-first parsing, authorization, filtering, and formatting logic in small core functions
- thin adapters

## Canonical Sample Stored Task Data

For deterministic tests and examples, use stored task data equivalent to this JSON document:

```json
[
  {
    "id": "task-1",
    "owner_user_id": "user-alice",
    "text": "Draft release notes",
    "visibility": "public"
  },
  {
    "id": "task-2",
    "owner_user_id": "user-bob",
    "text": "Fix login redirect bug",
    "visibility": "private"
  },
  {
    "id": "task-3",
    "owner_user_id": "user-alice",
    "text": "Prepare sprint demo",
    "visibility": "private"
  }
]
```

## Canonical Principals

Every tutorial run for this project should treat these principal shapes as canonical equivalents:

```text
anonymous
user(user_id)
admin(user_id)
```

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

## Non-Goals

This project does not include:

- task editing
- due dates
- priorities
- categories or tags
- multiple boards
- real password hashing or production-grade identity providers
- task assignment to multiple users

## Surface Expectations

This spec follows the shared surface and setup-path rules in the shared project guidance.

For this project, every tutorial run should adapt the same parsing, visibility, deletion, formatting, and serialization behavior instead of redefining it.

Adapters should:

- use one chosen surface and target path
- load the existing stored tasks from the chosen durable storage mechanism in a form equivalent to the canonical JSON task array
- pass equivalent stored JSON text to `parse_team_task_storage`
- establish one current principal in a form equivalent to `anonymous`, `user(user_id)`, or `admin(user_id)`
- filter visible tasks by passing the current task list and principal to `filter_visible_tasks`
- display only the filtered visible tasks by passing them to `format_team_task_list`
- collect one task id to delete through the chosen surface
- look up the chosen task id with `find_task_by_id`
- determine whether deletion is allowed with `can_delete_task`
- remove the task by passing the current task list, task id, and principal to `remove_task_by_id`
- persist the final task list by passing it to `serialize_team_task_storage`
- if the chosen storage engine is not itself a local JSON file, translate the serialized JSON array into the chosen durable storage representation before saving it

## Output Repository Expectations

This project follows the shared output model in the shared project guidance.

For this project, the code layer in this repo owns `parse_team_task_storage`, `find_task_by_id`, `filter_visible_tasks`, `can_delete_task`, `remove_task_by_id`, `format_team_task_list`, and `serialize_team_task_storage`, and adapter layer must not reimplement them.

## Testing And Coverage Contract

This spec follows the shared coverage policy in the shared project guidance.

This project should be built in a spec-driven and test-driven way.

Minimum test expectations:

- a test that `parse_team_task_storage` preserves the exact canonical task records and order
- a test that `filter_visible_tasks` returns only public tasks for `anonymous`
- a test that `filter_visible_tasks` returns public tasks plus the user's own private tasks for a normal user
- a test that `filter_visible_tasks` returns all tasks for an admin
- a test that `can_delete_task` allows owners to delete their own tasks
- a test that `can_delete_task` allows admins to delete any task
- a test that `can_delete_task` denies anonymous principals and non-owner normal users
- a test that `remove_task_by_id` removes an authorized exact match and preserves order
- a test that `remove_task_by_id` preserves the unchanged list when deletion is not allowed
- a test that `format_team_task_list` preserves exact visible task data and order
- a test that `serialize_team_task_storage` preserves exact task record data and order in a JSON array document
- tests for every adapter built in the chosen run that prove it loads tasks from the chosen durable storage mechanism, establishes a current principal, shows only the tasks visible to that principal, enforces owner-vs-admin deletion rights, and persists the final task list without changing the canonical task-board semantics
