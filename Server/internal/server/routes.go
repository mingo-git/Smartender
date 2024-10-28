package app

import (
	// "database/sql"
	"app/internal/handlers"
	"net/http"
)

func (a *App) initializeRoutes() {

	// Ensure that all routes are protected by the API key
	root := a.Router
	root.Use(handlers.APIKeyMiddleware)
	root.HandleFunc("/", handlers.GetRoot).Methods("GET")

	// Smartender (Raspberry Pi)
	smartenderRouter := a.Router.PathPrefix("/smartender").Subrouter()
	smartenderRouter.HandleFunc("/register", handlers.RegisterDevice).Methods("GET")

	// Client (Mobile App)
	clientRouter := a.Router.PathPrefix("/api").Subrouter()
	clientRouter.HandleFunc("/auth/register", func(w http.ResponseWriter, r *http.Request) {
		handlers.RegisterUser(a.DB, w, r)
	}).Methods("POST")

	clientRouter.HandleFunc("/auth/login", func(w http.ResponseWriter, r *http.Request) {
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

	// DRINKS: ---------------------------------------------------------------------------------------
	usersRouter := clientRouter.PathPrefix("/user").Subrouter()
	usersRouter.Use(handlers.JWTMiddleware)
	usersRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateDrink(a.DB, w, r)
	}).Methods("POST")

	usersRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllDrinks(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateDrink(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteDrink(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// RECIPES: --------------------------------------------------------------------------------------
	usersRouter.HandleFunc("/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateRecipe(a.DB, w, r)
	}).Methods("POST")

	usersRouter.HandleFunc("/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllRecipes(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateRecipeName(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteRecipe(a.DB, w, r)
	}).Methods("DELETE")

	// clientRouter.HandleFunc("/registerDevice", handlers.AddDevice).Methods("GET")
	// clientRouter.HandleFunc("/User", handlers.GetUserData).Methods("GET")
	// clientRouter.HandleFunc("/device", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
	// clientRouter.HandleFunc("", handlers.).Methods("GET")
}
