package app

import (
    "database/sql"
    "fmt"
    "log"
    "os"
    "net/http"
    "app/internal/config"
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
    connectionString := fmt.Sprintf("user=%s password=%s dbname=%s sslmode=disable", dbConfig.Username, dbConfig.Password, dbConfig.DBName)

    var err error
    a.DB, err = sql.Open("postgres", connectionString)

    if err != nil {
        log.Fatal(err)
    } else {
        log.Default().Printf("Connected to the database")
    }

    // TODO: Prepopulate the database with the tables here (IF NOT EXIST CREATE...)

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