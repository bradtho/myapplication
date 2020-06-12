package main

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/julienschmidt/httprouter"
)

// Wrapper nests the JSON constructed in Info.
type Wrapper struct {
	App []Info `json:"myapplication"`
}

// Info constructs application version, commit SHA and description data
// in JSON format in order specified.
type Info struct {
	Version       string `json:"version"`
	Lastcommitsha string `json:"lastcommitsha"`
	Description   string `json:"description"`
}

func main() {
	router := httprouter.New()
	router.GET("/version", VersionHandler)

	srv := &http.Server{
		Handler:      router,
		Addr:         "0.0.0.0:8080",
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	//Start Server
	go func() {
		log.Println("Starting HTTP server on port 8080")
		err := srv.ListenAndServe()
		if err != nil {
			log.Fatal(err)
		}
	}()

	//Graceful Shutdown
	GracefulShutdown(srv)

}

// VersionHandler returns the application version information.
func VersionHandler(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {

	// Default variables used for testing
	var Checksum = "xyz7890"
	var Version = "dev"

	info := Info{
		Version:       Version,
		Lastcommitsha: Checksum,
		Description:   "pre-interview technical test",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	p := Wrapper{App: []Info{info}}

	err := json.NewEncoder(w).Encode(p)
	if err != nil {
		log.Fatal(err)
	}
}

// GracefulShutdown shuts down the http server gracefully.
func GracefulShutdown(srv *http.Server) {
	interruptChan := make(chan os.Signal, 1)
	signal.Notify(interruptChan, os.Interrupt, syscall.SIGINT, syscall.SIGTERM)

	// Block until we receive our signal.
	<-interruptChan

	// Create a deadline to wait for.
	ctx, cancel := context.WithTimeout(context.Background(), time.Second*10)
	defer cancel()
	srv.Shutdown(ctx)

	log.Println("Shutting down HTTP server")
	os.Exit(0)
}
