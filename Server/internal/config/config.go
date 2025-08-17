package config

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"app/internal/cloudsql"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq" // register "postgres" driver
)

// holt den ersten gesetzten Wert aus einer Liste möglicher ENV-Keys
func first(keys ...string) string {
	for _, k := range keys {
		if v, ok := os.LookupEnv(k); ok && strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func buildDevDSN() (string, error) {
	// URL-Varianten zuerst akzeptieren
	if url := first("DATABASE_URL", "POSTGRES_URL"); url != "" {
		return url, nil
	}

	host := first("APP_DB_HOST", "DB_HOST", "POSTGRES_HOST", "PGHOST")
	if host == "" {
		host = "smartender-db-v2"
	}
	port := first("APP_DB_PORT", "DB_PORT", "POSTGRES_PORT", "PGPORT")
	if port == "" {
		port = "5432"
	}
	user := first("APP_DB_USER", "APP_DB_USERNAME", "DB_USER", "DB_USERNAME", "POSTGRES_USER", "PGUSER")
	pass := first("APP_DB_PASSWORD", "DB_PASSWORD", "POSTGRES_PASSWORD", "PGPASSWORD")
	name := first("APP_DB_DATABASE", "APP_DB_NAME", "DB_NAME", "POSTGRES_DB", "PGDATABASE")

	if user == "" || pass == "" || name == "" {
		return "", fmt.Errorf("No database configuration found")
	}

	// klassische lib/pq-DSN; sslmode=disable für lokale Container
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		user, pass, host, port, name,
	), nil
}

func GetDatabaseConnectionString() (*sql.DB, error) {
	// .env laden, aber NICHT fatal – in Containern kommen Werte über echte ENV
	if err := godotenv.Load(); err != nil {
		log.Printf("godotenv: .env nicht geladen (ok in Docker): %v", err)
	}

	// Rechtschreibfehler abfangen: ENVIRONMENT hat Vorrang, ENVIROMENT als Fallback
	env := first("ENVIRONMENT", "ENVIROMENT")
	if env == "" {
		env = "dev"
	}

	switch strings.ToLower(env) {
	case "prod", "production":
		db, err := cloudsql.ConnectWithConnector()
		if err != nil {
			return nil, fmt.Errorf("Error connecting to Cloud SQL: %v", err)
		}
		return db, nil

	default: // dev / staging / anything else
		dsn, err := buildDevDSN()
		if err != nil {
			return nil, err
		}

		db, err := sql.Open("postgres", dsn)
		if err != nil {
			return nil, fmt.Errorf("Error opening database connection: %v", err)
		}

		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := db.PingContext(ctx); err != nil {
			_ = db.Close()
			return nil, fmt.Errorf("DB ping failed: %v", err)
		}
		return db, nil
	}
}
