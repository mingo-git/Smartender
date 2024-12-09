package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

func GetRoot(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]bool{"ok": true})
	log.Default().Printf("📬 [GET] / at %s", time.Now())
}

func GetDatetime(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode("" + time.Now().Local().Format(time.RFC3339Nano))
}

func GetStatus(w http.ResponseWriter, r *http.Request) {

	type Health struct {
		DB     string `json:"db"`
		Device string `json:"device"`
		Self   string `json:"self"`
	}

	status := Health{"Connected", "Offline", "Running"}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func RegisterDevice(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode("Register Device")
}

func Login(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode("Login")
}
