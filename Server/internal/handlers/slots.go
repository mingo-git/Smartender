package handlers

import (
	models "app/internal/models"
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"strconv"
	"time"
	"strings"

	"github.com/gorilla/mux"
)

// InitSlotsForHardware initializes the slots table with the hardware_id and slot_number.
//
// TODO: Somehow receive hardware_id from the Raspberry Pi as well as the slot_amount
func InitSlotsForHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /slots at %s", time.Now())

	var slotAmount uint8 = 5

	for i := 1; i <= int(slotAmount); i++ {
		_, err := db.Exec(query.InitSlotsForHardware(), 1, i)
		if err != nil {
			log.Default().Printf("Error inserting new slot: %v", err)
			http.Error(w, "Could not create slot", http.StatusInternalServerError)
			return
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	
	log.Default().Printf("✅ [SLOT] %d Slots für Hardware 1 initialisiert", slotAmount)
}

// GetAllSlotsForSelectedHardware selects all slots from the slots table
func GetAllSlotsForSelectedHardware(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /slots at %s", time.Now())

	vars := mux.Vars(r)
	hardware_id := vars["hardware_id"]

	// Check, if the user is authorized to access the hardware
	rows, err := db.Query(query.CheckHardwareForUser(), hardware_id, r.Context().Value("user_id"))
	if err != nil {
		log.Default().Printf("Error querying hardware for user: %v", err)
		http.Error(w, "Could not check hardware for user", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	if !rows.Next() {
		log.Default().Printf("Hardware does not belong to user: Hardware %s, User %v", hardware_id, r.Context().Value("user_id"))
		http.Error(w, "Hardware does not belong to user", http.StatusUnauthorized)
		return
	}

    var slotSchemaList []models.SlotSchema
	rows, err = db.Query(query.GetAllSlotsForSelectedHardware(), hardware_id)
	if err != nil {
		log.Default().Printf("Error selecting all slots: %v", err)
		http.Error(w, "Could not get slots", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var slot models.SlotSchema
		if err := rows.Scan(&slot.HardwareID, &slot.SlotNumber, &slot.DrinkID); err != nil {
			log.Default().Printf("Error scanning slot: %v", err)
			http.Error(w, "Could not get slots", http.StatusInternalServerError)
			return
		}
		slotSchemaList = append(slotSchemaList, slot)
	}

    // Compact log of slot mapping will be printed after resolving drinks

	var slotResponseList []models.Slot

	// Prepare compact names array: index = slot_number-1, value = drink name or empty
	maxSlot := 0
	for _, s := range slotSchemaList { if int(s.SlotNumber) > maxSlot { maxSlot = int(s.SlotNumber) } }
	names := make([]string, maxSlot)

	for _, schema := range slotSchemaList {
		drink_id := schema.DrinkID
		var drink models.Drink

		// Prüfen, ob drink_id vorhanden ist
		if !drink_id.Valid {
			slotResponseList = append(slotResponseList, models.Slot{HardwareID: schema.HardwareID, SlotNumber: schema.SlotNumber, Drink: nil})
			if int(schema.SlotNumber) <= len(names) { names[int(schema.SlotNumber)-1] = "" }
			continue
		}

		row := db.QueryRow(query.GetDrinkByID(), drink_id.Int64, hardware_id)
		if err := row.Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic); err != nil {
			if err == sql.ErrNoRows {
				log.Default().Printf("No drink found for drink_id: %v (slot %d)", drink_id.Int64, schema.SlotNumber)
				continue
			}
			log.Default().Printf("Error scanning drink: %v", err)
			http.Error(w, "Could not get drink", http.StatusInternalServerError)
			return
		}
		if int(schema.SlotNumber) <= len(names) { names[int(schema.SlotNumber)-1] = drink.Name }
		slotResponseList = append(slotResponseList, models.Slot{HardwareID: schema.HardwareID, SlotNumber: schema.SlotNumber, Drink: &drink})
	}

	// Compact, single-line mapping log: e.g., "Vodka, , Rum, , Tequila, , , , , ,"
	if len(names) > 0 {
		log.Default().Printf("🍹 [SLOTS MAP] %s", strings.Join(names, ", "))
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(slotResponseList)
	
	log.Default().Printf("✅ [SLOT] %d Slots geladen für Hardware %s", len(slotResponseList), hardware_id)
}

func SetSlotForHardwareAndID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /slots at %s", time.Now())

	vars := mux.Vars(r)
	slotNumber := vars["slot_number"]
	hardware_id := vars["hardware_id"]

	// Check, if the user is authorized to access the hardware
	rows, err := db.Query(query.CheckHardwareForUser(), hardware_id, r.Context().Value("user_id"))
	if err != nil {
		log.Default().Printf("Error querying hardware for user: %v", err)
		http.Error(w, "Could not check hardware for user", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	if !rows.Next() {
		log.Default().Printf("Hardware does not belong to user: Hardware %s, User %v", hardware_id, r.Context().Value("user_id"))
		http.Error(w, "Hardware does not belong to user", http.StatusUnauthorized)
		return
	}

	// Peek into the body to check if it's empty
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		log.Default().Printf("Error reading body: %v", err)
		http.Error(w, "Could not read request body", http.StatusInternalServerError)
		return
	}

	// *** ERWEITERT: WebSocket Broadcast Variablen vorbereiten ***
	slotNumberInt, slotConvErr := strconv.Atoi(slotNumber)
	hardwareIDInt, hwConvErr := strconv.Atoi(hardware_id)

	if len(bodyBytes) == 0 {
		// If body is empty, clear the slot
		_, err := db.Exec(query.ClearSlotForHardwareAndID(), hardware_id, slotNumber)
		if err != nil {
			log.Default().Printf("Error clearing slot: %v", err)
			http.Error(w, "Could not clear slot", http.StatusInternalServerError)
			return
		}

		// *** ERWEITERT: WebSocket Broadcast für Slot Clear mit kompletten Daten ***
		if slotConvErr == nil && hwConvErr == nil {
			BroadcastSlotUpdate(db, slotNumberInt, hardwareIDInt, nil)
		} else {
			log.Default().Printf("Warning: Could not broadcast slot clear due to ID conversion error")
		}

		log.Default().Printf("✅ [SLOT] Slot geleert: Slot %s, Hardware %s", slotNumber, hardware_id)

	} else {
		// If body is not empty, decode it and update the slot
		var slot models.SlotUpdate
		err := json.Unmarshal(bodyBytes, &slot)
		if err != nil {
			log.Default().Printf("Error decoding slot: %v", err)
			http.Error(w, "Could not decode slot", http.StatusBadRequest)
			return
		}
		
		_, err = db.Exec(query.SetSlotForHardwareAndID(), slot.DrinkID, hardware_id, slotNumber)
		if err != nil {
			log.Default().Printf("Error setting slot: %v", err)
			http.Error(w, "Could not set slot", http.StatusInternalServerError)
			return
		}

		// *** ERWEITERT: WebSocket Broadcast für Slot Update mit kompletten Daten ***
		if slotConvErr == nil && hwConvErr == nil {
			BroadcastSlotUpdate(db, slotNumberInt, hardwareIDInt, slot.DrinkID)
		} else {
			log.Default().Printf("Warning: Could not broadcast slot update due to ID conversion error")
		}

		// Log mit Drink-Details
		if slot.DrinkID != nil {
			log.Default().Printf("✅ [SLOT] Slot belegt: Slot %s, Hardware %s, Drink ID %d", slotNumber, hardware_id, *slot.DrinkID)
		} else {
			log.Default().Printf("✅ [SLOT] Slot aktualisiert: Slot %s, Hardware %s, Drink ID nil", slotNumber, hardware_id)
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
}
