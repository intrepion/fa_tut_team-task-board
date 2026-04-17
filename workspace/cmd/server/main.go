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
