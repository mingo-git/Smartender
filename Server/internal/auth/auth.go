package auth

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

var jwtSecret = []byte(os.Getenv("JWT_SECRET"))

// GenerateJWT erstellt ein JWT für den angegebenen Benutzer
func GenerateJWT(userID string) (string, error) {
	claims := jwt.MapClaims{
		"user_id": userID,
		"exp":     time.Now().Add(time.Hour * 24 * 30).Unix(), // 30-day expiration
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signedToken, err := token.SignedString(jwtSecret)

	if err != nil {
		log.Default().Printf("Error generating token: %v", err)
		return "", err
	}

	log.Default().Printf("Generated token: %s", signedToken) // Debugging the token
	return signedToken, nil
}

// ValidateJWT checks the JWT token and returns the parsed user_id or an error
func ValidateJWT(tokenString string) (int, error) {

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		// Ensure that the signing method is HMAC (HS256)
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return jwtSecret, nil
	})

	if err != nil {
		log.Default().Printf("Error parsing token: %v", err)
		return 0, fmt.Errorf("invalid token: %v", err)
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// Check if user_id is a string and convert it to an int
		if userIDStr, ok := claims["user_id"].(string); ok {
			userID, err := strconv.Atoi(userIDStr)
			if err != nil {
				log.Default().Printf("Error converting user_id to int: %v", err)
				return 0, fmt.Errorf("user_id format invalid")
			}
			return userID, nil
		}

		// If user_id is stored as a float64 (fallback case)
		if userIDFloat, ok := claims["user_id"].(float64); ok {
			userID := int(userIDFloat)
			return userID, nil
		}

		log.Default().Printf("Error: user_id format is invalid")
		return 0, fmt.Errorf("user_id format invalid")
	}

	return 0, fmt.Errorf("invalid token")
}
