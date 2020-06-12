SHELL := /bin/sh
.PHONY: clean

## VARIABLES
APP_NAME = myapplication
APP_REPO = docker.pkg.github.com/bradtho/${APP_NAME}

CHECKSUM = $(shell git rev-parse --short HEAD)
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
	docker push ${APP_REPO}/${APP_REPO}:${VERSION}

tag:
	docker tag ${APP_NAME} ${APP_REPO}/${APP_NAME}:${VERSION}

test:
	go vet ./...
	go test -v -coverprofile=cover.txt
	go tool cover -html=cover.txt -o cover.html
