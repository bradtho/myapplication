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

Branching is intended to be done from `master` into `feat` or `fix` branches. Releases are intended to be done from `master`.

Versioning of releases is managed using git tags and is intended to be in SEMVER format i.e. v1.2.3.

Where builds are untagged branch name is used as the version.

Where builds are tagged, the CI Pipeline will build a Docker image with the tag and push this versioned release to the GitHub image and code respositories.

Version is dynamically hard set at build time so that a misconfigured deployment won't show a different version to what is actually released. This ensures the version running definitely points to the commit that it was compiled from.

The latest Docker image refers to the latest tagged release and not current master.

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

**Release** triggers on detection of new SEMVER tags.

## Unit Testing Code Coverage

Given the complexity of validating coverage against server startup or shutdown, coverage
results will appear lower than typically desired as the VersionHandler() method is all we can easily test against.

## Security Considerations

A number of steps were undertaken to enhance the security of the application:

- Utilising Google's Distroless Docker Image, this image contains a "bare bones" container on which only the essential requirements are built into the image.
- Given that image scanning isn't a simple process without considerable infrastructure the use of Distroless reduces the images Security Footprint.
- The go.mod file manages application dependencies and their versions, these are set on specific git commits through the CI Pipeline's tagging process.

## Dependencies for Local Development

By their nature the application and image have no dependencies, a local developemnt environment would need the following:

- Docker
- Git
- GNU Make
- Go 1.13 or later.

## Local Development

Local development can be handled via the use of the Makefile provided.

For Local Use and Testing: Builds the Go Application in the current directory

```bash
make build-package
```

For Local and Pipeline Use and Testing: Packages the Go Application into a Docker Image

```bash
make build-image
```

For Local and Pipeline Use: Runs code checks and executes unit tests

```bash
make test
```

To bump up to a new release version we tag and push

```bash
git tag v1.2.3 && git push --tags
```

## Deployments

The is run as a Docker image and can be from any system meeting the requirements to run docker.

[To authenticate as a user to the Github Docker Repository](https://help.github.com/en/packages/using-github-packages-with-your-projects-ecosystem/configuring-docker-for-use-with-github-packages#authenticating-with-a-personal-access-token)

```bash
cat ~/TOKEN.txt | docker login https://docker.pkg.github.com -u USERNAME --password-stdin
```

To start the container, run the following:

```bash
docker run -p 8000:8000 docker.pkg.github.com/bradtho/myapplication:latest
```

## Additional Considerations and Notes

A list of items for consideration post Minimal Viable Product addressing risks and productionisation:

- Test coverage indicates <50% of statements are being covered by the Go unit test. Additional unit tests may be introduced to cover items such as startup and shutdown operations i.e. - it is not possible to test the graceful shutdown SIGINT and SIGTERM and be initiated via go tests, could test using a *docker stop*
- Consider vendoring dependencies and hosting specific versions in a non-public code repo.
- golang:alpine is still a 127MB image so should ideally be cached locally
- gcr.io/distroless/static is a 1.82MB image so it is about as small as it will get.
- Final image size is 7.45MB this may be difficult to reduce further.
- Docker is running as privileged user but requires this to gracefully handle a kill signal
- Switching OSes/Architectures may cause Docker runtime issues i.e. - standard_init_linux.go:211: exec user process caused "no such file or directory" error occurs when running the image where GOOS=linux is not set within the Dockerfile.
- Unit testing returns for Negative.
- Utilising test coverage to determine whether the critical logic of the application is being validated is more important than hitting a certain percentage of coverage. The test suite outputs coverage files to assist with this analysis.
- During development GoSec found [/github/workspace/main.go:89] - G104 (CWE-703): Errors unhandled. (Confidence: HIGH, Severity: LOW) this has since been remediated but validates that GoSec is working.
- Branching rules and templates need to be expanded upon to restrict pull requests into `master`.
- Implementation of automated version bumping should be considered to take away any manual handling of version control. i.e. detect on a merge to master with key words within the commit message. This however does still required that the developer remembers to insert said keywords and may be more accustoed to using the `git tag` method in use currently.
- The application has no catch or recovery mechanism. e.g. if the JSON encoder failed then the user would still receive a HTTP 200 status but receive unexpected output.
- Expansion of logging capability should be considered for ease of debugging.
- Scalability of this application hasn't been considered, however implementation into a container orchestrator such as Kubernetes would allow this application to scale exponentially.
