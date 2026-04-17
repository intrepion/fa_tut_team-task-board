package storageadapter

import (
	"context"
	"database/sql"
	"errors"

	storedb "github.com/intrepion/fa_tut_team-task-board/workspace/internal/adapter/storage/db"
	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
	_ "github.com/jackc/pgx/v5/stdlib"
)

type PostgresTeamTaskStore struct {
	db      *sql.DB
	queries *storedb.Queries
}

func NewPostgresTeamTaskStore(databaseURL string) (*PostgresTeamTaskStore, error) {
	db, err := sql.Open("pgx", databaseURL)
	if err != nil {
		return nil, err
	}

	store := &PostgresTeamTaskStore{
		db:      db,
		queries: storedb.New(db),
	}
	if err := store.ensureSchema(); err != nil {
		_ = db.Close()
		return nil, err
	}

	return store, nil
}

func (s *PostgresTeamTaskStore) Close() error {
	return s.db.Close()
}

func (s *PostgresTeamTaskStore) ensureSchema() error {
	_, err := s.db.Exec(`
		CREATE TABLE IF NOT EXISTS tasks (
			id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
			owner_user_id TEXT NOT NULL,
			text TEXT NOT NULL,
			visibility TEXT NOT NULL
		)
	`)
	return err
}

func (s *PostgresTeamTaskStore) ListTasks() ([]contracts.TeamTask, error) {
	rows, err := s.queries.ListTasks(context.Background())
	if err != nil {
		return nil, err
	}

	tasks := make([]contracts.TeamTask, 0, len(rows))
	for _, row := range rows {
		tasks = append(tasks, contracts.TeamTask{
			ID:          row.ID,
			OwnerUserID: row.OwnerUserID,
			Text:        row.Text,
			Visibility:  row.Visibility,
		})
	}

	return tasks, nil
}

func (s *PostgresTeamTaskStore) CreateTask(ownerUserID, text, visibility string) (contracts.TeamTask, error) {
	row, err := s.queries.CreateTask(context.Background(), storedb.CreateTaskParams{
		OwnerUserID: ownerUserID,
		Text:        text,
		Visibility:  visibility,
	})
	if err != nil {
		return contracts.TeamTask{}, err
	}

	return contracts.TeamTask{
		ID:          row.ID,
		OwnerUserID: row.OwnerUserID,
		Text:        row.Text,
		Visibility:  row.Visibility,
	}, nil
}

func (s *PostgresTeamTaskStore) GetTask(taskID string) (contracts.TeamTask, bool, error) {
	row, err := s.queries.GetTask(context.Background(), taskID)
	if errors.Is(err, sql.ErrNoRows) {
		return contracts.TeamTask{}, false, nil
	}
	if err != nil {
		return contracts.TeamTask{}, false, err
	}

	return contracts.TeamTask{
		ID:          row.ID,
		OwnerUserID: row.OwnerUserID,
		Text:        row.Text,
		Visibility:  row.Visibility,
	}, true, nil
}

func (s *PostgresTeamTaskStore) DeleteTask(taskID string) (bool, error) {
	rowsAffected, err := s.queries.DeleteTask(context.Background(), taskID)
	if err != nil {
		return false, err
	}

	return rowsAffected > 0, nil
}
