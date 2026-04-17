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
