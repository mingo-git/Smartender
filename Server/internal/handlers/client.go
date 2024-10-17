package handlers

import (
	. "app/internal/models"
	"app/internal/query"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

func CreateUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [POST] /user at %s", time.Now())
	// 1. Decode the incoming JSON request
	var newUser User
	err := json.NewDecoder(r.Body).Decode(&newUser)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}
	// 2. Validate the user input (optional)
	if newUser.Username == "" || newUser.Password == "" || newUser.Email == "" {
		http.Error(w, "Username, password, and email are required", http.StatusBadRequest)
		return
	}
	// 3. Insert the new user into the database
	err = db.QueryRow(query.CreateUser(), newUser.Username, newUser.Password, newUser.Email).Scan(&newUser.UserID)
	if err != nil {
		log.Printf("Error inserting user: %v", err)
		http.Error(w, "Could not create user: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// 4. Set the response header to indicate success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated) // 201 Created

	// 5. Encode the created user as a JSON response
	json.NewEncoder(w).Encode(newUser)
}

// ReadUser retrieves user details
func ReadUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [GET] /user at %s", time.Now())

	// Extract user ID from the URL
	vars := mux.Vars(r) // Using Gorilla Mux to get URL variables
	userID := vars["user_id"]

	// Prepare a User struct to hold the retrieved user
	var user User

	// Query the database for the user
	err := db.QueryRow(query.GetUserByID(), userID).Scan(&user.UserID, &user.Username, &user.Password, &user.Email)

	// Handle errors
	if err != nil {
		if err == sql.ErrNoRows {
			// If no user is found, respond with a 404
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		// For any other errors, log and respond with a 500
		log.Printf("Error retrieving user: %v", err)
		http.Error(w, "Internal Server Error"+err.Error(), http.StatusInternalServerError)
		return
	}

	// Return the user details as JSON
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// UpdateUser updates user details
func UpdateUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [PUT] /user at %s", time.Now())

	// Extract user ID from the URL
	vars := mux.Vars(r) // Using Gorilla Mux to get URL variables
	userID := vars["user_id"]

	// Parse the request body
	var user User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		log.Printf("Error decoding request body: %v", err)
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	_, err = db.Exec(query.UpdateUser(), user.Username, user.Email, user.Password, userID)

	// Handle errors
	if err != nil {
		if err == sql.ErrNoRows {
			// If no user is found, respond with a 404
			http.Error(w, "User not found", http.StatusNotFound)
			return
		}
		// For any other errors, log and respond with a 500
		log.Printf("Error updating user: %v", err)
		http.Error(w, "Internal Server Error: "+err.Error(), http.StatusInternalServerError)
		return
	}

	// Optionally, return the updated user details or a success message
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func DeleteUser(db *sql.DB, w http.ResponseWriter, r *http.Request) {
	log.Default().Printf("📬 [DELETE] /user at %s", time.Now())

	// Extract user ID from the URL
	vars := mux.Vars(r) // Using Gorilla Mux to get URL variables
	userID := vars["user_id"]

	res, err := db.Exec(query.DeleteUser(), userID)

	// Handle errors
	if err != nil {
		log.Printf("Error deleting user: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Check the number of rows affected
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		log.Printf("Error checking affected rows: %v", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		// If no rows were affected, the user was not found
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	// Respond with a success message
	w.WriteHeader(http.StatusNoContent) // 204 No Content
}
