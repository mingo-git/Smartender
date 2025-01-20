package handlers

import (
	models "app/internal/models"
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"
)

func RegisterHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /hardware at %s", time.Now())

	var newCreateHardware models.HardwareCreate
	err := json.NewDecoder(r.Body).Decode(&newCreateHardware)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	var newHardwareID int
	// Insert new hardware into the database
	err = db.QueryRow(query.CreateHardwareForUser(), newCreateHardware.HardwareName, newCreateHardware.MacAddress).Scan(&newHardwareID)
	if err != nil {
		log.Default().Printf("Error inserting new hardware: %v", err)
		http.Error(w, "Could not create hardware", http.StatusInternalServerError)
		return
	}

	_, err = db.Exec(query.CreateUserHardware(), newCreateHardware.UserID, newHardwareID, "admin")
	if err != nil {
		log.Default().Printf("Error inserting new hardware into user_hardware: %v", err)
		http.Error(w, "Could not create hardware into user_hardware", http.StatusInternalServerError)
		return
	}

	var slotAmount uint8 = 11

	for i := 1; i <= int(slotAmount); i++ {
		_, err := db.Exec(query.InitSlotsForHardware(), newHardwareID, i)
		if err != nil {
			log.Default().Printf("Error inserting new slot: %v", err)
			http.Error(w, "Could not create slot", http.StatusInternalServerError)
			return
		}
	}

	json.NewEncoder(w).Encode(map[string]int{
		"hardwareID": newHardwareID,
	})
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
}

func GetAllHardwareForUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /hardware at %s", time.Now())

	userID := r.Context().Value("user_id")

	// Get all hardware for the user
	rows, err := db.Query(query.GetAllHardwareForUser(), userID)
	if err != nil {
		log.Default().Printf("Error getting hardware: %v", err)
		http.Error(w, "Could not get hardware", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Collect all hardware
	var hardware []models.Hardware
	for rows.Next() {
		var h models.Hardware
		if err := rows.Scan(&h.HardwareID, &h.HardwareName, &h.MacAddress, &h.UserID); err != nil {
			log.Default().Printf("Error scanning hardware: %v", err)
			http.Error(w, "Error processing hardware", http.StatusInternalServerError)
			return
		}
		hardware = append(hardware, h)
	}

	json.NewEncoder(w).Encode(hardware)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK
}
