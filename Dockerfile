FROM golang:1.13.12-alpine AS build

ENV GO111MODULE=on

WORKDIR /app

COPY go.mod go.sum ./

RUN apk update --no-cache && \
    apk add git make && \
    rm -rf /var/cache/apk/*

COPY . .

ARG checksum
ARG version

ENV GIT_CHECKSUM=${checksum}
ENV GIT_VERSION=${version}

RUN CGO_ENABLED=0 GOOS=linux make build-package

# RUNTIME STAGE
#FROM gcr.io/distroless/static

#COPY --from=build /app/myapplication /app/myapplication

EXPOSE 8080

ENTRYPOINT [ "/app/myapplication" ]
