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
