package main

import (
	"log"
	"net"
	"net/http"
	"os"

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

	// creating new loggers, defining log structure
	loggerINF = log.New(os.Stdout, "[INFO] -> ", log.Ldate|log.Ltime|log.Lshortfile)
	loggerFTL = log.New(os.Stdout, "[FATAL] -> ", log.Ldate|log.Ltime|log.Lshortfile)
)

// initializing and registering the Prometheus counter
func init() {
	prometheus.MustRegister(counter)
}

// HTTP request handler that increments the access counter and serves the website content
func handler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path == "/" {
		counter.Inc()
	}
	website.ServeHTTP(w, r)
	loggerINF.Printf("Request served: %s %s | client: %s", r.Method, r.URL.Path, r.RemoteAddr)
}

func main() {
	// Creating a separate router for metrics endpoint
	metricsMux := http.NewServeMux()
	metricsMux.HandleFunc("/metrics", promhttp.Handler().ServeHTTP)

	// Create a listener for metrics endpoint
	metricsMuxListener, err := net.Listen("tcp", ":9200")
	if err != nil {
		loggerFTL.Fatalf("Failed to listen on port 9200 for metrics: %s", err)
	}

	// Ensuring gracefull listener shutdown
	defer metricsMuxListener.Close()

	// Serving metrics endpoint as a separate goroutine
	go func() {
		if err := http.Serve(metricsMuxListener, metricsMux); err != nil {
			loggerFTL.Fatalf("Failed to serve metrics on port 9200: %s", err)
		}
	}()
	loggerINF.Println("Successfully exposed metrics on :9200")

	// Handling root path with the handler function
	http.HandleFunc("/", handler)

	// Starting the HTTP server on port :8080
	loggerINF.Println("Starting server on :8080")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		loggerFTL.Fatalf("Failed to start server: %s", err)
	}
}
