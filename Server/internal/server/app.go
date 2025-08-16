package app

import (
	"app/internal/config"
	populate "app/internal/query"
	"database/sql"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

type App struct {
	Router *mux.Router
	DB     *sql.DB
}

func (a *App) Initialize() {

	var err error

	// Lade die Datenbankverbindung, entweder lokal oder Cloud SQL, je nach Umgebungsvariable
	a.DB, err = config.GetDatabaseConnectionString()
	if err != nil {
		log.Fatal(err)
	} else {
		log.Default().Printf("Connected to the database")
	}

	// Datenbank initialisieren
	_, err = a.DB.Exec(populate.WipeDatabase())
	if err != nil {
		log.Fatalf("Error wiping tables: %v", err)
	}

	_, err = a.DB.Exec(populate.CreateTables())
	if err != nil {
		log.Fatalf("Error creating tables: %v", err)
	}

	_, err = a.DB.Exec(populate.PopulateDatabase())
	if err != nil {
		log.Fatalf("Error populating tables: %v", err)
	}

	// Router initialisieren
	a.Router = mux.NewRouter()
	a.initializeRoutes()
}

func (a *App) Run() {
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080" // default port if not specified
	}
	log.Default().Printf("Server starting on Port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, a.Router))
}
