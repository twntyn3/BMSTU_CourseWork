package main

import (
	"log"
	"net/http"
	"time"
)

func main() {
	cfg := loadConfig()

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.Dir("./static")))
	mux.HandleFunc("/ws", wsHandler(cfg))

	srv := &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           mux,
		ReadHeaderTimeout: 10 * time.Second,
	}

	log.Printf("HTTP listening on %s", cfg.HTTPAddr)
	log.Printf("SSH target: %s:%d (user=%s)", cfg.SSHHost, cfg.SSHPort, cfg.SSHUser)

	log.Fatal(srv.ListenAndServe())
}
