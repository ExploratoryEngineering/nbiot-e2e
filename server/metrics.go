package main

import (
	"log"
	"net/http"

	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func newMetricsServer() {
	log.SetFlags(log.Llongfile | log.Ltime)

	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.Handler())

	srv := &http.Server{
		Addr:    ":2112",
		Handler: mux,
	}

	log.Println("Serving metrics on port 2112.")
	go func() {
		if err := srv.ListenAndServe(); err != http.ErrServerClosed {
			log.Fatalln(err, "listen and serve")
		}
	}()
}
