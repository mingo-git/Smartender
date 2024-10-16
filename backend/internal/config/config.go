package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type DatabaseConfig struct {
	Username string
	Password string
	DBName   string
}

func LoadDatabaseConfig() DatabaseConfig {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	return DatabaseConfig{
		Username: os.Getenv("APP_DB_USERNAME"),
		Password: os.Getenv("APP_DB_PASSWORD"),
		DBName:   os.Getenv("APP_DB_NAME"),
	}
}
