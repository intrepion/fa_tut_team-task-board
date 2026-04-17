# Setup

Keep the repository root for shared files like `README.md`, `LICENSE`, `.gitignore`, `.github/`, `justfile`, and `tutorial/`.

Put all Go code inside a single `workspace/` folder.

This tutorial builds a team task board with public and private tasks, anonymous/user/admin principals, and owner-vs-admin deletion rules.

This API is configured to accept browser requests from `http://localhost:{FOR_ALL_FRONTEND_PORT}` and to persist team task records in Postgres with owner, visibility, and UUID id columns.

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
  owner_user_id TEXT NOT NULL,
  text TEXT NOT NULL,
  visibility TEXT NOT NULL
);
```

Put this exact content in `workspace/db/query/tasks.sql`:

```sql
-- name: ListTasks :many
SELECT id, owner_user_id, text, visibility
FROM tasks
ORDER BY text ASC, id ASC;

-- name: CreateTask :one
INSERT INTO tasks (owner_user_id, text, visibility)
VALUES ($1, $2, $3)
RETURNING id, owner_user_id, text, visibility;

-- name: GetTask :one
SELECT id, owner_user_id, text, visibility
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
