package query

func CreateRecipeForUser() string {
	return "INSERT INTO recipes (user_id, recipe_name) VALUES ($1, $2) RETURNING recipe_id;"
}

func GetAllRecipesForUser() string {
	return `SELECT 
						r.recipe_id, 
						r.user_id,
						r.recipe_name, 
						COALESCE(ARRAY_AGG(DISTINCT d.drink_id) FILTER (WHERE d.drink_id IS NOT NULL), '{}') AS drink_ids
				FROM 
						recipes r
				LEFT JOIN 
						recipe_ingredients ri ON r.recipe_id = ri.recipe_id
				LEFT JOIN 
						drinks d ON ri.drink_id = d.drink_id
				WHERE 
						r.user_id = $1
				GROUP BY 
						r.recipe_id, r.recipe_name;
`
}

func GetRecipeByID() string {
	return `SELECT 
						r.recipe_id, 
						r.user_id,
						r.recipe_name, 
						    COALESCE(json_agg(DISTINCT ri.drink_id) FILTER (WHERE ri.drink_id IS NOT NULL), '[]') AS drink_ids
				FROM 
						recipes r
				LEFT JOIN 
						recipe_ingredients ri ON r.recipe_id = ri.recipe_id
				LEFT JOIN 
						drinks d ON ri.drink_id = d.drink_id
				WHERE 
						r.recipe_id = $1 AND r.user_id = $2
				GROUP BY 
						r.recipe_id, r.recipe_name;
`
}

func UpdateRecipeForUser() string {
	return "UPDATE recipes SET recipe_name = $1 WHERE (recipe_id = $2) AND (user_id = $3)"
}

func DeleteRecipeForUser() string {
	return "DELETE FROM recipes WHERE (recipe_id = $1) AND (user_id = $2)"
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
