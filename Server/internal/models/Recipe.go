package models

type Recipe struct {
	ID           int     `json:"recipe_id"`
	HardwareID   int     `json:"hardware_id"`
	Name         string  `json:"recipe_name"`
	DrinkDetails []Drink `json:"drink_details"`
}

type Recipe_Response struct {
	ID          int                  `json:"recipe_id"`
	HardwareID  int                  `json:"hardware_id"`
	Name        string               `json:"recipe_name"`
	Ingredients []IngredientResponse `json:"ingredientsResponse"`
}
