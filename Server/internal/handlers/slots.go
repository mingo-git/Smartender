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

// InitSlotsForHardware initializes the slots table with the hardware_id and slot_number.
//
// TODO: Somehow receive hardware_id from the Raspberry Pi as well as the slot_amount
func InitSlotsForHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /slots at %s", time.Now())

	var slotAmount uint8 = 6

	for i := 0; i < int(slotAmount); i++ {
		_, err := db.Exec(query.InitSlotsForHardware(), 1, i)
		if err != nil {
			log.Printf("Error inserting new slot: %v", err)
			http.Error(w, "Could not create slot", http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
}

// GetAllSlotsForSelectedHardware selects all slots from the slots table
func GetAllSlotsForSelectedHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /slots at %s", time.Now())

	// TODO: Hardware ID should be dnamically set
	hardware_id := 1

	var slotSchemaList []models.SlotSchema
	rows, err := db.Query(query.GetAllSlotsForSelectedHardware(), hardware_id)
	if err != nil {
		log.Printf("Error selecting all slots: %v", err)
		http.Error(w, "Could not get slots", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var slot models.SlotSchema
		if err := rows.Scan(&slot.HardwareID, &slot.SlotNumber, &slot.DrinkID); err != nil {
			log.Printf("Error scanning slot: %v", err)
			http.Error(w, "Could not get slots", http.StatusInternalServerError)
			return
		}
		slotSchemaList = append(slotSchemaList, slot)
	}

	log.Default().Printf("Slots: %v", slotSchemaList)

	for _, schema := range slotSchemaList {
		drink_id := schema.DrinkID
		var drink models.Drink

		// Prüfen, ob drink_id vorhanden ist
		if drink_id == 0 {
			log.Printf("No drink assigned to slot: %v", schema.SlotNumber)
			continue
		}

		log.Default().Printf("Drink ID: %v", drink_id)
		log.Default().Printf("User ID: %v", r.Context().Value("user_id"))

		row := db.QueryRow(query.GetDrinkByID(), drink_id, r.Context().Value("user_id"))
		if err := row.Scan(&drink.DrinkID, &drink.UserID, &drink.Name, &drink.Alcoholic); err != nil {
			if err == sql.ErrNoRows {
				log.Printf("No drink found for drink_id: %v", drink_id)
				log.Default().Printf("Error: %v", err)
				continue
			}
			log.Printf("Error scanning drink: %v", err)
			http.Error(w, "Could not get drink", http.StatusInternalServerError)
			return
		}
		log.Default().Printf("Drink: %v", drink)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(slotSchemaList)
}

func SetSlotForHardwareAndID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /slots at %s", time.Now())

	var slot models.SlotSchema
	err := json.NewDecoder(r.Body).Decode(&slot)
	if err != nil {
		log.Printf("Error decoding slot: %v", err)
		http.Error(w, "Could not decode slot", http.StatusBadRequest)
		return
	}

	_, err = db.Exec(query.SetSlotForHardwareAndID(), slot.DrinkID, slot.HardwareID, slot.SlotNumber)
	if err != nil {
		log.Printf("Error setting slot: %v", err)
		http.Error(w, "Could not set slot", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
}
