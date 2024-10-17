package models

type Ingredient struct {
	Drinks       []Drink `json:"drinks"`
	Amount_in_ml int     `json:"amount"`
}
