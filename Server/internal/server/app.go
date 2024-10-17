package app

import (
	"app/internal/config"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	populate "app/internal/query"
	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

type App struct {
	Router *mux.Router
	DB     *sql.DB
}

func (a *App) Initialize() {
	// Load configuration
	dbConfig := config.LoadDatabaseConfig()

	// Use the service name 'db' defined in docker-compose.yml
	connectionString := fmt.Sprintf("host=db user=%s password=%s dbname=%s sslmode=disable",
		dbConfig.Username, dbConfig.Password, dbConfig.DBName)

	var err error
	a.DB, err = sql.Open("postgres", connectionString)

	if err != nil {
		log.Fatal(err)
	} else {
		log.Default().Printf("Connected to the database")
	}

	// Pre-populate the database with the tables here 
	_, err = a.DB.Exec(populate.CreateAndPrepopulateTables())

	if err != nil {
		log.Fatalf("Error creating users table: %v", err)
	}
	a.Router = mux.NewRouter()
	a.initializeRoutes()
}

func (a *App) Run() {
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080" // default port if not specified
	}
	log.Printf("Server starting on Port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, a.Router))
}
