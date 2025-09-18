package app

import (
	"app/internal/config"
	// populate "app/internal/query"
	"database/sql"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

type App struct {
	Router *mux.Router
	DB     *sql.DB
}

func (a *App) Initialize() {
	var err error

	// Lade die Datenbankverbindung
	a.DB, err = config.GetDatabaseConnectionString()
	if err != nil {
		log.Fatal(err)
	} else {
		log.Default().Printf("Connected to the database")
	}

	// 🔒 SICHERHEIT: Nur in Development-Umgebung Datenbank wipen/initialisieren
	env := strings.ToLower(os.Getenv("ENVIRONMENT"))
	if env == "dev" || env == "development" || env == "test" {
		log.Printf("⚠️  DEVELOPMENT MODE: Initialisiere Datenbank...")
		
		// Nur in Dev: Datenbank wipen
		_, err = a.DB.Exec(populate.WipeDatabase())
		if err != nil {
			log.Fatalf("Error wiping tables: %v", err)
		}

		// Nur in Dev: Tabellen erstellen
		_, err = a.DB.Exec(populate.CreateTables())
		if err != nil {
			log.Fatalf("Error creating tables: %v", err)
		}

		// Nur in Dev: Testdaten einfügen
		_, err = a.DB.Exec(populate.PopulateDatabase())
		if err != nil {
			log.Fatalf("Error populating tables: %v", err)
		}
		log.Printf("✅ Development-Datenbank initialisiert")
	} else {
		log.Printf("🔒 PRODUCTION MODE: Überspringe Datenbank-Initialisierung")
		
		// In Production: Nur sicherstellen, dass Tabellen existieren
		_, err = a.DB.Exec(populate.CreateTables())
		if err != nil {
			log.Printf("Warning: Could not create tables (may already exist): %v", err)
		}
	}

	// Router initialisieren
	a.Router = mux.NewRouter()
	a.initializeRoutes()
}

func (a *App) Run() {
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}
	
	env := os.Getenv("ENVIRONMENT")
	log.Default().Printf("🚀 Server starting on Port %s (Environment: %s)", port, env)
	log.Fatal(http.ListenAndServe(":"+port, a.Router))
}