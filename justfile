set shell := ["bash", "-eu", "-c"]

default:
	@just --list

workspace := "workspace"
database_url := "postgres://postgres@localhost:5432/team_task_board?sslmode=disable"

restore:
	(cd {{workspace}} && go mod download)
	(cd {{workspace}} && GOBIN=$(pwd)/bin go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.30.0)

generate:
	(cd {{workspace}} && ./bin/sqlc generate)

format:
	find {{workspace}} -name '*.go' -exec gofmt -w {} +

check-formatting:
	test -z "$(find {{workspace}} -name '*.go' -exec gofmt -l {} +)"

check-tests:
	just generate
	(cd {{workspace}} && go test ./...)

run:
	just generate
	(cd {{workspace}} && TEAM_TASK_BOARD_DATABASE_URL={{database_url}} go run ./cmd/server)

check-all:
	just check-formatting
	just check-tests
