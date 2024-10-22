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
	"github.com/lib/pq"
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
		var drinkNames pq.StringArray
		err := rows.Scan(&recipe.ID, &recipe.Name, &drinkNames)
		if err != nil {
			log.Printf("Error scanning recipe: %v", err)
			http.Error(w, "Error processing recipes", http.StatusInternalServerError)
			return
		}
		recipe.DrinkNames = drinkNames
		recipes = append(recipes, recipe)
	}

	// Überprüfe auf Fehler nach der Iteration
	if err = rows.Err(); err != nil {
		log.Printf("Error after iterating rows: %v", err)
		http.Error(w, "Error processing recipes", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK) // 200 OK

	// Encode die Liste der Recipes als JSON und sende sie als Antwort
	json.NewEncoder(w).Encode(recipes)
}

func UpdateRecipe(db *sql.DB, w http.ResponseWriter, r *http.Request) {
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

// func GetSingleRecipeForUserByRecipeID(db *sql.DB, w http.ResponseWriter, r *http.Request) {
// 	log.Default().Printf("📬 [GET] /recipes/{id} at %s", time.Now())

// 	vars := mux.Vars(r)
// 	recipeID := vars["recipe_id"]

// 	var recipe models.Recipe

// 	err := db.QueryRow(query.GetRecipeByID(), recipeID, r.Context().Value("user_id")).Scan(&recipe.RecipeID, &recipe.Name)
// 	if err != nil {
// 		log.Printf("Error getting recipe: %v", err)
// 		http.Error(w, "Could not get recipe", http.StatusInternalServerError)
// 		return
// 	}

// 	w.Header().Set("Content-Type", "application/json")
// 	w.WriteHeader(http.StatusOK)
// 	json.NewEncoder(w).Encode(recipe)
// }
