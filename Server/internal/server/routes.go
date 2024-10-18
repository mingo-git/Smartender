package app

import (
	// "database/sql"
	"app/internal/handlers"
	"net/http"
)

func (a *App) initializeRoutes() {
	// Common
	a.Router.HandleFunc("/", handlers.GetRoot).Methods("GET")
	a.Router.HandleFunc("/date", handlers.GetDatetime).Methods("GET")

	// TODO: Status is dependent on the asking user
	a.Router.HandleFunc("/status", handlers.GetStatus).Methods("GET")

	// Smartender (Raspberry Pi)
	smartenderRouter := a.Router.PathPrefix("/smartender").Subrouter()
	smartenderRouter.HandleFunc("/register", handlers.RegisterDevice).Methods("GET")

	// Client (Mobile App)
	clientRouter := a.Router.PathPrefix("/client").Subrouter()
	clientRouter.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
		handlers.RegisterUser(a.DB, w, r)
	}).Methods("POST")

	clientRouter.HandleFunc("/login", func(w http.ResponseWriter, r *http.Request) {
		handlers.LoginUser(a.DB, w, r)
	}).Methods("POST")



	// TODO: Change or delete User Data --------------------------------------------------------------
	a.Router.HandleFunc("/user/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateUser(a.DB, w, r)
	}).Methods("PUT")

	a.Router.HandleFunc("/user/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteUser(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	

	protectedUserRouter := clientRouter.PathPrefix("/protected").Subrouter()
	protectedUserRouter.Use(handlers.JWTMiddleware)
	protectedUserRouter.HandleFunc("/test", func(w http.ResponseWriter, r *http.Request) {
		// handlers.GetUserData(a.DB, w, r)
	}).Methods("GET")

	// DRINKS: ---------------------------------------------------------------------------------------
	clientRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateDrink(a.DB, w, r)
	}).Methods("POST")

	clientRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllDrinks(a.DB, w, r)
	}).Methods("GET")

	clientRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateDrink(a.DB, w, r)
	}).Methods("PUT")

	clientRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteDrink(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// clientRouter.HandleFunc("/registerDevice", handlers.AddDevice).Methods("GET")
	// clientRouter.HandleFunc("/User", handlers.GetUserData).Methods("GET")
	// clientRouter.HandleFunc("/device", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
}
