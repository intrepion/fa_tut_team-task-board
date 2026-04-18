set shell := ["bash", "-eu", "-c"]

default:
	@just --list

workspace := "workspace"

api_base_url := "http://localhost:25664"

restore:
	(cd {{workspace}} && flutter pub get)

format:
	(cd {{workspace}} && dart format lib test integration_test)

check-formatting:
	(cd {{workspace}} && dart format --output=none --set-exit-if-changed lib test integration_test)

check-tests:
	(cd {{workspace}} && flutter test)

devices:
	(cd {{workspace}} && flutter devices)

emulators:
	(cd {{workspace}} && flutter emulators)

run:
	just run-web

run-web:
	(cd {{workspace}} && flutter run -d chrome --web-port 25616 --dart-define=API_BASE_URL={{api_base_url}})

run-ios device="":
	#!/usr/bin/env bash
	set -euo pipefail
	normalized_device='{{device}}'
	normalized_device="${normalized_device#\"}"
	normalized_device="${normalized_device%\"}"
	normalized_device="${normalized_device#device=}"
	if [ -n "$normalized_device" ]; then
	  (cd {{workspace}} && flutter run -d "$normalized_device" --dart-define=API_BASE_URL={{api_base_url}})
	else
	  echo 'Use `just devices` and rerun with device="<ios-device-id-or-name>".' >&2
	  exit 1
	fi

run-android device="":
	#!/usr/bin/env bash
	set -euo pipefail
	normalized_device='{{device}}'
	normalized_device="${normalized_device#\"}"
	normalized_device="${normalized_device%\"}"
	normalized_device="${normalized_device#device=}"
	if [ -n "$normalized_device" ]; then
	  (cd {{workspace}} && flutter run -d "$normalized_device" --dart-define=API_BASE_URL={{api_base_url}})
	else
	  echo 'Use `just devices` and rerun with device="<android-device-id-or-name>".' >&2
	  exit 1
	fi

run-macos:
	(cd {{workspace}} && flutter run -d macos --dart-define=API_BASE_URL={{api_base_url}})

run-windows:
	(cd {{workspace}} && flutter run -d windows --dart-define=API_BASE_URL={{api_base_url}})

run-linux:
	(cd {{workspace}} && flutter run -d linux --dart-define=API_BASE_URL={{api_base_url}})

check-all:
	just check-formatting
	just check-tests
