package utils

import (
	"app/internal/query"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
)

var getMappedIngredientsForRecipe string = `
SELECT
    s.slot_number,
    ri.quantity_ml
FROM
    recipe_ingredients ri
JOIN
    drinks d ON ri.drink_id = d.drink_id
LEFT JOIN
    slots s ON s.drink_id = d.drink_id
WHERE
    s.hardware_id = $1 AND ri.recipe_id = $2
`

// CocktailProtokollMapper maps the Recipe to the Cocktail Protocol
func CocktailProtokollMapper(db *sql.DB, hardware_id int, recipe_id string, r *http.Request) (string, error) {

	var checkHardwareID int
	var checkUserID int

	// Check if the hadware is owned by the user
	err := db.QueryRow(query.GetHardwareForUserByID(), hardware_id, r.Context().Value("user_id")).Scan(&checkHardwareID, &checkUserID)

	if err != nil {
		log.Default().Printf("Failed to get hardware for user: %s", err)
		return "", errors.New("failed to get hardware from Database")
	}

	// Prepare the map for ingredients
	ingredients := make(map[string]map[string]interface{})
	rows, err := db.Query(getMappedIngredientsForRecipe, hardware_id, recipe_id)
	if err != nil {
		log.Default().Printf("Failed to get ingredients: %s", err)
		return "", errors.New("failed to get ingredients from Database")
	}
	defer rows.Close()

	// Iterate over the results
	count := 1
	for rows.Next() {
		var slotNumber sql.NullInt32
		var quantityML int

		// Scan each ingredient
		err := rows.Scan(&slotNumber, &quantityML)
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
