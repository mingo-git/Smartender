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
