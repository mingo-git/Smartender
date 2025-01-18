package handlers

import (
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func CreateFavorite(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /favorites at %s", time.Now())

	userID := r.Context().Value("user_id")

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]

	hasHardware := false

	// Check if the user has the right hardware for the recipe
	err := db.QueryRow(query.CheckRecipeForHardwareForUser(), userID, recipeID).Scan(&hasHardware)

	if err != nil {
		log.Default().Printf("Error checking hardware for user: %v", err)
		http.Error(w, "Could not check hardware for user", http.StatusInternalServerError)
		return
	}

	if !hasHardware {
		http.Error(w, "User does not have the required hardware for this recipe", http.StatusForbidden)
		return
	}

	// Insert new favorite into the database
	_, err = db.Exec(query.CreateFavorite(), userID, recipeID)
	if err != nil {
		log.Default().Printf("Error inserting new favorite: %v", err)
		http.Error(w, "Could not create favorite", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
}

func DeleteFavorite(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /favorites at %s", time.Now())

	userID := r.Context().Value("user_id")

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]

	// Delete favorite from the database
	_, err := db.Exec(query.DeleteFavorite(), userID, recipeID)
	if err != nil {
		log.Default().Printf("Error deleting favorite: %v", err)
		http.Error(w, "Could not delete favorite", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK
}

func GetAllFavoritesForUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /favorites at %s", time.Now())

	userID := r.Context().Value("user_id")

	var favorites []int

	rows, err := db.Query(query.GetAllFavoritesForUser(), userID)
	if err != nil {
		log.Default().Printf("Error getting favorites: %v", err)
		http.Error(w, "Could not get favorites", http.StatusInternalServerError)
		return
	}

	defer rows.Close()

	// Iterate over all rows
	for rows.Next() {
		var favorite int
		err := rows.Scan(&favorite)
		if err != nil {
			log.Default().Printf("Error scanning favorite: %v", err)
			http.Error(w, "Error processing favorites", http.StatusInternalServerError)
			return
		}
		favorites = append(favorites, favorite)
	}

	// Check for errors after iteration
	if err = rows.Err(); err != nil {
		log.Default().Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing favorites", http.StatusInternalServerError)
		return
	}

	json.NewEncoder(w).Encode(favorites)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK
}
