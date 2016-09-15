package main

import (
	"log"
	"net/http"
	"net/http/httputil"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		director := func(req *http.Request) {
			p := req.Header.Get("X-Port")
			if p == "" {
				p = "5051"
			}
			h := req.Header.Get("X-Agent") + ":" + p
			req = r
			req.URL.Scheme = "http"
			req.URL.Host = h
		}
		proxy := &httputil.ReverseProxy{Director: director}
		proxy.ServeHTTP(w, r)
	})
	log.Fatal(http.ListenAndServe("0.0.0.0:8181", nil))
}
