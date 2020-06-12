package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/julienschmidt/httprouter"
)

func TestVersionHandler(t *testing.T) {
	router := httprouter.New()
	router.GET("/version", VersionHandler)

	req, err := http.NewRequest("GET", "/version", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	router.ServeHTTP(rr, req)

	// Check the status code is what we expect.
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("Returned unexpected status code: \n\tgot %v \n\texpected %v",
			status, http.StatusOK)
	} else {
		t.Logf("Returned expected status code: \n\tgot %v \n\texpected %v",
			status, http.StatusOK)
	}

	// Check the body is what we expect.
	expected := `{"myapplication":[{"version":"dev","lastcommitsha":"xyz7890","description":"pre-interview technical test"}]}`
	if strings.TrimRight(rr.Body.String(), "\n") != expected {
		t.Errorf("Returned unexpected body: \n\tgot %v \n\texpected %v",
			rr.Body.String(), expected)
	} else {
		t.Logf("Returned expected body: \n\tgot %v \n\texpected %v",
			rr.Body.String(), expected)
	}
}
