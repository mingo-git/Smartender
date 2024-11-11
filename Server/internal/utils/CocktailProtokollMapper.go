package utils

import (
	"app/internal/models"
	"app/internal/query"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
)

var getMappedIngredientsForRecipe string = `
SELECT
    s.slot_number,
    d.drink_id,
    d.drink_name,
    ri.quantity_ml
FROM
    recipe_ingredients ri
JOIN
    drinks d ON ri.drink_id = d.drink_id
LEFT JOIN
    slots s ON s.drink_id = d.drink_id
WHERE
    ri.recipe_id = $1;
`

// CocktailProtokollMapper maps the Recipe to the Cocktail Protocol
func CocktailProtokollMapper(db *sql.DB, recipe_id int) (string, error) {
	// Fetch the recipe name and details
	recipe := models.Recipe{}
	err := db.QueryRow(query.GetRecipeByID(), recipe_id).Scan(&recipe.ID, &recipe.UserID, &recipe.Name)
	if err != nil {
		log.Default().Printf("Failed to get recipe: %s", err)
		return "", errors.New("failed to get recipe from Database")
	}

	// Prepare the map for ingredients
	ingredients := make(map[string]map[string]interface{})
	rows, err := db.Query(getMappedIngredientsForRecipe, recipe_id)
	if err != nil {
		log.Default().Printf("Failed to get ingredients: %s", err)
		return "", errors.New("failed to get ingredients from Database")
	}
	defer rows.Close()

	// Iterate over the results
	count := 1
	for rows.Next() {
		var slotNumber sql.NullInt32
		var drinkID int
		var drinkName string
		var quantityML int

		// Scan each ingredient
		err := rows.Scan(&slotNumber, &drinkID, &drinkName, &quantityML)
		if err != nil {
			log.Default().Printf("Failed to scan ingredient: %s", err)
			return "", errors.New("failed to read ingredient data")
		}

		// Generate ingredient key (e.g., "ingredient_1", "ingredient_2", ...)
		ingredientKey := fmt.Sprintf("ingredient_%d", count)
		count++

		// Build ingredient details
		ingredients[ingredientKey] = map[string]interface{}{
			"slot_number": slotNumber.Int32, // will be 0 if NULL
			"drink_id":    drinkID,
			"drink_name":  drinkName,
			"quantity_ml": quantityML,
		}
	}

	// Check for errors after the loop
	if err := rows.Err(); err != nil {
		log.Default().Printf("Row iteration error: %s", err)
		return "", errors.New("error iterating over ingredients data")
	}

	// Convert to JSON
	jsonData, err := json.Marshal(ingredients)
	if err != nil {
		log.Default().Printf("Failed to marshal ingredients to JSON: %s", err)
		return "", errors.New("failed to convert ingredients to JSON")
	}

	return string(jsonData), nil
}
