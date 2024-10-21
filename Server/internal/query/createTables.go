package query

func WipeDatabase() string {
	return `
	-- Drop existing tables

	DROP TABLE IF EXISTS recipe_ingredients CASCADE;
	DROP TABLE IF EXISTS recipes CASCADE;
	DROP TABLE IF EXISTS slots CASCADE;
	DROP TABLE IF EXISTS drinks CASCADE;
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

	CREATE TABLE IF NOT EXISTS drinks (
		drink_id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,  -- Each drink belongs to a user
		drink_name VARCHAR(100) NOT NULL
	);

	CREATE TABLE IF NOT EXISTS hardware (
		hardware_id SERIAL PRIMARY KEY,
		hardware_name VARCHAR(100) NOT NULL,
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
		drink_id INT REFERENCES drinks(drink_id) ON DELETE SET NULL  -- Each slot can hold one drink
	);

	CREATE TABLE IF NOT EXISTS recipes (
		recipe_id SERIAL PRIMARY KEY,
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,  -- Each recipe belongs to a user
		recipe_name VARCHAR(100) NOT NULL UNIQUE,  -- Unique recipe name per user
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS recipe_ingredients (
		recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,  -- Ingredients belong to recipes
		drink_id INT REFERENCES drinks(drink_id) ON DELETE CASCADE,  -- Each ingredient is a drink
		quantity_ml INT NOT NULL,  -- Amount of the drink used in the recipe
		PRIMARY KEY (recipe_id, drink_id)
	);
	`
}

func PopulateDatabase() string {
	return `
	INSERT INTO users (username, password, email) VALUES
		('testuser', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser@example.com')
	ON CONFLICT (username) DO NOTHING; -- Avoid duplicates
	
	INSERT INTO drinks (user_id, drink_name) VALUES
		(1, 'Vodka'),
		(1, 'Rum'),
		(1, 'Gin'),
		(1, 'Tequila'),
		(1, 'Whiskey');

	InSERT INTO hardware (hardware_name, device_id) VALUES
		('Smartender von Jonas', '1'),
		('Smartender von Fachschaft', '2');

	INSERT INTO user_hardware (user_id, hardware_id) VALUES
		(1, 1),
		(1, 2);

	INSERT INTO slots (hardware_id, slot_number, drink_id) VALUES
		(1, 1, 1),
		(1, 2, 2),
		(1, 3, 3),
		(1, 4, 4),
		(1, 5, 5);

	INSERT INTO recipes (user_id, recipe_name) VALUES
		(1, 'Vodka Martini'),
		(1, 'Mojito'),
		(1, 'Gin and Tonic');

	INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml) VALUES
		(1, 1, 60),
		(1, 2, 30),
		(2, 2, 60),
		(2, 3, 30),
		(3, 3, 60),
		(3, 4, 30);
	`
}
