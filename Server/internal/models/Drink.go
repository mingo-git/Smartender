package models

type Drink struct {
	DrinkID    int    `json:"drink_id"`
	Name       string `json:"drink_name"`
	HardwareID int    `json:"hardware_id"`
	Alcoholic  bool   `json:"is_alcoholic"`
}
