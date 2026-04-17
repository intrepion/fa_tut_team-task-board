# Contracts

Create the shared contract file:

```bash
mkdir -p workspace/internal/contracts
touch workspace/internal/contracts/team_task_board.go
```

Put this exact content in `workspace/internal/contracts/team_task_board.go`:

```go
package contracts

import "errors"

var (
	ErrTaskTextBlank = errors.New("task text must not be blank")
	ErrTaskNotFound  = errors.New("task not found")
)

type Principal interface{ isPrincipal() }
type AnonymousPrincipal struct{}
type UserPrincipal struct{ UserID string }
type AdminPrincipal struct{ UserID string }

func (AnonymousPrincipal) isPrincipal() {}
func (UserPrincipal) isPrincipal() {}
func (AdminPrincipal) isPrincipal() {}

type TeamTask struct {
	ID          string `json:"id"`
	OwnerUserID string `json:"owner_user_id"`
	Text        string `json:"text"`
	Visibility  string `json:"visibility"`
}

type TeamTaskStore interface {
	ListTasks() ([]TeamTask, error)
	CreateTask(ownerUserID, text, visibility string) (TeamTask, error)
	GetTask(taskID string) (TeamTask, bool, error)
	DeleteTask(taskID string) (bool, error)
}

type TeamTaskService interface {
	ListTasks(principal Principal) ([]TeamTask, error)
	CreateTask(ownerUserID, text, visibility string) (TeamTask, error)
	GetTask(taskID string, principal Principal) (TeamTask, error)
	DeleteTask(taskID string, principal Principal) error
}

type ErrorResponse struct {
	Message string `json:"message"`
}
```

Do not add tests here. Keep this layer limited to the board principals, the task record shape, and the authorization interfaces.

Then run:

```bash
just format
git add --all
git commit --message "Define team task board contracts"
```
