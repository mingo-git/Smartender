package models

type Hardware struct {
	HardwareID   int    `json:"hardware_id"`
	HardwareName string `json:"hardware_name"`
	MacAddress   string `json:"mac_address"`
	UserID       int    `json:"user_id"`
}

type HardwareCreate struct {
	HardwareName string `json:"hardware_name"`
	MacAddress   string `json:"mac_address"`
	UserID       int    `json:"user_id"`
}
