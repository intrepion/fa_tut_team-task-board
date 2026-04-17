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
