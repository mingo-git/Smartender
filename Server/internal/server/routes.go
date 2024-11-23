package app

import (
	// "database/sql"
	handlers "app/internal/handlers"
	"net/http"
)

func (a *App) initializeRoutes() {

	// =============================================================================================== API KEY
	// Ensure that all routes are protected by the API key
	root := a.Router
	root.Use(handlers.APIKeyMiddleware)
	root.HandleFunc("/", handlers.GetRoot).Methods("GET")
	// ===============================================================================================

	// Smartender (Raspberry Pi) --------------------------------------------------------------------- HARDWARE
	smartenderRouter := a.Router.PathPrefix("/smartender").Subrouter()
	smartenderRouter.HandleFunc("/register", handlers.RegisterDevice).Methods("GET")
	// -----------------------------------------------------------------------------------------------

	// Client (Mobile App) --------------------------------------------------------------------------- CLIENT

	// REGISTRATION and LOGIN ------------------------------------------------------------------------ REGISTRATION + LOGIN
	clientRouter := a.Router.PathPrefix("/api").Subrouter()
	clientRouter.HandleFunc("/auth/register", func(w http.ResponseWriter, r *http.Request) {
		handlers.RegisterUser(a.DB, w, r)
	}).Methods("POST")

	clientRouter.HandleFunc("/auth/login", func(w http.ResponseWriter, r *http.Request) {
		handlers.LoginUser(a.DB, w, r)
	}).Methods("POST")

	// TODO: Change or delete User Data
	usersRouter := clientRouter.PathPrefix("/user").Subrouter()
	usersRouter.Use(handlers.JWTMiddleware)

	usersRouter.HandleFunc("/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateUser(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteUser(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// DRINKS: ---------------------------------------------------------------------------------------  DRINKS
	usersRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateDrink(a.DB, w, r)
	}).Methods("POST")

	usersRouter.HandleFunc("/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllDrinks(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetSingleDrinkForUserByDrinkID(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateDrink(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteDrink(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// RECIPES: --------------------------------------------------------------------------------------  RECIPES
	usersRouter.HandleFunc("/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateRecipe(a.DB, w, r)
	}).Methods("POST")

	usersRouter.HandleFunc("/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllRecipes(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetRecipeByID(a.DB, w, r)
	}).Methods("GET")

	usersRouter.HandleFunc("/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateRecipeName(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteRecipe(a.DB, w, r)
	}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// INGREDIENTS: ----------------------------------------------------------------------------------  INGREDIENTS
	usersRouter.HandleFunc(
		"/recipes/{recipe_id}/ingredients", func(w http.ResponseWriter, r *http.Request) {
			handlers.CreateIngredient(a.DB, w, r)
		}).Methods("POST")

	usersRouter.HandleFunc(
		"/recipes/{recipe_id}/ingredients/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
			handlers.UpdateIngredient(a.DB, w, r)
		}).Methods("PUT")

	usersRouter.HandleFunc(
		"/recipes/{recipe_id}/ingredients/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
			handlers.DeleteIngredient(a.DB, w, r)
		}).Methods("DELETE")
	// -----------------------------------------------------------------------------------------------

	// HARDWARE: -------------------------------------------------------------------------------------  HARDWARE

	hardwareRouter := usersRouter.PathPrefix("/hardware").Subrouter()
	// hardwareRouter.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
	// 	handlers.RegisterHardware(a.DB, w, r)
	// }).Methods("POST")

	// SLOTS: ----------------------------------------------------------------------------------------  SLOTS
	// TODO: Move this Route to the WebSocket Communication Process
	hardwareRouter.HandleFunc("/slots/temp", func(w http.ResponseWriter, r *http.Request) {
		handlers.InitSlotsForHardware(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/slots", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllSlotsForSelectedHardware(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/slots/{slot_number}", func(w http.ResponseWriter, r *http.Request) {
		handlers.SetSlotForHardwareAndID(a.DB, w, r)
	}).Methods("PUT")
	// -----------------------------------------------------------------------------------------------

	// REGISTER DEVICE: ------------------------------------------------------------------------------  REGISTER DEVICE
	// TODO: WebSocket
	smartenderRouter.HandleFunc("/socket", handlers.Socket).Methods("GET")
	usersRouter.HandleFunc("/action", func(w http.ResponseWriter, r *http.Request) {
		handlers.SendCommandToHardware(a.DB, w, r)
	}).Methods("POST")
	// -----------------------------------------------------------------------------------------------
}
