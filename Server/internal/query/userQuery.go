package query

func GetAllUsers() string {
	return "SELECT * FROM users"
}

func GetUserByID() string {
	return "SELECT * FROM users WHERE user_id = $1"
}

func GetUserByUsername() string {
	return "SELECT * FROM users WHERE username = $1"
}

func CreateUser() string {
	return "INSERT INTO users (username, password, email) VALUES ($1, $2, $3)"
}

func UpdateUser() string {
	return "UPDATE users SET username = $1, password = $2, email = $3 WHERE user_id = $4"
}

func DeleteUser() string {
	return "DELETE FROM users WHERE user_id = $1"
}
