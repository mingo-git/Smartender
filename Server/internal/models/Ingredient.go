package models

type Ingredient struct {
	RecipeID    int `json:"recipe_id"`
	DrinkID     int `json:"drink_id"`
	Quantity_ml int `json:"quantity_ml"`
}


type IngredientResponse struct {
	Quantity_ml int   `json:"quantity_ml"`
	Drink       Drink `json:"drink"`
}
