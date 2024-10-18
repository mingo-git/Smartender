package query

func WipeDatabase() string {
	return `
		-- Drop existing tables

	DROP TABLE IF EXISTS recipe_ingredients CASCADE;
	DROP TABLE IF EXISTS recipes CASCADE;
	DROP TABLE IF EXISTS slots CASCADE;
	DROP TABLE IF EXISTS beverages CASCADE;
	DROP TABLE IF EXISTS user_hardware CASCADE;
	DROP TABLE IF EXISTS hardware CASCADE;
	DROP TABLE IF EXISTS users CASCADE;
	`
}

func CreateTables() string {
	return `
		-- Create tables

	CREATE TABLE IF NOT EXISTS users (
		user_id SERIAL PRIMARY KEY,
		username VARCHAR(50) NOT NULL UNIQUE,  -- Add unique constraint
		password VARCHAR(255) NOT NULL,
		email VARCHAR(100) NOT NULL UNIQUE     -- Add unique constraint
	);

	CREATE TABLE IF NOT EXISTS beverages (
		beverage_id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,  -- Each beverage belongs to a user
		beverage_name VARCHAR(100) NOT NULL
	);

	CREATE TABLE IF NOT EXISTS hardware (
		hardware_id SERIAL PRIMARY KEY,
		device_name VARCHAR(100) NOT NULL,
		device_id VARCHAR(255) UNIQUE NOT NULL  -- Unique hardware ID sent by the device
	);

	CREATE TABLE IF NOT EXISTS user_hardware (
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
		hardware_id INT REFERENCES hardware(hardware_id) ON DELETE CASCADE,
		PRIMARY KEY (user_id, hardware_id)
	);

	CREATE TABLE IF NOT EXISTS slots (
		slot_id SERIAL PRIMARY KEY,
		hardware_id INT REFERENCES hardware(hardware_id) ON DELETE CASCADE,
		slot_number INT NOT NULL,
		beverage_id INT REFERENCES beverages(beverage_id) ON DELETE SET NULL  -- Each slot can hold one beverage
	);

	CREATE TABLE IF NOT EXISTS recipes (
		recipe_id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,  -- Each recipe belongs to a user
		recipe_name VARCHAR(100) NOT NULL UNIQUE,  -- Unique recipe name per user
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS recipe_ingredients (
		recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,  -- Ingredients belong to recipes
		beverage_id INT REFERENCES beverages(beverage_id) ON DELETE CASCADE,  -- Each ingredient is a beverage
		quantity_ml INT NOT NULL,  -- Amount of the beverage used in the recipe
		PRIMARY KEY (recipe_id, beverage_id)
	);
	`
}

func PopulateDatabase() string {
	return `
	-- Prepopulate the users table
	INSERT INTO users (username, password, email) VALUES
		('testuser', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser@example.com')
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
