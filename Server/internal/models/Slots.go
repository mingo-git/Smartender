package models

type SlotSchema struct {
	HardwareID int `json:"hardware_id"`
	SlotNumber int `json:"slot_number"`
	DrinkID    int `json:"drink_id"`
}

type Slot struct {
	HardwareID int   `json:"hardware_id"`
	SlotNumber int   `json:"slot_number"`
	Drink      Drink `json:"drink,omitempty"`
}
