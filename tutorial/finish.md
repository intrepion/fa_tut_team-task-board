# Finish

Make sure you have a local Postgres database named `team_task_board`. The default tutorial command for that is:

```bash
createdb --host localhost --username postgres team_task_board
```

Start the API server from the repository root:

```bash
just run
```

The generated `just run` and `just check-tests` commands call `sqlc generate` for you before compiling the app.

If your local Postgres uses a different connection string, run:

```bash
just --set database_url "postgres://<user>:<password>@localhost:5432/<database>?sslmode=disable" run
```

This API is configured to accept browser requests from `http://localhost:25616`.

In another terminal, try these requests:

```bash
curl "http://localhost:25664/api/tasks"
curl -X POST "http://localhost:25664/api/tasks" \
  -H "Content-Type: application/json" \
  -d '{"text":"Buy milk"}'
curl "http://localhost:25664/api/tasks/11111111-1111-1111-1111-111111111111"
curl -i -X DELETE "http://localhost:25664/api/tasks/11111111-1111-1111-1111-111111111111"
```

With a fresh database, the first `GET` should return an empty list:

```json
{"tasks":[]}
```

The `POST` should return a created task resource with a UUID id, for example:

```json
{"id":"11111111-1111-1111-1111-111111111111","text":"Buy milk"}
```

The next `GET /api/tasks/<uuid>` should return the same task resource. The `DELETE` should return `204 No Content`.

If you already have rows in the database, Postgres will assign a different UUID than the example above.
