package models

type Recipe struct {
	ID           string  `json:"recipe_id"`
	UserID       string  `json:"user_id"`
	Name         string  `json:"recipe_name"`
	DrinkDetails []Drink `json:"drink_details"`
}
