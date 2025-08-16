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

func CreateIngredient(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /ingredients at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]

	var newIngredient models.Ingredient
	err := json.NewDecoder(r.Body).Decode(&newIngredient)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}
	recipeIDInt, err := strconv.Atoi(recipeID)
	if err != nil {
		http.Error(w, "Invalid recipe ID", http.StatusBadRequest)
		return
	}
	newIngredient.RecipeID = recipeIDInt

	// Insert new ingredient into the database
	err = db.QueryRow(query.CreateIngredient(), newIngredient.RecipeID, newIngredient.DrinkID, newIngredient.Quantity_ml).Scan(&newIngredient.RecipeID)
	if err != nil {
		log.Default().Printf("Error inserting new ingredient: %v", err)
		http.Error(w, "Could not create ingredient", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
}

func UpdateIngredient(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /ingredients/{id} at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	drinkID := vars["drink_id"]

	var updatedIngredient models.Ingredient
	err := json.NewDecoder(r.Body).Decode(&updatedIngredient)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Update ingredient in the database
	result, err := db.Exec(query.UpdateIngredient(), recipeID, drinkID, updatedIngredient.Quantity_ml)
	if err != nil {
		log.Default().Printf("Error updating ingredient: %v", err)
		http.Error(w, "Could not update ingredient", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Ingredient not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
}

func DeleteIngredient(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /ingredients/{id} at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	drinkID := vars["drink_id"]

	// Delete ingredient from the database
	result, err := db.Exec(query.DeleteIngredient(), recipeID, drinkID)
	if err != nil {
		log.Default().Printf("Error deleting ingredient: %v", err)
		http.Error(w, "Could not delete ingredient", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Ingredient not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Successfully deleted ingredient",
	})
}
