package models

type Recipe struct {
	ID           int     `json:"recipe_id"`
	HardwareID   int     `json:"hardware_id"`
	Name         string  `json:"recipe_name"`
	IsFavorite   bool    `json:"is_favorite"`
	DrinkDetails []Drink `json:"drink_details"`
}

type Recipe_Response struct {
	ID          int                  `json:"recipe_id"`
	HardwareID  int                  `json:"hardware_id"`
	Name        string               `json:"recipe_name"`
	IsFavorite  bool                 `json:"is_favorite"`
	Ingredients []IngredientResponse `json:"ingredientsResponse"`
}
