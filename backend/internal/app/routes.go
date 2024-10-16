package app

import (
	"smartender/internal/handlers" 
)

func (a *App) initializeRoutes() {
	// Common
	a.Router.HandleFunc("/", handlers.GetRoot).Methods("GET")
	a.Router.HandleFunc("/date", handlers.GetDatetime).Methods("GET")
	a.Router.HandleFunc("/status", handlers.GetStatus).Methods("GET")
	// Smartender
	smartenderRouter := a.Router.PathPrefix("/smartender").Subrouter()
	smartenderRouter.HandleFunc("/register", handlers.RegisterDevice).Methods("GET")
	// // Client
	
	clientRouter := a.Router.PathPrefix("/cli").Subrouter()
	clientRouter.HandleFunc("/register", handlers.RegisterUser).Methods("GET")
	// clientRouter.HandleFunc("/login", handlers.Login).Methods("GET")
	// clientRouter.HandleFunc("/registerDevice", handlers.AddDevice).Methods("GET")
	// clientRouter.HandleFunc("/User", handlers.GetUserData).Methods("GET")
	// clientRouter.HandleFunc("/device", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
}
