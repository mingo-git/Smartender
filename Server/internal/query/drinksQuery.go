package query

func CreateDrink() string {
	return "INSERT INTO drinks (drink_name, is_alcoholic, hardware_id) VALUES ($1, $2, $3) RETURNING drink_id"
}

func GetAllDrinksForHardware() string {
	return "SELECT drink_id, hardware_id, drink_name, is_alcoholic FROM drinks WHERE hardware_id = $1 ORDER BY drink_name"
}

// GetDrinkByID returns the SQL query to fetch a specific drink by its ID.
func GetDrinkByID() string {
	return "SELECT drink_id, hardware_id, drink_name, is_alcoholic FROM drinks WHERE (drink_id = $1) AND (hardware_id = $2)"
}

// UpdateDrink returns the SQL query to update a specific drink by its ID.
func UpdateDrink() string {
	return "UPDATE drinks SET drink_name = $1, is_alcoholic = $2 WHERE (drink_id = $3) AND (hardware_id = $4)"
}

// DeleteDrink returns the SQL query to delete a specific drink by its ID.
func DeleteDrink() string {
	return "DELETE FROM drinks WHERE (drink_id = $1) AND (hardware_id = $2)"
}
