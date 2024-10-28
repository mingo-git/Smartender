package models

type Ingredient struct {
	RecipeID    int `json:"recipe_id"`
	DrinkID     int `json:"drink_id"`
	Quantity_ml int `json:"quantity_ml"`
}
