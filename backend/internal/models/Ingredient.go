package models

type Ingredient struct {
	drinks       []Drink `json:"drinks"`
	amount_in_ml int     `json:"amount"`
}
