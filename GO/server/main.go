package main

import (
	"fmt"
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	// Prometheus counter that tracks website access count.
	counter = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "website_access_count",
		Help: "Total number of times the website has been accessed",
	})

	// serving website files from the "./web" directory
	website = http.FileServer(http.Dir("./web"))
)

// initializing and registering the Prometheus counter
func init() {
	prometheus.MustRegister(counter)
}

// HTTP request handler that increments the access counter and serves the website content
func handler(w http.ResponseWriter, r *http.Request) {
	counter.Inc()
	website.ServeHTTP(w, r)
	fmt.Println("Site accessed")
}

func main() {
	// Handling root path with the handler function
	http.HandleFunc("/", handler)

	// Exposing metrics endpoint for Prometheus
	http.Handle("/metrics", promhttp.Handler())

	// Starting the HTTP server on port :8080
	fmt.Println("Server started on :8080")
	http.ListenAndServe(":8080", nil)
}
