package query

func CreateIngredient() string {
	return "INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml) VALUES ($1, $2, $3) RETURNING recipe_id;"
}

// UpdateIngredient returns the SQL query to update a specific ingredient by its ID.
func UpdateIngredient() string {
	return "UPDATE recipe_ingredients SET quantity_ml = $3 WHERE (recipe_id = $1) AND (drink_id = $2)"
}

// DeleteIngredient returns the SQL query to delete a specific ingredient by its ID.
func DeleteIngredient() string {
	return "DELETE FROM recipe_ingredients WHERE (recipe_id = $1) AND (drink_id = $2)"
}

// GetIngredientsForRecipe returns the SQL query to get all ingredients for a specific recipe.
func GetIngredientsForRecipe() string {
	return `SELECT 
						r.recipe_id,
						d.drink_id,  
						r.quantity_ml
				FROM 
						recipe_ingredients r
				JOIN 
						drinks d ON r.drink_id = d.drink_id
				WHERE 
						r.recipe_id = $1;
`
}