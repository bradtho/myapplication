# myapplication

A basic HTTP API

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
