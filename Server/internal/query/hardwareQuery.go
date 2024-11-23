package query

func CreateHardwareForUser() string {
	return "INSERT INTO hardware (hardware_name, hardware_type, user_id) VALUES ($1, $2, $3) RETURNING hardware_id;"
}

func GetHardwareForUser() string {
	return "SELECT hardware_id, user_id, hardware_name, hardware_type FROM hardware WHERE user_id = $1 ORDER BY hardware_id"
}

func GetHardwareForUserByID() string {
	return "SELECT hardware_id, user_id FROM user_hardware WHERE hardware_id = $1 AND user_id = $2"
}
