# Setup

Keep the repository root for shared files like `README.md`, `LICENSE`, `.gitignore`, `.github/`, `justfile`, and `tutorial/`.

Put all Go code inside a single `workspace/` folder.

This tutorial builds a team task board with public and private tasks, anonymous/user/admin principals, and owner-vs-admin deletion rules.

This API is configured to accept browser requests from `http://localhost:{FOR_ALL_FRONTEND_PORT}` and to persist team task records in `workspace/data/tasks.db`.

From the repository root, run each setup command and checkpoint it before moving to the next one:

```bash
rm -rf workspace

mkdir -p workspace

curl -L -s https://raw.githubusercontent.com/github/gitignore/refs/heads/main/Go.gitignore > workspace/.gitignore
just format
git add --all
git commit --message "curl -L -s https://raw.githubusercontent.com/github/gitignore/refs/heads/main/Go.gitignore > workspace/.gitignore"

printf '\n# Repo-local tools\nbin/\n\n# Local runtime data\ndata/\n' >> workspace/.gitignore
just format
git add --all
git commit --message "printf '\\n# Repo-local tools\\nbin/\\n\\n# Local runtime data\\ndata/\\n' >> workspace/.gitignore"

(cd workspace && go mod init github.com/intrepion/fa_tut_team-task-board/workspace)
just format
git add --all
git commit --message "(cd workspace && go mod init github.com/intrepion/fa_tut_team-task-board/workspace)"

(cd workspace && GOBIN=$(pwd)/bin go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.30.0)
just format
git add --all
git commit --message "(cd workspace && GOBIN=\$(pwd)/bin go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.30.0)"

(cd workspace && go get github.com/labstack/echo/v4)
just format
git add --all
git commit --message "(cd workspace && go get github.com/labstack/echo/v4)"

(cd workspace && go get github.com/labstack/echo/v4/middleware)
just format
git add --all
git commit --message "(cd workspace && go get github.com/labstack/echo/v4/middleware)"

(cd workspace && go get github.com/jackc/pgx/v5/stdlib)
just format
git add --all
git commit --message "(cd workspace && go get github.com/jackc/pgx/v5/stdlib)"

(cd workspace && go get github.com/DATA-DOG/go-sqlmock)
just format
git add --all
git commit --message "(cd workspace && go get github.com/DATA-DOG/go-sqlmock)"

(cd workspace && go get github.com/stretchr/testify/assert github.com/stretchr/testify/mock)
just format
git add --all
git commit --message "(cd workspace && go get github.com/stretchr/testify/assert github.com/stretchr/testify/mock)"

mkdir -p workspace/db/query

mkdir -p workspace
touch workspace/sqlc.yaml
just format
git add --all
git commit --message "touch workspace/sqlc.yaml"

mkdir -p workspace/db
touch workspace/db/schema.sql
just format
git add --all
git commit --message "touch workspace/db/schema.sql"

mkdir -p workspace/db/query
touch workspace/db/query/tasks.sql
just format
git add --all
git commit --message "touch workspace/db/query/tasks.sql"
```

Put this exact content in `workspace/sqlc.yaml`:

```yaml
version: "2"
sql:
  - engine: "postgresql"
    schema: "db/schema.sql"
    queries: "db/query/tasks.sql"
    gen:
      go:
        package: "storedb"
        out: "internal/adapter/storage/db"
        sql_package: "database/sql"
```

Put this exact content in `workspace/db/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  text TEXT NOT NULL
);
```

Put this exact content in `workspace/db/query/tasks.sql`:

```sql
-- name: ListTasks :many
SELECT id, text
FROM tasks
ORDER BY text ASC, id ASC;

-- name: CreateTask :one
INSERT INTO tasks (text)
VALUES ($1)
RETURNING id, text;

-- name: GetTask :one
SELECT id, text
FROM tasks
WHERE id = $1
LIMIT 1;

-- name: DeleteTask :execrows
DELETE FROM tasks
WHERE id = $1;
```

Then run:

```bash
just format
git add --all
git commit --message "Add sqlc configuration and queries"
```

This gives you:

- a root-level `.gitignore` for operating-system noise and editor leftovers
- a `workspace/.gitignore` for standard Go build output, local tooling files, and local runtime data
- a Postgres-backed REST adapter that reads its connection string from `TEAM_TASK_BOARD_DATABASE_URL`
- a generated root `justfile` that defaults `database_url` to `postgres://postgres@localhost:5432/team_task_board?sslmode=disable`
- a repo-local `workspace/bin/sqlc` installation for generating Go query code from `workspace/sqlc.yaml`, `workspace/db/schema.sql`, and `workspace/db/query/tasks.sql`

Before you run the server, create the default tutorial database with:

```bash
createdb --host localhost --username postgres team_task_board
```

If that does not match your local Postgres setup, create an equivalent database your user can access and override the generated `database_url` value in the root `justfile`.

In another terminal, try these requests:

```bash
curl "http://localhost:25664/api/tasks"
curl -X POST "http://localhost:25664/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{"owner_user_id":"user-alice","text":"Draft release notes","visibility":"public"}'
curl "http://localhost:25664/api/tasks/11111111-1111-1111-1111-111111111111"
curl -i -X DELETE "http://localhost:25664/api/tasks/11111111-1111-1111-1111-111111111111"
```

With a fresh database, the first `GET` should return an empty list:

```json
{"tasks":[]}
```

The `POST` should return a created task resource with a UUID id, owner id, and visibility, for example:

```json
{"id":"11111111-1111-1111-1111-111111111111","owner_user_id":"user-alice","text":"Draft release notes","visibility":"public"}
```

The next `GET /api/tasks/<uuid>` should return the same task resource. The `DELETE` should return `204 No Content`.

When you later add the adapter behavior for the board, anonymous users should see only public tasks, normal users should see public tasks plus their own private tasks, and admins should be able to delete any task.

When the full workspace is finished, it should contain these files:

```text
workspace/
  .gitignore
  bin/
    sqlc
  go.mod
  go.sum
  sqlc.yaml
  db/
    schema.sql
    query/
      tasks.sql
  cmd/
    server/
      main.go
  internal/
    contracts/
      task_api.go
    code/
      task_service.go
      task_service_test.go
    adapter/
      http/
        task_handler.go
        task_handler_test.go
      storage/
        postgres_task_store.go
        postgres_task_store_test.go
        db/
          ...generated Go files from sqlc...
```
