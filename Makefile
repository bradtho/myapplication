SHELL := /bin/sh
.PHONY: clean
.PHONY: help
# COLORS
GREEN	:= $(shell tput -Txterm setaf 2)
YELLOW	:= $(shell tput -Txterm setaf 3)
WHITE	:= $(shell tput -Txterm setaf 7)
CYAN	:= $(shell tput -Txterm setaf 6)
RESET	:= $(shell tput -Txterm sgr0)

## VARIABLES
APP_NAME = myapplication
APP_REPO = docker.pkg.github.com/bradtho/${APP_NAME}

CHECKSUM = $(shell git rev-parse --short HEAD)
VERSION ?= dev 

## TARGETS
## For Local Use and Testing: Builds the Go Application in the current directory
build-package:
	go build -a -installsuffix cgo -ldflags "-s -w -X main.GitChecksum=${CHECKSUM} -X main.GitVersion=${VERSION}" ./...

## For Local and Pipeline Use and Testing: Packages the Go Application into a Docker Image
build-image:
	docker build --build-arg=${CHECKSUM} --build-arg=${VERSION} -t ${APP_NAME} .

## Cleans the local directory
clean:
	go clean

## For Pipeline Use: Releases the Docker Image
push: 
	docker push ${APP_REPO}/${APP_NAME}:${VERSION}

## For Pipeline Use: Tags the Docker Image
tag:
	docker tag ${APP_NAME} ${APP_REPO}/${APP_NAME}:${VERSION}

## For Local and Pipeline Use: Runs code checks and executes unit tests
test:
	go fmt .
	go vet ./...
	go test -v -coverprofile=cover.txt
	go tool cover -html=cover.txt -o cover.html

## HELP
## Show help
help:
	@echo ''
	@echo ''
	@echo '${CYAN}Usage:${RESET}'
	@echo ''
	@echo '	${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo '${CYAN}Targets:${RESET}'
	@echo ''
	@awk '/(^[a-zA-Z\-\.\_0-9]+:)|(^###[a-zA-Z]+)/ { \
		header = match($$1, /^###(.*)/); \
		if (header) { \
			title = substr($$1, 4, length($$1)); \
			printf "${CYAN}%s${RESET}\n", title; \
		} \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "   ${YELLOW}%-30s${RESET} ${GREEN}%-$(TARGET_MAX_CHAR_NUM)s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
