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

func buildDevDSN() (string, error) {
	// URL-Varianten zuerst akzeptieren
	if url := os.Getenv("DATABASE_URL"); url != "" {
		return url, nil
	}
	if url := os.Getenv("POSTGRES_URL"); url != "" {
		return url, nil
	}

	// Standard Environment Variablen (vereinfacht)
	host := os.Getenv("DB_HOST")
	if host == "" {
		host = "smartender-db-v2" // Fallback für lokale Entwicklung
	}

	port := os.Getenv("DB_PORT")
	if port == "" {
		port = "5432"
	}

	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASS")
	name := os.Getenv("DB_NAME")

	if user == "" || pass == "" || name == "" {
		return "", fmt.Errorf("Missing required database configuration: DB_USER, DB_PASS, DB_NAME")
	}

	// PostgreSQL DSN
	return fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=disable",
		user, pass, host, port, name,
	), nil
}

func GetDatabaseConnectionString() (*sql.DB, error) {
	// .env laden, aber NICHT fatal – in Containern kommen Werte über echte ENV
	if err := godotenv.Load(); err != nil {
		log.Printf("godotenv: .env nicht geladen (ok in Docker): %v", err)
	}

	// Environment Check
	env := os.Getenv("ENVIRONMENT")
	if env == "" {
		env = "dev"
	}

    switch strings.ToLower(env) {
    case "prod", "production":
        // If Cloud SQL connector variables are present, use connector,
        // otherwise gracefully fall back to direct DSN (local Postgres in Docker).
        if os.Getenv("INSTANCE_CONNECTION_NAME") != "" {
            db, err := cloudsql.ConnectWithConnector()
            if err != nil {
                return nil, fmt.Errorf("Error connecting to Cloud SQL: %v", err)
            }
            return db, nil
        }
        // Fallback to DSN (same path as dev)
        fallDSN, err := buildDevDSN()
        if err != nil {
            return nil, err
        }
        db, err := sql.Open("postgres", fallDSN)
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
