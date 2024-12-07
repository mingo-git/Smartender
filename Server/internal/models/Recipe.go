package models

type Recipe struct {
	ID           string  `json:"recipe_id"`
	HardwareID   string  `json:"hardware_id"`
	Name         string  `json:"recipe_name"`
	DrinkDetails []Drink `json:"drink_details"`
}

type Recipe_Response struct {
	ID          string               `json:"recipe_id"`
	HardwareID  string               `json:"hardware_id"`
	Name        string               `json:"recipe_name"`
	Ingredients []IngredientResponse `json:"ingredientsResponse"`
}
