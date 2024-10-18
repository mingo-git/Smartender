package query

func GetAllDrinks() string {
	return "SELECT * FROM drinks"
}

func CreateDrink() string {
	return "INSERT INTO drinks (name) VALUES ($1) RETURNING drink_id;"
}

// GetDrinkByID returns the SQL query to fetch a specific drink by its ID.
func GetDrinkByID() string {
	return "SELECT drink_id, name FROM drinks WHERE drink_id = $1"
}

// UpdateDrink returns the SQL query to update a specific drink by its ID.
func UpdateDrink() string {
	return "UPDATE drinks SET name = $1 WHERE drink_id = $2"
}

// DeleteDrink returns the SQL query to delete a specific drink by its ID.
func DeleteDrink() string {
	return "DELETE FROM drinks WHERE drink_id = $1"
}