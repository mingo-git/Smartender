package models

import "database/sql"

type SlotSchema struct {
	HardwareID int           `json:"hardware_id"`
	SlotNumber int           `json:"slot_number"`
	DrinkID    sql.NullInt64 `json:"drink_id"`
}

type Slot struct {
	HardwareID int    `json:"hardware_id"`
	SlotNumber int    `json:"slot_number"`
	Drink      *Drink `json:"drink,omitempty"`
}

type SlotUpdate struct {
	HardwareID int  `json:"hardware_id"`
	SlotNumber int  `json:"slot_number"`
	DrinkID    *int `json:"drink_id,omitempty"`
}
