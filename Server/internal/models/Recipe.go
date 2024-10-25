package models

type Recipe struct {
	ID         string   `json:"recipe_id"`
	UserID     string   `json:"user_id"`
	Name       string   `json:"recipe_name"`
	DrinkNames []string `json:"drink_names"`
}
