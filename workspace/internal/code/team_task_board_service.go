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

type DefaultTeamTaskService struct {
	store contracts.TeamTaskStore
}

func NewTeamTaskService(store contracts.TeamTaskStore) contracts.TeamTaskService {
	return DefaultTeamTaskService{store: store}
}

func canViewTask(task contracts.TeamTask, principal contracts.Principal) bool {
	if task.Visibility == "public" {
		return true
	}
	if user, ok := principal.(contracts.UserPrincipal); ok && user.UserID == task.OwnerUserID {
		return true
	}
	_, ok := principal.(contracts.AdminPrincipal)
	return ok
}

func (s DefaultTeamTaskService) ListTasks(principal contracts.Principal) ([]contracts.TeamTask, error) {
	tasks, err := s.store.ListTasks()
	if err != nil {
		return nil, err
	}

	return filterVisibleTasks(tasks, principal), nil
}

func (s DefaultTeamTaskService) CreateTask(ownerUserID, text, visibility string) (contracts.TeamTask, error) {
	if text == "" {
		return contracts.TeamTask{}, contracts.ErrTaskTextBlank
	}

	return s.store.CreateTask(ownerUserID, text, visibility)
}

func (s DefaultTeamTaskService) GetTask(taskID string, principal contracts.Principal) (contracts.TeamTask, error) {
	task, found, err := s.store.GetTask(taskID)
	if err != nil {
		return contracts.TeamTask{}, err
	}
	if !found || !canViewTask(task, principal) {
		return contracts.TeamTask{}, contracts.ErrTaskNotFound
	}

	return task, nil
}

func (s DefaultTeamTaskService) DeleteTask(taskID string, principal contracts.Principal) error {
	task, found, err := s.store.GetTask(taskID)
	if err != nil {
		return err
	}
	if !found || !canDeleteTask(task, principal) {
		return contracts.ErrTaskNotFound
	}

	deleted, err := s.store.DeleteTask(taskID)
	if err != nil {
		return err
	}
	if !deleted {
		return contracts.ErrTaskNotFound
	}

	return nil
}
