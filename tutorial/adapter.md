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
