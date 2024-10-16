package models

type User struct {
	UserID   string   `json:"user_id"`
	Username string   `json:"username"`
	Password string   `json:"password"`
	Email    string   `json:"email"`
	Devices  []Device `json:"devices"`
	Recipes  []Recipe `json:"recipes"`
}
