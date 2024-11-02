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

	userID := r.Context().Value("user_id")

	// Get all recipe ids for the user
	rows, err := db.Query(query.GetAllRecipesForUser(), userID)
	if err != nil {
		log.Printf("Error getting recipes: %v", err)
		http.Error(w, "Could not get recipes", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Collect all recipe ids
	var recipeIDs []int
	for rows.Next() {
		var recipeID int
		if err := rows.Scan(&recipeID); err != nil {
			log.Printf("Error scanning recipe: %v", err)
			http.Error(w, "Error processing recipes", http.StatusInternalServerError)
			return
		}
		recipeIDs = append(recipeIDs, recipeID)
	}

	// Error check after iteration
	if err = rows.Err(); err != nil {
		log.Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing recipes", http.StatusInternalServerError)
		return
	}

	// Get all ingredients for each recipe
	var recipesAll []models.Recipe_Response
	for _, recipeID := range recipeIDs {
		// Get recipe details
		var recipe models.Recipe
		var drinkIDsJSON []byte
		if err := db.QueryRow(query.GetRecipeByID(), recipeID, userID).Scan(&recipe.ID, &recipe.UserID, &recipe.Name, &drinkIDsJSON); err != nil {
			log.Printf("Error getting recipe: %v", err)
			continue
		}

		// Get ingredients for the recipe
		rows, err := db.Query(query.GetIngredientsForRecipe(), recipe.ID)
		if err != nil {
			log.Printf("Error getting ingredients for recipe: %v", err)
			continue
		}
		defer rows.Close()

		// Collect ingredients and drink details
		var ingredientsAll []models.IngredientResponse
		for rows.Next() {
			var ingredient models.Ingredient
			if err := rows.Scan(&ingredient.RecipeID, &ingredient.DrinkID, &ingredient.Quantity_ml); err != nil {
				log.Printf("Error scanning ingredient: %v", err)
				http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
				return
			}

			// Get drink details
			var drink models.Drink
			if err := db.QueryRow(query.GetDrinkByID(), ingredient.DrinkID, recipe.UserID).Scan(&drink.DrinkID, &drink.UserID, &drink.Name, &drink.Alcoholic); err != nil {
				log.Printf("Error getting drink details for drink_id %d: %v", ingredient.DrinkID, err)
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
			log.Printf("Error after iterating rows: %v", err)
			http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
			return
		}

		if len(ingredientsAll) == 0 {
			ingredientsAll = []models.IngredientResponse{}
		}

		// Create structured response
		recipeResponse := models.Recipe_Response{
			ID:          recipe.ID,
			UserID:      recipe.UserID,
			Name:        recipe.Name,
			Ingredients: ingredientsAll,
		}

		recipesAll = append(recipesAll, recipeResponse)
	}

	// Send JSON response
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(recipesAll)
}

func GetRecipeByID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /recipes/{id} at %s", time.Now())

	// Routen-Variablen extrahieren
	vars := mux.Vars(r)
	recipeID := vars["recipe_id"]
	userID := r.Context().Value("user_id")

	// Haupt-Rezeptdaten abrufen
	var recipe models.Recipe
	var drinkIDsJSON []byte
	if err := db.QueryRow(query.GetRecipeByID(), recipeID, userID).Scan(&recipe.ID, &recipe.UserID, &recipe.Name, &drinkIDsJSON); err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Recipe not found", http.StatusNotFound)
			return
		}
		log.Printf("Error getting recipe: %v", err)
		http.Error(w, "Could not get recipe", http.StatusInternalServerError)
		return
	}

	// Zutateninformationen abrufen
	rows, err := db.Query(query.GetIngredientsForRecipe(), recipe.ID)
	if err != nil {
		log.Printf("Error getting ingredients for recipe: %v", err)
		http.Error(w, "Could not get ingredients for recipe", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	// Zutaten und zugehörige Getränke-Details sammeln
	var ingredientsAll []models.IngredientResponse
	for rows.Next() {
		var ingredient models.Ingredient
		if err := rows.Scan(&ingredient.RecipeID, &ingredient.DrinkID, &ingredient.Quantity_ml); err != nil {
			log.Printf("Error scanning ingredient: %v", err)
			http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
			return
		}

		// Getränkedetails abrufen
		var drink models.Drink
		if err := db.QueryRow(query.GetDrinkByID(), ingredient.DrinkID, recipe.UserID).Scan(&drink.DrinkID, &drink.UserID, &drink.Name, &drink.Alcoholic); err != nil {
			log.Printf("Error getting drink details for drink_id %d: %v", ingredient.DrinkID, err)
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
		log.Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing ingredients", http.StatusInternalServerError)
		return
	}

	if len(ingredientsAll) == 0 {
		ingredientsAll = []models.IngredientResponse{}
	}

	// Strukturierte Antwort erstellen
	recipeResponse := models.Recipe_Response{
		ID:          recipe.ID,
		UserID:      recipe.UserID,
		Name:        recipe.Name,
		Ingredients: ingredientsAll,
	}

	// JSON-Antwort senden
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(recipeResponse)
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
