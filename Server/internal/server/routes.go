package app

import (
	handlers "app/internal/handlers"
	"net/http"
)

func (a *App) initializeRoutes() {

	// =============================================================================================== API KEY
	// Ensure that all routes are protected by the API key
	root := a.Router
	root.Use(handlers.APIKeyMiddleware)
	root.HandleFunc("/", handlers.GetRoot).Methods("GET")
	
	// Status-Endpunkt ohne API-Key (für Health Checks)
	root.HandleFunc("/status", handlers.GetStatus).Methods("GET")
	// ===============================================================================================

	// Smartender (Raspberry Pi) --------------------------------------------------------------------- HARDWARE
	smartenderRouter := a.Router.PathPrefix("/smartender").Subrouter()
	smartenderRouter.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
		handlers.RegisterHardware(a.DB, w, r)
	}).Methods("POST")

	// Hardware WebSocket
	smartenderRouter.HandleFunc("/socket", func(w http.ResponseWriter, r *http.Request){
		handlers.Socket(a.DB, w, r)
	}).Methods("GET")
	// -----------------------------------------------------------------------------------------------

	// Client (Mobile App) --------------------------------------------------------------------------- CLIENT

	// REGISTRATION and LOGIN ------------------------------------------------------------------------ REGISTRATION + LOGIN
	clientRouter := a.Router.PathPrefix("/api").Subrouter()

	// Frontend WebSocket Endpoint
	clientRouter.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		handlers.FrontendWebSocket(a.DB, w, r)
	}).Methods("GET")

	clientRouter.HandleFunc("/auth/register", func(w http.ResponseWriter, r *http.Request) {
		handlers.RegisterUser(a.DB, w, r)
	}).Methods("POST")

	clientRouter.HandleFunc("/auth/login", func(w http.ResponseWriter, r *http.Request) {
		handlers.LoginUser(a.DB, w, r)
	}).Methods("POST")

	// Authenticated User Routes
	usersRouter := clientRouter.PathPrefix("/user").Subrouter()
	usersRouter.Use(handlers.JWTMiddleware)

	// WebSocket Status Endpoint
	usersRouter.HandleFunc("/ws/status", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetWebSocketStatus(w, r)
	}).Methods("GET")

	// User Management
	usersRouter.HandleFunc("/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateUser(a.DB, w, r)
	}).Methods("PUT")

	usersRouter.HandleFunc("/{user_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteUser(a.DB, w, r)
	}).Methods("DELETE")

	// Hardware Routes
	hardwareRouter := usersRouter.PathPrefix("/hardware").Subrouter()

	// HARDWARE MANAGEMENT ---------------------------------------------------------------------------
	hardwareRouter.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllHardwareForUser(a.DB, w, r)
	}).Methods("GET")

	// DRINKS: ---------------------------------------------------------------------------------------
	hardwareRouter.HandleFunc("/{hardware_id}/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateDrink(a.DB, w, r)
	}).Methods("POST")

	hardwareRouter.HandleFunc("/{hardware_id}/drinks", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllDrinks(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetSingleDrinkForHardwareByDrinkID(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateDrink(a.DB, w, r)
	}).Methods("PUT")

	hardwareRouter.HandleFunc("/{hardware_id}/drinks/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteDrink(a.DB, w, r)
	}).Methods("DELETE")

	// RECIPES: --------------------------------------------------------------------------------------
	hardwareRouter.HandleFunc("/{hardware_id}/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateRecipe(a.DB, w, r)
	}).Methods("POST")

	hardwareRouter.HandleFunc("/{hardware_id}/recipes", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllRecipes(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetRecipeByID(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.UpdateRecipe(a.DB, w, r)
	}).Methods("PUT")

	hardwareRouter.HandleFunc("/{hardware_id}/recipes/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteRecipe(a.DB, w, r)
	}).Methods("DELETE")

	// INGREDIENTS: ----------------------------------------------------------------------------------
	hardwareRouter.HandleFunc(
		"/{hardware_id}/recipes/{recipe_id}/ingredients", func(w http.ResponseWriter, r *http.Request) {
			handlers.CreateIngredient(a.DB, w, r)
		}).Methods("POST")

	hardwareRouter.HandleFunc(
		"/{hardware_id}/recipes/{recipe_id}/ingredients/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
			handlers.UpdateIngredient(a.DB, w, r)
		}).Methods("PUT")

	hardwareRouter.HandleFunc(
		"/{hardware_id}/recipes/{recipe_id}/ingredients/{drink_id}", func(w http.ResponseWriter, r *http.Request) {
			handlers.DeleteIngredient(a.DB, w, r)
		}).Methods("DELETE")

	// FAVORITES: ------------------------------------------------------------------------------------
	hardwareRouter.HandleFunc("/{hardware_id}/favorite/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.CreateFavorite(a.DB, w, r)
	}).Methods("POST")

	hardwareRouter.HandleFunc("/{hardware_id}/favorites", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllFavoritesForUser(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/favorite/{recipe_id}", func(w http.ResponseWriter, r *http.Request) {
		handlers.DeleteFavorite(a.DB, w, r)
	}).Methods("DELETE")

	// SLOTS: ----------------------------------------------------------------------------------------
	hardwareRouter.HandleFunc("/{hardware_id}/slots", func(w http.ResponseWriter, r *http.Request) {
		handlers.GetAllSlotsForSelectedHardware(a.DB, w, r)
	}).Methods("GET")

	hardwareRouter.HandleFunc("/{hardware_id}/slots/{slot_number}", func(w http.ResponseWriter, r *http.Request) {
		handlers.SetSlotForHardwareAndID(a.DB, w, r)
	}).Methods("PUT")

	// ACTIONS: --------------------------------------------------------------------------------------
	usersRouter.HandleFunc("/action", func(w http.ResponseWriter, r *http.Request) {
		handlers.SendCommandToHardware(a.DB, w, r)
	}).Methods("POST")
}
