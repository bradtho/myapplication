SHELL := /bin/sh
.PHONY: clean

## VARIABLES
APP_NAME = myapplication
APP_REPO = docker.pkg.github.com/bradtho/$(APP_NAME)/$(APP_NAME)

CHECKSUM = $(git rev-parse --short HEAD)
VERSION ?= dev

## TARGETS
build-package:
	go build -a -installsuffix cgo -ldflags "-s -w -X main.GitChecksum=${CHECKSUM} -X main.GitVersion=${VERSION}" ./...

build-image:
	docker build -t ${APP_NAME} .

clean:
	go clean

init:
	go mod download

push: 
	docker push ${APP_NAME}:${VERSION}

tag:
	docker tag ${APP_NAME} ${APP_REPO}:${VERSION}

test:
	go vet ./...
	go test -v -coverprofile=cover.txt
	go tool cover -html=cover.txt -o cover.html