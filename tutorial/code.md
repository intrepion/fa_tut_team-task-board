# Code

### 1. Red: Anonymous Users Only See Public Tasks

Create the first code test file:

```bash
touch workspace/internal/code/team_task_board_service_test.go
```

Put this exact content in `workspace/internal/code/team_task_board_service_test.go`:

```go
package code

import (
	"testing"

	"__MODULE_PATH__/internal/contracts"
	"github.com/stretchr/testify/assert"
)

func TestFilterVisibleTasksReturnsOnlyPublicTasksForAnonymous(t *testing.T) {
	tasks := []contracts.TeamTask{
		{ID: "task-1", OwnerUserID: "user-alice", Text: "Draft release notes", Visibility: "public"},
		{ID: "task-2", OwnerUserID: "user-bob", Text: "Fix login redirect bug", Visibility: "private"},
	}

	result := filterVisibleTasks(tasks, contracts.AnonymousPrincipal{})

	assert.Equal(t, []contracts.TeamTask{
		{ID: "task-1", OwnerUserID: "user-alice", Text: "Draft release notes", Visibility: "public"},
	}, result)
}

func TestCanDeleteTaskAllowsOwnersAndAdmins(t *testing.T) {
	task := contracts.TeamTask{ID: "task-2", OwnerUserID: "user-bob", Text: "Fix login redirect bug", Visibility: "private"}

	assert.True(t, canDeleteTask(task, contracts.UserPrincipal{UserID: "user-bob"}))
	assert.False(t, canDeleteTask(task, contracts.UserPrincipal{UserID: "user-alice"}))
	assert.True(t, canDeleteTask(task, contracts.AdminPrincipal{UserID: "user-admin"}))
	assert.False(t, canDeleteTask(task, contracts.AnonymousPrincipal{}))
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "1. Red: Anonymous Users Only See Public Tasks"
```

### 2. Green: Enforce Visibility And Deletion Rules

Create the first production file:

```bash
touch workspace/internal/code/team_task_board_service.go
```

Put this exact content in `workspace/internal/code/team_task_board_service.go`:

```go
package code

import (
	"encoding/json"

	"__MODULE_PATH__/internal/contracts"
)

func filterVisibleTasks(tasks []contracts.TeamTask, principal contracts.Principal) []contracts.TeamTask {
	var result []contracts.TeamTask
	for _, task := range tasks {
		if task.Visibility == "public" {
			result = append(result, task)
			continue
		}
		if user, ok := principal.(contracts.UserPrincipal); ok && user.UserID == task.OwnerUserID {
			result = append(result, task)
			continue
		}
		if _, ok := principal.(contracts.AdminPrincipal); ok {
			result = append(result, task)
		}
	}
	return result
}

func canDeleteTask(task contracts.TeamTask, principal contracts.Principal) bool {
	switch current := principal.(type) {
	case contracts.UserPrincipal:
		return current.UserID == task.OwnerUserID
	case contracts.AdminPrincipal:
		return true
	default:
		return false
	}
}

func removeTaskById(tasks []contracts.TeamTask, taskID string, principal contracts.Principal) []contracts.TeamTask {
	result := append([]contracts.TeamTask{}, tasks...)
	for index, task := range result {
		if task.ID == taskID && canDeleteTask(task, principal) {
			return append(result[:index], result[index+1:]...)
		}
	}
	return result
}

func formatTeamTaskList(tasks []contracts.TeamTask) []string {
	lines := make([]string, 0, len(tasks))
	for _, task := range tasks {
		lines = append(lines, task.ID+" | "+task.Visibility+" | "+task.Text)
	}
	return lines
}

func serializeTeamTaskStorage(tasks []contracts.TeamTask) string {
	storageBytes, _ := json.Marshal(tasks)
	return string(storageBytes)
}
```

Run:

```bash
just format
just check-all
git add --all
git commit --message "2. Green: Enforce Visibility And Deletion Rules"
```
