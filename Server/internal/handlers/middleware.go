package handlers

import (
	auth "app/internal/auth"
	"log"

	"context"
	"net/http"
	"strings"
)

func JWTMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		tokenString := r.Header.Get("Authorization")
		if tokenString == "" {
			http.Error(w, "Missing token", http.StatusUnauthorized)
			return
		}

		tokenString = strings.TrimPrefix(tokenString, "Bearer ")

		user_id, err := auth.ValidateJWT(tokenString)
		if err != nil {
			log.Default().Printf("Error validating token: %v", err)
			http.Error(w, "Invalid token", http.StatusUnauthorized)
			return
		}

		log.Default().Printf("🪪 [USER ID EXTRACTED FROM TOKEN]:\t%d\n", user_id)

		ctx := context.WithValue(r.Context(), "user_id", user_id)
		r = r.WithContext(ctx)

		next.ServeHTTP(w, r)
	})
}

func APIKeyMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		apiKey := r.Header.Get("X-API-Key")
		if apiKey == "" {
			http.Error(w, "Missing API key", http.StatusUnauthorized)
			return
		}

		next.ServeHTTP(w, r)

	})
}
