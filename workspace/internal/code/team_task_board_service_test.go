package code

import (
	"testing"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
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
