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
