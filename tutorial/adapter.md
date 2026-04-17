# Adapter

### 1. Red: Render Anonymous Visibility In The Handler

Create the first adapter test file:

```bash
mkdir -p workspace/internal/adapter/http
touch workspace/internal/adapter/http/team_task_board_handler_test.go
```

Put this exact content in `workspace/internal/adapter/http/team_task_board_handler_test.go`:

```go
package httpadapter

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockTeamTaskService struct{ mock.Mock }

func (m *MockTeamTaskService) ListTasks(principal contracts.Principal) ([]contracts.TeamTask, error) {
	args := m.Called(principal)
	return args.Get(0).([]contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) CreateTask(ownerUserID, text, visibility string) (contracts.TeamTask, error) {
	args := m.Called(ownerUserID, text, visibility)
	return args.Get(0).(contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) GetTask(taskID string, principal contracts.Principal) (contracts.TeamTask, error) {
	args := m.Called(taskID, principal)
	return args.Get(0).(contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) DeleteTask(taskID string, principal contracts.Principal) error {
	args := m.Called(taskID, principal)
	return args.Error(0)
}

func TestTaskHandlerListsOnlyPublicTasksForAnonymousUsers(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodGet, "/api/tasks", nil)
	rec := httptest.NewRecorder()
	ctx := e.NewContext(req, rec)

	service := new(MockTeamTaskService)
	service.On("ListTasks", contracts.AnonymousPrincipal{}).Return([]contracts.TeamTask{
		{ID: "task-1", OwnerUserID: "user-alice", Text: "Draft release notes", Visibility: "public"},
	}, nil)

	handler := NewTaskHandler(service)
	err := handler.ListTasks(ctx)

	assert.NoError(t, err)
	assert.Equal(t, http.StatusOK, rec.Code)

	var body struct {
		Tasks []contracts.TeamTask `json:"tasks"`
	}
	err = json.Unmarshal(rec.Body.Bytes(), &body)
	assert.NoError(t, err)
	assert.Len(t, body.Tasks, 1)
	service.AssertExpectations(t)
}
```

Run:

```bash
just check-tests
just format
git add --all
git commit --message "1. Red: Render Anonymous Visibility In The Handler"
```

### 2. Green: Wire The Visibility-Aware Handler

Create the first adapter production file:

```bash
touch workspace/internal/adapter/http/team_task_board_handler.go
```

Put this exact content in `workspace/internal/adapter/http/team_task_board_handler.go`:

```go
package httpadapter

import (
	"net/http"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
	"github.com/labstack/echo/v4"
)

type TeamTaskHandler struct{ service contracts.TeamTaskService }

type TeamTaskCreateRequest struct {
	OwnerUserID string `json:"owner_user_id"`
	Text        string `json:"text"`
	Visibility  string `json:"visibility"`
}

func NewTaskHandler(service contracts.TeamTaskService) *TeamTaskHandler {
	return &TeamTaskHandler{service: service}
}

func (h *TeamTaskHandler) ListTasks(c echo.Context) error {
	tasks, err := h.service.ListTasks(contracts.AnonymousPrincipal{})
	if err != nil {
		return c.JSON(http.StatusInternalServerError, contracts.ErrorResponse{Message: "internal server error"})
	}
	return c.JSON(http.StatusOK, map[string]any{"tasks": tasks})
}

func (h *TeamTaskHandler) CreateTask(c echo.Context) error {
	var request TeamTaskCreateRequest
	if err := c.Bind(&request); err != nil {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "invalid task request"})
	}

	task, err := h.service.CreateTask(request.OwnerUserID, request.Text, request.Visibility)
	if err != nil {
		if err == contracts.ErrTaskTextBlank {
			return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, contracts.ErrorResponse{Message: "internal server error"})
	}

	return c.JSON(http.StatusCreated, task)
}

func (h *TeamTaskHandler) GetTask(c echo.Context) error {
	taskID := c.Param("id")
	if taskID == "" {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "task id must not be empty"})
	}

	task, err := h.service.GetTask(taskID, contracts.AnonymousPrincipal{})
	if err != nil {
		if err == contracts.ErrTaskNotFound {
			return c.JSON(http.StatusNotFound, contracts.ErrorResponse{Message: "task not found"})
		}
		return c.JSON(http.StatusForbidden, contracts.ErrorResponse{Message: "forbidden"})
	}

	return c.JSON(http.StatusOK, task)
}

func (h *TeamTaskHandler) DeleteTask(c echo.Context) error {
	taskID := c.Param("id")
	if taskID == "" {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "task id must not be empty"})
	}

	err := h.service.DeleteTask(taskID, contracts.AnonymousPrincipal{})
	if err != nil {
		return c.JSON(http.StatusForbidden, contracts.ErrorResponse{Message: "forbidden"})
	}
	return c.NoContent(http.StatusNoContent)
}
```

