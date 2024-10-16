package app

import (
	"database/sql"
	"log"
)

// createTables erstellt alle erforderlichen Tabellen in der Datenbank
func createTables(db *sql.DB) error {
	// SQL-Befehl zum Erstellen der Tabelle "users" falls sie nicht existiert
	query := `
	CREATE TABLE IF NOT EXISTS users (
		user_id SERIAL PRIMARY KEY,
		username TEXT NOT NULL,
		password TEXT NOT NULL,
		email TEXT NOT NULL
	);`

	_, err := db.Exec(query)
	if err != nil {
		return err
	}

	log.Println("Tables created or verified successfully")
	return nil
}

// InitializeDB erstellt eine Datenbankverbindung und stellt sicher, dass die Tabellen existieren
func InitializeDB(connectionString string) (*sql.DB, error) {
	// Öffne die Verbindung zur Datenbank
	db, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, err
	}

	// Überprüfe, ob die Verbindung erfolgreich ist
	if err := db.Ping(); err != nil {
		return nil, err
	}

	// Erstelle die Tabellen, falls sie nicht existieren
	if err := createTables(db); err != nil {
		return nil, err
	}

	return db, nil
}