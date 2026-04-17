CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  owner_user_id TEXT NOT NULL,
  text TEXT NOT NULL,
  visibility TEXT NOT NULL
);
