# myapplication

is a basic microservice written in Go exposing an API which returns a simple set of values.

![Build and Test](https://github.com/bradtho/myapplication/workflows/Build%20and%20Test/badge.svg) ![Deploy and Release](https://github.com/bradtho/myapplication/workflows/Deploy%20and%20Release/badge.svg)

## The API

When a GET request is sent to the /version endpoint the API returns the
release version, git commit hash and API description in JSON format with
the following schema

```json
"myapplication": [{
  "version": "v1.0.0",
  "lastcommitsha": "xyz7890",
  "description" : "pre-interview technical test"
}]
```

## Branching and Versioning Strategy

Versioning is managed by git tags. On an untagged build, the version dev is used. Tagged builds push a Docker image and versioned release to the GitHub image and source respositories.

The version is dynamically hard set at build time so that a misconfigured deployment won't show a different version to what is actually released. This ensures the version running definitely points to the commit that it was compiled from. The latest Docker image refers to the latest tagged release and not current master.

## CI Pipeline

The Continuous Integration Pipeline is handled by GitHub Actions, configurations for which are located in the `.github/workflows/` directory.

The pipeline has been split into two distinct phases **Build and Test** and **Release**.

**Build and Test** effectively tests that the image will:

- Build correctly with the provided `Dockerfile`
- Compile correctly the provided `main.go`
- Pass CWE checks using [gosec](https://github.com/securego/gosec)
- Ensures good code formatting with `make test`
- Pass unit tests as defined in `main_test.go` and run from `make test`

**Build and Test** is triggered on any `push` or `pull_request` including to intended for **Release**.

**Release** as its name implies:

- Builds and Compiles the provided `main.go` and `Dockerfile`.
- Uses git tags to tag the subsequent Docker image.
- Pushes the Docker image to the GitHub Docker registry.

**Release** truiggers on new tags along with building the Docker image before deploying to the GitHub Docker registry.

## Code Coverage
Type definitions generally don't show up in Go code coverage. It's generally impractical to validate coverage against things like the server being able to start, so the only meaningful coverage is the Version() method for rendering a response to API requests.

## Security
Dependencies are pinned to exact git commits, either from an approved HEAD, or specific upstream version tag. Only known and explicit dependency versions are installed. The base Docker image used is Distroless, an image maintained by Google with only the bare essentials present and mostly updated to handle patching relevant CVEs. While scanning the Docker image with a tool such as CoreOS Clair is a good idea, it requires a reasonable amount of infrastructure and isn't available as a SaaS service.

Dependencies
While the code itself has no user-installed dependencies, the build environment requires the following:

Docker
Git
GNU Make
A development environment additionally needs Go 1.13 or later.

Developing
To build, make build will suffice. There is also make test to run just the tests.

To release a new version, git tags are used, for example:

git tag v1.0 && git push --tags
Productionisation and Risks
The app as currently built has no graceful error handling or even shutdown. Terminating the app will simply drop any ongoing connections. A proper cancel context would solve this. Additionally, some signal handling to instruct the app to shutdown would be advisable.

As far as application error handling goes, there is no proper catch or recovery. If the JSON encoder errors, the user would currently receive an HTTP 200 status and unexpected output. Proper error catching should be added, for both logging and presenting the API consumer with information they can use to debug.

The built Docker image is also running as privileged user, however if it isn't, then it wouldn't be able to receive signals on PID 0. For this reason, the Distroless base image is used rather than Scratch.

Deployments
The app is simply a Docker image and can be run in any Docker-capable environment. To start a container, run the following:

docker run -p 8000:8000 docker.pkg.github.com/hatt/anz-test-2/anz-test-2:latest

## Additional Considerations

- go test coverage indicates only 50% of statements are being covered by the test.
- consider vendoring dependencies and hosting specific versions in a non-public code repo.
- golang:alpine is still a 127MB image so should ideally be cached locally
- image size is 7.47MB
- switching OSes/Architectures may cause Docker runtime issues
- unit testing returns for both positive and negative
- utilising test coverage to determine whether the critical logic of the application is being validated
- not possible to test the graceful shutdown SIGINT and SIGTERM and be initiated via go tests, could test using a *docker stop*
- GoSec found [/github/workspace/main.go:89] - G104 (CWE-703): Errors unhandled. (Confidence: HIGH, Severity: LOW)
