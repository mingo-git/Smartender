package models

type User struct {
	UserID   string `json:"user_id"`
	Username string `json:"username"`
	Password string `json:"password"`
	Email    string `json:"email"`
	Token    string `json:"token"`
}
