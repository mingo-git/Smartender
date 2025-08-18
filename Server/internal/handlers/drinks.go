package handlers

import (
	models "app/internal/models"
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

func CreateDrink(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /drinks at %s", time.Now())

	vars := mux.Vars(r)
	hardwareID := vars["hardware_id"]

	var newDrink models.Drink
	err := json.NewDecoder(r.Body).Decode(&newDrink)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Insert new drink into the database
	err = db.QueryRow(query.CreateDrink(), newDrink.Name, newDrink.Alcoholic, hardwareID).Scan(&newDrink.DrinkID)
	if err != nil {
		log.Default().Printf("Error inserting new drink: %v", err)
		http.Error(w, "Could not create drink", http.StatusInternalServerError)
		return
	}

	hardwareIDInt, err := strconv.Atoi(hardwareID)
	if err != nil {
		http.Error(w, "Invalid hardware ID", http.StatusBadRequest)
		return
	}
	newDrink.HardwareID = hardwareIDInt

	// *** ERWEITERT: WebSocket Broadcast mit kompletten Daten ***
	BroadcastDrinkUpdate(db, newDrink.DrinkID, hardwareIDInt, "created")

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	json.NewEncoder(w).Encode(newDrink)
	
	log.Default().Printf("✅ [DRINK] Neues Getränk erstellt: ID %d, Name '%s', Hardware %d", newDrink.DrinkID, newDrink.Name, hardwareIDInt)
}

func GetAllDrinks(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /drinks at %s", time.Now())

	vars := mux.Vars(r)
	hardwareID := vars["hardware_id"]

	var drinks []models.Drink

	rows, err := db.Query(query.GetAllDrinksForHardware(), hardwareID)
	if err != nil {
		log.Default().Printf("Error getting drinks: %v", err)
		http.Error(w, "Could not get drinks", http.StatusInternalServerError)
		return
	}

	defer rows.Close()

	// Iteriere über alle Zeilen
	for rows.Next() {
		var drink models.Drink
		err := rows.Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic)
		if err != nil {
			log.Default().Printf("Error scanning drink: %v", err)
			http.Error(w, "Error processing drinks", http.StatusInternalServerError)
			return
		}
		drinks = append(drinks, drink)
	}

	// Überprüfe auf Fehler nach der Iteration
	if err = rows.Err(); err != nil {
		log.Default().Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing drinks", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK

	// Encode die Liste der Drinks als JSON und sende sie als Antwort
	json.NewEncoder(w).Encode(drinks)
	
	log.Default().Printf("✅ [DRINK] %d Getränke geladen für Hardware %s", len(drinks), hardwareID)
}

func GetSingleDrinkForHardwareByDrinkID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /drinks/{id} at %s", time.Now())

	vars := mux.Vars(r)
	drinkID := vars["drink_id"]
	hardwareID := vars["hardware_id"]

	var drink models.Drink

	err := db.QueryRow(query.GetDrinkByID(), drinkID, hardwareID).Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Default().Printf("Drink not found: ID %s, Hardware %s", drinkID, hardwareID)
			http.Error(w, "Drink not found", http.StatusNotFound)
			return
		}
		log.Default().Printf("Error getting drink: %v", err)
		http.Error(w, "Could not get drink", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(drink)
	
	log.Default().Printf("✅ [DRINK] Getränk geladen: ID %d, Name '%s'", drink.DrinkID, drink.Name)
}

func UpdateDrink(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /drinks/{id} at %s", time.Now())

	vars := mux.Vars(r)
	drinkID := vars["drink_id"]
	hardwareID := vars["hardware_id"]

	var updatedDrink models.Drink
	err := json.NewDecoder(r.Body).Decode(&updatedDrink)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Update drink in the database
	result, err := db.Exec(query.UpdateDrink(), updatedDrink.Name, updatedDrink.Alcoholic, drinkID, hardwareID)
	if err != nil {
		log.Default().Printf("Error updating drink: %v", err)
		http.Error(w, "Could not update drink", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		log.Default().Printf("Drink not found for update: ID %s, Hardware %s", drinkID, hardwareID)
		http.Error(w, "Drink not found", http.StatusNotFound)
		return
	}

	// *** ERWEITERT: WebSocket Broadcast mit kompletten Daten ***
	drinkIDInt, err := strconv.Atoi(drinkID)
	if err != nil {
		log.Default().Printf("Error converting drink ID to int: %v", err)
		// Fallback: sende Update ohne WebSocket
	} else {
		hardwareIDInt, err := strconv.Atoi(hardwareID)
		if err != nil {
			log.Default().Printf("Error converting hardware ID to int: %v", err)
			// Fallback: sende Update ohne WebSocket
		} else {
			BroadcastDrinkUpdate(db, drinkIDInt, hardwareIDInt, "updated")
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
	
	log.Default().Printf("✅ [DRINK] Getränk aktualisiert: ID %s, Name '%s', Hardware %s", drinkID, updatedDrink.Name, hardwareID)
}

func DeleteDrink(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /drinks/{id} at %s", time.Now())

	vars := mux.Vars(r)
	drinkID := vars["drink_id"]
	hardwareID := vars["hardware_id"]

	// Konvertiere IDs für WebSocket-Broadcast (vor dem Löschen)
	drinkIDInt, drinkIDErr := strconv.Atoi(drinkID)
	hardwareIDInt, hardwareIDErr := strconv.Atoi(hardwareID)

	// Delete drink from the database
	result, err := db.Exec(query.DeleteDrink(), drinkID, hardwareID)
	if err != nil {
		log.Default().Printf("Error deleting drink: %v", err)
		http.Error(w, "Could not delete drink", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		log.Default().Printf("Drink not found for deletion: ID %s, Hardware %s", drinkID, hardwareID)
		http.Error(w, "Drink not found", http.StatusNotFound)
		return
	}

	// *** ERWEITERT: WebSocket Broadcast für gelöschtes Getränk ***
	if drinkIDErr == nil && hardwareIDErr == nil {
		BroadcastDrinkUpdate(db, drinkIDInt, hardwareIDInt, "deleted")
	} else {
		log.Default().Printf("Warning: Could not broadcast drink deletion due to ID conversion error")
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Successfully deleted drink",
	})
	
	log.Default().Printf("✅ [DRINK] Getränk gelöscht: ID %s, Hardware %s", drinkID, hardwareID)
}