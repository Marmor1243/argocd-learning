package main

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = prometheus.NewCounter(
		prometheus.CounterOpts{
			Name: "myapp_http_requests_total",
			Help: "Total number of HTTP requests",
		},
	)
)

func init() {
	// Register metric with Prometheus
	prometheus.MustRegister(httpRequestsTotal)
}

func handler(w http.ResponseWriter, r *http.Request) {
	httpRequestsTotal.Inc() // increment by 1
	w.Write([]byte("Hello, Prometheus!"))
}

func main() {
	http.Handle("/metrics", promhttp.Handler()) // Prometheus endpoint
	http.HandleFunc("/", handler)

	http.ListenAndServe(":8080", nil)
}
