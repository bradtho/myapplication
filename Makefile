SHELL := /bin/sh
.PHONY: clean

## VARIABLES
APP_NAME = myapplication
APP_REPO = docker.pkg.github.com/bradtho/${APP_NAME}

CHECKSUM = $(shell git rev-parse --short HEAD)
VERSION ?= feat 

## TARGETS
## For Local Use and Testing: Builds the Go Application in the current directory
build-package:
	go build -a -installsuffix cgo -ldflags "-s -w -X main.GitChecksum=$(GIT_CHECKSUM) -X main.GitVersion=$(GIT_VERSION)" ./...
	
## For Local and Pipeline Use and Testing: Packages the Go Application into a Docker Image
build-image:
	docker build --build-arg checksum=${CHECKSUM} --build-arg version=${VERSION} -t ${APP_NAME} .

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
