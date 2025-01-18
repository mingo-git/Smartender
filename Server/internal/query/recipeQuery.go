package query

func CreateRecipeForHardware() string {
	return "INSERT INTO recipes (hardware_id, recipe_name, picture_id) VALUES ($1, $2, $3) RETURNING recipe_id;"
}

func GetAllRecipesForHardware() string {
	return `SELECT 
						r.recipe_id
				FROM 
						recipes r
				WHERE 
						r.hardware_id = $1
				GROUP BY 
						r.recipe_id, r.recipe_name
				ORDER BY
						r.recipe_name;
`
}

// GetIngredientsForRecipe returns all ingredients for a recipe
// The query returns the recipe_id, user_id, recipe_name and an array with each ingredient
// $1 = recipe_id
// $2 = user_id
func GetRecipeByID() string {
	return `SELECT 
						r.recipe_id, 
						r.hardware_id,
						r.recipe_name, 
						r.picture_id,
						    COALESCE(json_agg(DISTINCT ri.drink_id) FILTER (WHERE ri.drink_id IS NOT NULL), '[]') AS drink_ids
				FROM 
						recipes r
				LEFT JOIN 
						recipe_ingredients ri ON r.recipe_id = ri.recipe_id
				LEFT JOIN 
						drinks d ON ri.drink_id = d.drink_id
				WHERE 
						r.recipe_id = $1 AND r.hardware_id = $2
				GROUP BY 
						r.recipe_id, r.recipe_name;
`
}

func UpdateRecipeForHardware() string {
	return "UPDATE recipes SET recipe_name = $1, picture_id = $2 WHERE (recipe_id = $3) AND (hardware_id = $4)"
}

func DeleteRecipeForHardware() string {
	return "DELETE FROM recipes WHERE (recipe_id = $1) AND (hardware_id = $2)"
}

// -------------------------------------------------------------------------------------------------

func AddIngredientToRecipe() string {
	return "INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml) VALUES ($1, $2, $3) RETURNING recipe_id;"
}

func UpdateIngredientInRecipe() string {
	return "UPDATE recipe_ingredients SET drink_id = $1, quantity_ml = $2 WHERE (recipe_id = $3) AND (ingredient_id = $4)"
}

func DeleteIngredientFromRecipe() string {
	return "DELETE FROM recipe_ingredients WHERE (recipe_id = $1) AND (drink_id = $2)"
}