Run:

```bash
just check-tests
just format
git add --all
git commit --message "2. Green: Wire The Visibility-Aware Handler"
```

### 3. Red: Add Owner And Admin Deletion Tests

Replace `workspace/internal/adapter/http/team_task_board_handler_test.go` with this exact content:

```go
package httpadapter

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
	"github.com/labstack/echo/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockTeamTaskService struct{ mock.Mock }

func (m *MockTeamTaskService) ListTasks(principal contracts.Principal) ([]contracts.TeamTask, error) {
	args := m.Called(principal)
	return args.Get(0).([]contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) CreateTask(ownerUserID, text, visibility string) (contracts.TeamTask, error) {
	args := m.Called(ownerUserID, text, visibility)
	return args.Get(0).(contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) GetTask(taskID string, principal contracts.Principal) (contracts.TeamTask, error) {
	args := m.Called(taskID, principal)
	return args.Get(0).(contracts.TeamTask), args.Error(1)
}

func (m *MockTeamTaskService) DeleteTask(taskID string, principal contracts.Principal) error {
	args := m.Called(taskID, principal)
	return args.Error(0)
}

func TestTaskHandlerAllowsOwnersToDeleteTheirOwnTask(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/api/tasks/task-1", nil)
	req.Header.Set("X-Team-Task-Principal", "user")
	req.Header.Set("X-Team-Task-User-ID", "user-alice")
	rec := httptest.NewRecorder()
	ctx := e.NewContext(req, rec)
	ctx.SetParamNames("id")
	ctx.SetParamValues("task-1")

	service := new(MockTeamTaskService)
	service.On("DeleteTask", "task-1", contracts.UserPrincipal{UserID: "user-alice"}).Return(nil)

	handler := NewTaskHandler(service)
	err := handler.DeleteTask(ctx)

	assert.NoError(t, err)
	assert.Equal(t, http.StatusNoContent, rec.Code)
	service.AssertExpectations(t)
}

func TestTaskHandlerRejectsOtherUsersTaskDeletion(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/api/tasks/task-2", nil)
	req.Header.Set("X-Team-Task-Principal", "user")
	req.Header.Set("X-Team-Task-User-ID", "user-alice")
	rec := httptest.NewRecorder()
	ctx := e.NewContext(req, rec)
	ctx.SetParamNames("id")
	ctx.SetParamValues("task-2")

	service := new(MockTeamTaskService)
	service.On("DeleteTask", "task-2", contracts.UserPrincipal{UserID: "user-alice"}).Return(contracts.ErrTaskNotFound)

	handler := NewTaskHandler(service)
	err := handler.DeleteTask(ctx)

	assert.NoError(t, err)
	assert.Equal(t, http.StatusNotFound, rec.Code)
	service.AssertExpectations(t)
}

func TestTaskHandlerAllowsAdminsToDeleteAnyTask(t *testing.T) {
	e := echo.New()
	req := httptest.NewRequest(http.MethodDelete, "/api/tasks/task-2", nil)
	req.Header.Set("X-Team-Task-Principal", "admin")
	req.Header.Set("X-Team-Task-User-ID", "user-admin")
	rec := httptest.NewRecorder()
	ctx := e.NewContext(req, rec)
	ctx.SetParamNames("id")
	ctx.SetParamValues("task-2")

	service := new(MockTeamTaskService)
	service.On("DeleteTask", "task-2", contracts.AdminPrincipal{UserID: "user-admin"}).Return(nil)

	handler := NewTaskHandler(service)
	err := handler.DeleteTask(ctx)

	assert.NoError(t, err)
	assert.Equal(t, http.StatusNoContent, rec.Code)
	service.AssertExpectations(t)
}
```

Run:

```bash
just check-tests
just format
git add --all
git commit --message "3. Red: Add Owner And Admin Deletion Tests"
```

### 4. Green: Wire Principal-Aware Deletion

Replace `workspace/internal/adapter/http/team_task_board_handler.go` with this exact content:

