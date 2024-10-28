package models

type Drink struct {
	DrinkID   int    `json:"drink_id"`
	Name      string `json:"drink_name"`
	UserID    int    `json:"user_id"`
	Alcoholic bool   `json:"is_alcoholic"`
}
