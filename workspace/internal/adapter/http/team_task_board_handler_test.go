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
