package handlers

import (
	models "app/internal/models"
	query "app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func CreateRecipe(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /recipes at %s", time.Now())

	var newRecipe models.Recipe
	err := json.NewDecoder(r.Body).Decode(&newRecipe)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Insert new recipe into the database
	err = db.QueryRow(query.CreateRecipeForUser(), r.Context().Value("user_id"), newRecipe.Name).Scan(&newRecipe.ID)
	if err != nil {
		log.Printf("Error inserting new recipe: %v", err)
		http.Error(w, "Could not create recipe", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
}

func GetAllRecipes(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /recipes at %s", time.Now())

	var recipes []models.Recipe
	rows, err := db.Query(query.GetAllRecipesForUser(), r.Context().Value("user_id"))
	if err != nil {
		log.Printf("Error getting recipes: %v", err)
		http.Error(w, "Could not get recipes", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Iteriere über alle Zeilen
	for rows.Next() {
		var recipe models.Recipe
		var drinkIDs []uint8 // IDs der Drinks für das Rezept
		err := rows.Scan(&recipe.ID, &recipe.UserID, &recipe.Name, &drinkIDs)
		if err != nil {
			log.Printf("Error scanning recipe: %v", err)
			http.Error(w, "Error processing recipes", http.StatusInternalServerError)
			return
		}

		// Erstelle das DrinkDetails-Array für das aktuelle Rezept
		var drinkDetails []models.Drink = make([]models.Drink, 0)
		for _, drinkID := range drinkIDs {
			var drink models.Drink
			// Abfrage ausführen, um jedes Getränk-Objekt anhand der drink_id und user_id abzurufen
			drinkRow := db.QueryRow(query.GetDrinkByID(), drinkID, recipe.UserID)
			if err := drinkRow.Scan(&drink.DrinkID, &drink.Name, &drink.UserID, &drink.Alcoholic); err != nil {
				log.Printf("Error getting drink details for drink_id %d: %v", drinkID, err)
				continue // Falls ein Fehler auftritt, überspringe diesen Drink
			}
			// Füge das Getränk-Objekt zur Liste hinzu
			drinkDetails = append(drinkDetails, drink)
		}
		recipe.DrinkDetails = drinkDetails // Setze die Drink-Details für das Rezept
		recipes = append(recipes, recipe)
	}

	// Überprüfe auf Fehler nach der Iteration
	if err = rows.Err(); err != nil {
		log.Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing recipes", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Encode die Liste der Recipes als JSON und sende sie als Antwort
	json.NewEncoder(w).Encode(recipes)
}

func GetRecipeByID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /recipes/{id} at %s", time.Now())

	vars := mux.Vars(r)
	id := vars["recipe_id"]

	var recipe models.Recipe
	var drinkIDsJSON []byte // JSON-Daten für die Drink-IDs

	// Datenbankabfrage ausführen und drinkIDs als []byte holen
	err := db.QueryRow(query.GetRecipeByID(), id, r.Context().Value("user_id")).Scan(&recipe.ID, &recipe.UserID, &recipe.Name, &drinkIDsJSON)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Recipe not found", http.StatusNotFound)
			return
		}
		log.Printf("Error getting recipe: %v", err)
		http.Error(w, "Could not get recipe", http.StatusInternalServerError)
		return
	}

	// Unmarshale JSON-Array von Drink-IDs in []int
	var drinkIDs []int
	if err := json.Unmarshal(drinkIDsJSON, &drinkIDs); err != nil {
		log.Printf("Error unmarshaling drink IDs: %v", err)
		log.Printf("Drink IDs JSON: %s", drinkIDsJSON) // Debugging-Ausgabe
		http.Error(w, "Error processing recipe drink IDs", http.StatusInternalServerError)
		return
	}

	// Erstelle das DrinkDetails-Array für das aktuelle Rezept
	var drinkDetails []models.Drink
	for _, drinkID := range drinkIDs {
		log.Default().Printf("____Drink ID: %d", drinkID)
		var drink models.Drink
		// Abfrage ausführen, um jedes Getränk-Objekt anhand der drink_id und user_id abzurufen
		drinkRow := db.QueryRow(query.GetDrinkByID(), drinkID, recipe.UserID)
		if err := drinkRow.Scan(&drink.DrinkID, &drink.Name, &drink.UserID, &drink.Alcoholic); err != nil {
			log.Printf("Error getting drink details for drink_id %d: %v", drinkID, err)
			continue // Falls ein Fehler auftritt, überspringe diesen Drink
		}
		// Füge das Getränk-Objekt zur Liste hinzu
		drinkDetails = append(drinkDetails, drink)
	}
	recipe.DrinkDetails = drinkDetails // Setze die Drink-Details für das Rezept

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	// Encode das Recipe-Objekt als JSON und sende es als Antwort
	json.NewEncoder(w).Encode(recipe)
}

func UpdateRecipeName(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /recipes/{id} at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]

	var updatedRecipe models.Recipe
	err := json.NewDecoder(r.Body).Decode(&updatedRecipe)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Update recipe in the database
	result, err := db.Exec(query.UpdateRecipeForUser(), updatedRecipe.Name, recipeID, r.Context().Value("user_id"))
	if err != nil {
		log.Printf("Error updating recipe: %v", err)
		http.Error(w, "Could not update recipe", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Recipe not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusNoContent) // 204 No Content
}

func DeleteRecipe(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /recipes/{id} at %s", time.Now())

	vars := mux.Vars(r)
	id := vars["recipe_id"]

	// Delete recipe from the database
	result, err := db.Exec(query.DeleteRecipeForUser(), id, r.Context().Value("user_id"))
	if err != nil {
		log.Printf("Error deleting recipe: %v", err)
		http.Error(w, "Could not delete recipe", http.StatusInternalServerError)
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		http.Error(w, "Recipe not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"message": "Successfully deleted recipe",
	})
}
