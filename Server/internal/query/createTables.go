package query

func CreateAndPrepopulateTables() string {
	return `
		-- Drop existing tables
	DROP TABLE IF EXISTS recipe_ingredients;
	DROP TABLE IF EXISTS ingredient_drinks;
	DROP TABLE IF EXISTS recipes;
	DROP TABLE IF EXISTS ingredients;
	DROP TABLE IF EXISTS drinks;
	DROP TABLE IF EXISTS devices;
	DROP TABLE IF EXISTS users;

	-- Recreate tables
	CREATE TABLE IF NOT EXISTS users (
		user_id SERIAL PRIMARY KEY,
		username VARCHAR(50) NOT NULL UNIQUE,  -- Add unique constraint
		password VARCHAR(255) NOT NULL,
		email VARCHAR(100) NOT NULL UNIQUE     -- Add unique constraint
	);

	CREATE TABLE IF NOT EXISTS drinks (
		drink_id SERIAL PRIMARY KEY,
		name VARCHAR(50) NOT NULL UNIQUE         -- Add unique constraint
	);

	CREATE TABLE IF NOT EXISTS devices (
		device_id SERIAL PRIMARY KEY,
		device_name VARCHAR(50) NOT NULL UNIQUE  -- Add unique constraint
	);

	CREATE TABLE IF NOT EXISTS ingredients (
		ingredient_id SERIAL PRIMARY KEY,
		amount_in_ml INT NOT NULL UNIQUE          -- Add unique constraint
	);

	CREATE TABLE IF NOT EXISTS ingredient_drinks (
		ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
		drink_id INT REFERENCES drinks(drink_id) ON DELETE CASCADE,
		PRIMARY KEY (ingredient_id, drink_id)
	);

	CREATE TABLE IF NOT EXISTS recipes (
		recipe_id SERIAL PRIMARY KEY,
		recipe_name VARCHAR(50) NOT NULL UNIQUE,  -- Add unique constraint
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS recipe_ingredients (
		recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,
		ingredient_id INT REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
		PRIMARY KEY (recipe_id, ingredient_id)
	);

	-- Prepopulate the users table
	INSERT INTO users (username, password, email) VALUES
		('testuser', 'password123', 'testuser@example.com')
	ON CONFLICT (username) DO NOTHING; -- Avoid duplicates

	-- Prepopulate the drinks table
	INSERT INTO drinks (name) VALUES
		('Coca Cola'),
		('Pepsi')
	ON CONFLICT (name) DO NOTHING; -- Avoid duplicates

	-- Prepopulate the devices table
	INSERT INTO devices (device_name) VALUES
		('iPhone'),
		('Android Phone')
	ON CONFLICT (device_name) DO NOTHING; -- Avoid duplicates

	-- Prepopulate the ingredients table
	INSERT INTO ingredients (amount_in_ml) VALUES
		(100),
		(200)
	ON CONFLICT (amount_in_ml) DO NOTHING; -- Avoid duplicates

	-- Prepopulate the recipes table
	INSERT INTO recipes (recipe_name) VALUES
		('Mojito'),
		('Margarita')
	ON CONFLICT (recipe_name) DO NOTHING; -- Avoid duplicates
	`
}
