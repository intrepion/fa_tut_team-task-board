package code

import (
	"encoding/json"

	"github.com/intrepion/fa_tut_team-task-board/workspace/internal/contracts"
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
