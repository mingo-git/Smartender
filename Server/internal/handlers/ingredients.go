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

	// *** ERWEITERT: WebSocket Broadcast mit kompletten Daten ***
	BroadcastIngredientUpdate(db, newIngredient.RecipeID, newIngredient.DrinkID, "created")

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	json.NewEncoder(w).Encode(newIngredient)
	
	log.Default().Printf("✅ [INGREDIENT] Neue Zutat erstellt: Recipe %d, Drink %d, Menge %d ml", 
		newIngredient.RecipeID, newIngredient.DrinkID, newIngredient.Quantity_ml)
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
		log.Default().Printf("Ingredient not found for update: Recipe %s, Drink %s", recipeID, drinkID)
		http.Error(w, "Ingredient not found", http.StatusNotFound)
		return
	}

	// *** ERWEITERT: WebSocket Broadcast mit kompletten Daten ***
	recipeIDInt, recipeConvErr := strconv.Atoi(recipeID)
	drinkIDInt, drinkConvErr := strconv.Atoi(drinkID)
	
	if recipeConvErr == nil && drinkConvErr == nil {
		BroadcastIngredientUpdate(db, recipeIDInt, drinkIDInt, "updated")
	} else {
		log.Default().Printf("Warning: Could not broadcast ingredient update due to ID conversion error (Recipe: %s, Drink: %s)", recipeID, drinkID)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
	
	log.Default().Printf("✅ [INGREDIENT] Zutat aktualisiert: Recipe %s, Drink %s, Neue Menge %d ml", 
		recipeID, drinkID, updatedIngredient.Quantity_ml)
}

func DeleteIngredient(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /ingredients/{id} at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	drinkID := vars["drink_id"]

	// Konvertiere IDs für WebSocket-Broadcast (vor dem Löschen)
	recipeIDInt, recipeConvErr := strconv.Atoi(recipeID)
	drinkIDInt, drinkConvErr := strconv.Atoi(drinkID)

	// Delete ingredient from the database
	result, err := db.Exec(query.DeleteIngredient(), recipeID, drinkID)
	if err != nil {
		log.Default().Printf("Error deleting ingredient: %v", err)
		http.Error(w, "Could not delete ingredient", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		log.Default().Printf("Ingredient not found for deletion: Recipe %s, Drink %s", recipeID, drinkID)
		http.Error(w, "Ingredient not found", http.StatusNotFound)
		return
	}

	// *** ERWEITERT: WebSocket Broadcast für gelöschte Zutat ***
	if recipeConvErr == nil && drinkConvErr == nil {
		BroadcastIngredientUpdate(db, recipeIDInt, drinkIDInt, "deleted")
	} else {
		log.Default().Printf("Warning: Could not broadcast ingredient deletion due to ID conversion error (Recipe: %s, Drink: %s)", recipeID, drinkID)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Successfully deleted ingredient",
	})
	
	log.Default().Printf("✅ [INGREDIENT] Zutat gelöscht: Recipe %s, Drink %s", recipeID, drinkID)
}