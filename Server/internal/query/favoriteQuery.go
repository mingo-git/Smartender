package query

func CreateFavorite() string {
	return `INSERT INTO favorite_recipes (user_id, recipe_id) VALUES ($1, $2)`
}

func DeleteFavorite() string {
	return `DELETE FROM favorite_recipes WHERE (user_id = $1) AND (recipe_id = $2)`
}

func GetAllFavoritesForUser() string {
	return `
	SELECT
		recipe_id
	FROM
		favorite_recipes
	WHERE
		user_id = $1;
	`
}

func CheckRecipeForHardwareForUser() string {
	return `
	SELECT
		1
	FROM 
		recipes r
	JOIN
		hardware h ON r.hardware_id = h.hardware_id
	JOIN
		user_hardware uh ON h.hardware_id = uh.hardware_id
	WHERE
		uh.user_id = $1 AND r.recipe_id = $2;
`
}
