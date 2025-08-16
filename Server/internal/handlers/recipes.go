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

func CreateRecipe(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /recipes at %s", time.Now())

	vars := mux.Vars(r)
	hardwareID := vars["hardware_id"]

	var newRecipe models.Recipe
	err := json.NewDecoder(r.Body).Decode(&newRecipe)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Insert new recipe into the database
	err = db.QueryRow(query.CreateRecipeForHardware(), hardwareID, newRecipe.Name, newRecipe.Picture).Scan(&newRecipe.ID)
	if err != nil {
		log.Default().Printf("Error inserting new recipe: %v", err)
		http.Error(w, "Could not create recipe", http.StatusInternalServerError)
		return
	}
	hardwareIDInt, err := strconv.Atoi(hardwareID)
	if err != nil {
		http.Error(w, "Invalid hardware ID", http.StatusBadRequest)
		return
	}
	newRecipe.HardwareID = hardwareIDInt

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created
	json.NewEncoder(w).Encode(newRecipe)
}

func GetAllRecipes(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /recipes at %s", time.Now())

	vars := mux.Vars(r)
	hardwareID := vars["hardware_id"]

	mappedRecipes := map[string][]models.Recipe_Response{}
	mappedRecipes["available"] = []models.Recipe_Response{}
	mappedRecipes["unavailable"] = []models.Recipe_Response{}

	drinkIDsInSlot := getSlots(db, w, hardwareID)

	// Get all recipe ids for the hardware
	rows, err := db.Query(query.GetAllRecipesForHardware(), hardwareID)
	if err != nil {
		log.Default().Printf("Error getting recipes: %v", err)
		http.Error(w, "Could not get recipes", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Collect all recipe ids
	var recipeIDs []int
	for rows.Next() {
		var recipeID int
		if err := rows.Scan(&recipeID); err != nil {
			log.Default().Printf("Error scanning recipe: %v", err)
			http.Error(w, "Error processing recipes", http.StatusInternalServerError)
			return
		}
		recipeIDs = append(recipeIDs, recipeID)
	}

	// Error check after iteration
	if err = rows.Err(); err != nil {
		log.Default().Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing recipes", http.StatusInternalServerError)
		return
	}

	// Get all ingredients for each recipe
	for _, recipeID := range recipeIDs {
		// Get recipe details
		var recipe models.Recipe
		var drinkIDsJSON []byte
		if err := db.QueryRow(query.GetRecipeByID(), recipeID, hardwareID).Scan(&recipe.ID, &recipe.HardwareID, &recipe.Name, &recipe.Picture, &drinkIDsJSON); err != nil {
			log.Default().Printf("Error getting recipe: %v", err)
			continue
		}

		// Get ingredients for the recipe
		rows, err := db.Query(query.GetIngredientsForRecipe(), recipe.ID)
		if err != nil {
			log.Default().Printf("Error getting ingredients for recipe: %v", err)
			continue
		}
		defer rows.Close()

		// Collect ingredients and drink details
		var ingredientsAll []models.IngredientResponse
		for rows.Next() {
			var ingredient models.Ingredient
			if err := rows.Scan(&ingredient.RecipeID, &ingredient.DrinkID, &ingredient.Quantity_ml); err != nil {
				log.Default().Printf("Error scanning ingredient: %v", err)
				http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
				return
			}

			// Get drink details
			var drink models.Drink
			if err := db.QueryRow(query.GetDrinkByID(), ingredient.DrinkID, recipe.HardwareID).Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic); err != nil {
				log.Default().Printf("Error getting drink details for drink_id %d: %v", ingredient.DrinkID, err)
				continue
			}

			// Combine ingredient and drink
			ingredientsAll = append(ingredientsAll, models.IngredientResponse{
				Quantity_ml: ingredient.Quantity_ml,
				Drink:       drink,
			})
		}

		// Error check after iteration
		if err = rows.Err(); err != nil {
			log.Default().Printf("Error after iterating rows: %v", err)
			http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
			return
		}

		if len(ingredientsAll) == 0 {
			ingredientsAll = []models.IngredientResponse{}
		}

		// Create structured response
		recipeResponse := models.Recipe_Response{
			ID:          recipe.ID,
			HardwareID:  recipe.HardwareID,
			Name:        recipe.Name,
			Picture:     recipe.Picture,
			Ingredients: ingredientsAll,
		}

		if isRecipeAvailable(recipeResponse, drinkIDsInSlot) {
			mappedRecipes["available"] = append(mappedRecipes["available"], recipeResponse)
		} else {
			mappedRecipes["unavailable"] = append(mappedRecipes["unavailable"], recipeResponse)
		}

	}

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(mappedRecipes)
}

func GetRecipeByID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /recipes/{id} at %s", time.Now())

	// Routen-Variablen extrahieren
	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	hardwareID := vars["hardware_id"]

	drinkIDsInSlot := getSlots(db, w, hardwareID)

	mappedRecipes := map[string][]models.Recipe_Response{}
	mappedRecipes["available"] = []models.Recipe_Response{}
	mappedRecipes["unavailable"] = []models.Recipe_Response{}

	// Haupt-Rezeptdaten abrufen
	var recipe models.Recipe
	var drinkIDsJSON []byte
	if err := db.QueryRow(query.GetRecipeByID(), recipeID, hardwareID).Scan(&recipe.ID, &recipe.HardwareID, &recipe.Name, &recipe.Picture, &drinkIDsJSON); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Recipe not found", http.StatusNotFound)
			return
		}
		log.Default().Printf("Error getting recipe: %v", err)
		http.Error(w, "Could not get recipe", http.StatusInternalServerError)
		return
	}

	// Zutateninformationen abrufen
	rows, err := db.Query(query.GetIngredientsForRecipe(), recipe.ID)
	if err != nil {
		log.Default().Printf("Error getting ingredients for recipe: %v", err)
		http.Error(w, "Could not get ingredients for recipe", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Zutaten und zugehörige Getränke-Details sammeln
	var ingredientsAll []models.IngredientResponse
	for rows.Next() {
		var ingredient models.Ingredient
		if err := rows.Scan(&ingredient.RecipeID, &ingredient.DrinkID, &ingredient.Quantity_ml); err != nil {
			log.Default().Printf("Error scanning ingredient: %v", err)
			http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
			return
		}

		// Getränkedetails abrufen
		var drink models.Drink
		if err := db.QueryRow(query.GetDrinkByID(), ingredient.DrinkID, recipe.HardwareID).Scan(&drink.DrinkID, &drink.HardwareID, &drink.Name, &drink.Alcoholic); err != nil {
			log.Default().Printf("Error getting drink details for drink_id %d: %v", ingredient.DrinkID, err)
			continue
		}

		// Zutat und Getränk kombinieren
		ingredientsAll = append(ingredientsAll, models.IngredientResponse{
			Quantity_ml: ingredient.Quantity_ml,
			Drink:       drink,
		})
	}

	// Fehler nach der Iteration prüfen
	if err = rows.Err(); err != nil {
		log.Default().Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
		return
	}

	if len(ingredientsAll) == 0 {
		ingredientsAll = []models.IngredientResponse{}
	}

	// Strukturierte Antwort erstellen
	recipeResponse := models.Recipe_Response{
		ID:          recipe.ID,
		HardwareID:  recipe.HardwareID,
		Name:        recipe.Name,
		Picture:     recipe.Picture,
		Ingredients: ingredientsAll,
	}

	if isRecipeAvailable(recipeResponse, drinkIDsInSlot) {
		mappedRecipes["available"] = append(mappedRecipes["available"], recipeResponse)
	} else {
		mappedRecipes["unavailable"] = append(mappedRecipes["unavailable"], recipeResponse)
	}

	// JSON-Antwort senden
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(mappedRecipes)
}

func UpdateRecipe(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /recipes/{id} at %s", time.Now())

	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	hardwareID := vars["hardware_id"]

	var updatedRecipe models.Recipe
	err := json.NewDecoder(r.Body).Decode(&updatedRecipe)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	// Update recipe in the database
	result, err := db.Exec(query.UpdateRecipeForHardware(), updatedRecipe.Name, updatedRecipe.Picture, recipeID, hardwareID)
	if err != nil {
		log.Default().Printf("Error updating recipe: %v", err)
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
	hardwareID := vars["hardware_id"]

	// Delete recipe from the database
	result, err := db.Exec(query.DeleteRecipeForHardware(), id, hardwareID)
	if err != nil {
		log.Default().Printf("Error deleting recipe: %v", err)
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

// Function to check if all drink_ids from the first array are in the second array
func isRecipeAvailable(recipe models.Recipe_Response, slot_drink_ids []int) bool {
	// Create a map of drink_ids from slots for quick lookup
	slotDrinkIDs := make(map[int]bool)
	for _, drnik_id := range slot_drink_ids {
		slotDrinkIDs[drnik_id] = true
	}

	// Check if all drink_ids from the recipes' ingredients are in the slot map
	for _, ingredient := range recipe.Ingredients {
		if !slotDrinkIDs[ingredient.Drink.DrinkID] {
			return false
		}
	}

	return true
}

func getSlots(db *sql.DB, w http.ResponseWriter, hardwareID string) []int {
	result := []int{}

	slotRows, slotErr := db.Query(query.GetAllSlotsForSelectedHardware(), hardwareID)
	if slotErr != nil {
		log.Default().Printf("Error selecting all slots: %v", slotErr)
		http.Error(w, "Could not get slots", http.StatusInternalServerError)
		return nil
	}
	defer slotRows.Close()

	for slotRows.Next() {
		var slot models.SlotSchema
		if err := slotRows.Scan(&slot.HardwareID, &slot.SlotNumber, &slot.DrinkID); err != nil {
			log.Default().Printf("Error scanning slot: %v", err)
			http.Error(w, "Could not get slots", http.StatusInternalServerError)
			return nil
		}
		if slot.DrinkID.Valid {
			result = append(result, int(slot.DrinkID.Int64))
		}
	}
	return result
}
