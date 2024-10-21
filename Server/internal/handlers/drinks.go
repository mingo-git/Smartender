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

	var newDrink models.Drink
	err := json.NewDecoder(r.Body).Decode(&newDrink)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	userIDStr, ok := r.Context().Value("user_id").(string)  // Get user ID from context as string
	if !ok {
			http.Error(w, "Invalid user ID", http.StatusBadRequest)
			return
	}
	
	// Convert userID from string to int
	userID, err := strconv.Atoi(userIDStr)
	if err != nil {
			log.Printf("Error converting user ID to int: %v", err)
			http.Error(w, "Invalid user ID format", http.StatusBadRequest)
			return
	}
	
	// Assign the integer userID to newDrink.UserID
	newDrink.UserID = userID

	// Insert new drink into the database
	err = db.QueryRow(query.CreateDrink(), newDrink.Name, newDrink.UserID).Scan(&newDrink.DrinkID)
	if err != nil {
		log.Printf("Error inserting new drink: %v", err)
		http.Error(w, "Could not create drink", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	json.NewEncoder(w).Encode(newDrink)
}

func GetAllDrinks(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /drinks at %s", time.Now())

	var drinks []models.Drink

	rows, err := db.Query(query.GetAllDrinksForUser(), r.Context().Value("user_id"))
	if err != nil {
		log.Printf("Error getting drinks: %v", err)
		http.Error(w, "Could not get drinks", http.StatusInternalServerError)
		return
	}

	defer rows.Close()

	// Iteriere über alle Zeilen
	for rows.Next() {
		var drink models.Drink
		err := rows.Scan(&drink.DrinkID, &drink.Name, &drink.UserID)
		if err != nil {
			log.Printf("Error scanning drink: %v", err)
			http.Error(w, "Error processing drinks", http.StatusInternalServerError)
			return
		}
		drinks = append(drinks, drink)
	}

	// Überprüfe auf Fehler nach der Iteration
	if err = rows.Err(); err != nil {
		log.Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing drinks", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK

	// Encode die Liste der Drinks als JSON und sende sie als Antwort
	json.NewEncoder(w).Encode(drinks)
}

func UpdateDrink(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /drinks/{id} at %s", time.Now())

	vars := mux.Vars(r)
	drinkID := vars["drink_id"]

	var updatedDrink models.Drink
	err := json.NewDecoder(r.Body).Decode(&updatedDrink)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Update drink in the database
	result, err := db.Exec(query.UpdateDrink(), updatedDrink.Name, drinkID)
	if err != nil {
		log.Printf("Error updating drink: %v", err)
		http.Error(w, "Could not update drink", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Drink not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(updatedDrink.DrinkID)
}

func DeleteDrink(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /drinks/{id} at %s", time.Now())

	vars := mux.Vars(r)
	id := vars["drink_id"]

	// Delete drink from the database
	result, err := db.Exec(query.DeleteDrink(), id)
	if err != nil {
		log.Printf("Error deleting drink: %v", err)
		http.Error(w, "Could not delete drink", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Drink not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Successfully deleted drink",
	})
}
