# run commands via docker-compose


### ENV VARS ###

# defaults
# use the old docker-compose which uses v1 protocol - needed for building with podman as `docker compose build` doesn't work
DOCKER_COMPOSE="docker-compose"

# expose UID as Makefile vars
UID := $(shell id -u)

# override with .env
ifneq (,$(wildcard ./.env))
	include .env
	export
endif

# podman override
ifeq ($(PODMAN), true)
  DOCKER_HOST=unix:///run/user/$(UID)/podman/podman.sock
endif


### DEFAULT RULE ###

.DEFAULT_GOAL := help
# list all make targets
help:
	@echo "Use one of these make targets:"
	@make -rpn | sed -n -e '/^$$/ { n ; /^[^ .#][^ ]*:/p ; }' | sed -e 's/:$$//' | egrep --color '^[^ ]*'


### COMMANDS ###

# build the docker image - use dummy env vars to ensure it works without .env configured
build:
	GITHUB_ACTIONS_RUNNER_GITHUB_ORG='' GITHUB_ACTIONS_RUNNER_LABELS='' GITHUB_ACTIONS_RUNNER_NAME='' GITHUB_ACTIONS_RUNNER_TOKEN='' $(DOCKER_COMPOSE) build

# clean out test docker containers - use dummy env vars to ensure it works without .env configured
clean:
	GITHUB_ACTIONS_RUNNER_GITHUB_ORG='' GITHUB_ACTIONS_RUNNER_LABELS='' GITHUB_ACTIONS_RUNNER_NAME='' GITHUB_ACTIONS_RUNNER_TOKEN='' $(DOCKER_COMPOSE) down

# run a temporary debug shell
run-temporary-debug-shell:
	${DOCKER_COMPOSE} run --entrypoint bash --rm github-actions-runner-nomad

# test the docker image
test:
	${DOCKER_COMPOSE} up

# run a shell within the running test container
test-shell-within-running-test-container:
	${DOCKER_COMPOSE} exec github-actions-runner-nomad bash
