package models

type Recipe struct {
	RecipeID    string       `json:"recipe_id"`
	RecipeName  string       `json:"recipe_name"`
	Ingredients []Ingredient `json:"ingredients"`
}
