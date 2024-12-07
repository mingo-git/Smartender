package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"app/internal/cloudsql"
	"database/sql"
)

func GetDatabaseConnectionString() (*sql.DB, error) {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	env := os.Getenv("ENVIROMENT")
	if env == "dev" {
		username := os.Getenv("APP_DB_USERNAME")
		password := os.Getenv("APP_DB_PASSWORD")
		dbName := os.Getenv("APP_DB_NAME")
		// Lokale Verbindung herstellen und als *sql.DB zurückgeben
		connectionString := fmt.Sprintf("host=db user=%s password=%s dbname=%s sslmode=disable", username, password, dbName)
		db, err := sql.Open("postgres", connectionString)
		if err != nil {
			return nil, fmt.Errorf("Error opening database connection: %v", err)
		}
		return db, nil
	} else if env == "prod" {
		// Rückgabe der Cloud SQL-Verbindung für prod
		db, err := cloudsql.ConnectWithConnector() // Deine Cloud SQL-Verbindung
		if err != nil {
			return nil, fmt.Errorf("Error connecting to Cloud SQL: %v", err)
		}
		return db, nil
	}

	return nil, fmt.Errorf("No database configuration found")
}