```go
package httpadapter

import (
	"net/http"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
	"github.com/labstack/echo/v4"
)

type TeamTaskHandler struct{ service contracts.TeamTaskService }

func NewTaskHandler(service contracts.TeamTaskService) *TeamTaskHandler {
	return &TeamTaskHandler{service: service}
}

func (h *TeamTaskHandler) ListTasks(c echo.Context) error {
	tasks, err := h.service.ListTasks(principalFromContext(c))
	if err != nil {
		return c.JSON(http.StatusInternalServerError, contracts.ErrorResponse{Message: "internal server error"})
	}
	return c.JSON(http.StatusOK, map[string]any{"tasks": tasks})
}

func (h *TeamTaskHandler) CreateTask(c echo.Context) error {
	var request TeamTaskCreateRequest
	if err := c.Bind(&request); err != nil {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "invalid task request"})
	}

	task, err := h.service.CreateTask(request.OwnerUserID, request.Text, request.Visibility)
	if err != nil {
		if err == contracts.ErrTaskTextBlank {
			return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: err.Error()})
		}
		return c.JSON(http.StatusInternalServerError, contracts.ErrorResponse{Message: "internal server error"})
	}

	return c.JSON(http.StatusCreated, task)
}

func (h *TeamTaskHandler) GetTask(c echo.Context) error {
	taskID := c.Param("id")
	if taskID == "" {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "task id must not be empty"})
	}

	task, err := h.service.GetTask(taskID, principalFromContext(c))
	if err != nil {
		if err == contracts.ErrTaskNotFound {
			return c.JSON(http.StatusNotFound, contracts.ErrorResponse{Message: "task not found"})
		}
		return c.JSON(http.StatusForbidden, contracts.ErrorResponse{Message: "forbidden"})
	}

	return c.JSON(http.StatusOK, task)
}

func (h *TeamTaskHandler) DeleteTask(c echo.Context) error {
	taskID := c.Param("id")
	if taskID == "" {
		return c.JSON(http.StatusBadRequest, contracts.ErrorResponse{Message: "task id must not be empty"})
	}

	err := h.service.DeleteTask(taskID, principalFromContext(c))
	if err != nil {
		switch err {
		case contracts.ErrTaskNotFound:
			return c.JSON(http.StatusNotFound, contracts.ErrorResponse{Message: "task not found"})
		default:
			return c.JSON(http.StatusForbidden, contracts.ErrorResponse{Message: "forbidden"})
		}
	}
	return c.NoContent(http.StatusNoContent)
}

func principalFromContext(c echo.Context) contracts.Principal {
	switch c.Request().Header.Get("X-Team-Task-Principal") {
	case "admin":
		return contracts.AdminPrincipal{UserID: c.Request().Header.Get("X-Team-Task-User-ID")}
	case "user":
		return contracts.UserPrincipal{UserID: c.Request().Header.Get("X-Team-Task-User-ID")}
	default:
		return contracts.AnonymousPrincipal{}
	}
}
```

Run:

```bash
just check-tests
just format
git add --all
git commit --message "4. Green: Wire Principal-Aware Deletion"
```
### 5. Green: Add The Postgres Store And Server Wiring

Create the Postgres store and server files:

```bash
mkdir -p workspace/internal/adapter/storage
mkdir -p workspace/cmd/server
touch workspace/internal/adapter/storage/postgres_team_task_store.go
touch workspace/cmd/server/main.go
```

Put this exact content in `workspace/internal/adapter/storage/postgres_team_task_store.go`:

```go
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
```

Put this exact content in `workspace/cmd/server/main.go`:

```go
package main

import (
	"log"
	"os"

	httpadapter "github.com/intrepion/fa_tut_team-task-board/workspace/internal/adapter/http"
	storageadapter "github.com/intrepion/fa_tut_team-task-board/workspace/internal/adapter/storage"
	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/code"
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"http://localhost:25616"},
	}))

	databaseURL := os.Getenv("TEAM_TASK_BOARD_DATABASE_URL")
	if databaseURL == "" {
		log.Fatal("TEAM_TASK_BOARD_DATABASE_URL must not be empty")
	}

	store, err := storageadapter.NewPostgresTeamTaskStore(databaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer store.Close()

	service := code.NewTeamTaskService(store)
	handler := httpadapter.NewTaskHandler(service)

	e.GET("/api/tasks", handler.ListTasks)
	e.POST("/api/tasks", handler.CreateTask)
	e.GET("/api/tasks/:id", handler.GetTask)
	e.DELETE("/api/tasks/:id", handler.DeleteTask)

	log.Fatal(e.Start(":25664"))
}
```

Run:

```bash
just check-tests
just format
git add --all
git commit --message "5. Green: Add The Postgres Store And Server Wiring"
```
