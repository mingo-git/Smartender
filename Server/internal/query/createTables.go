package query

func WipeDatabase() string {
	return `
	-- Drop existing tables

	DROP TABLE IF EXISTS favorite_recipes CASCADE;
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
	
	CREATE TABLE IF NOT EXISTS hardware (
		hardware_id SERIAL PRIMARY KEY,
		hardware_name VARCHAR(100) NOT NULL,
		mac_address VARCHAR(17) UNIQUE NOT NULL
	);

	CREATE TABLE IF NOT EXISTS drinks (
		drink_id SERIAL PRIMARY KEY,
		hardware_id INT REFERENCES hardware(hardware_id) ON DELETE CASCADE NOT NULL,  -- Each drink belongs to a hardware
		drink_name VARCHAR(100) NOT NULL,
		is_alcoholic BOOLEAN DEFAULT TRUE NOT NULL
	);

	CREATE TABLE IF NOT EXISTS user_hardware (
		user_id INT REFERENCES users(user_id) ON DELETE SET NULL,
		hardware_id INT REFERENCES hardware(hardware_id) ON DELETE CASCADE,
		role VARCHAR(50) DEFAULT 'user' NOT NULL,  -- User role for the hardware
		PRIMARY KEY (user_id, hardware_id)
	);

	-- Create a trigger function to handle conditional delete
	CREATE OR REPLACE FUNCTION delete_admin_user_hardware()
	RETURNS TRIGGER AS $$
	BEGIN
		DELETE FROM user_hardware
		WHERE user_id = OLD.user_id AND role = 'admin';
		RETURN OLD;
	END;
	$$ LANGUAGE plpgsql;

	-- Attach the trigger function to the users table
	CREATE TRIGGER delete_admin_user_hardware_trigger
	AFTER DELETE ON users
	FOR EACH ROW
	EXECUTE FUNCTION delete_admin_user_hardware();


	CREATE TABLE IF NOT EXISTS slots (
			hardware_id INT NOT NULL REFERENCES hardware(hardware_id) ON DELETE CASCADE,
			slot_number INT NOT NULL,
			drink_id INT REFERENCES drinks(drink_id) ON DELETE SET NULL,  -- Each slot can hold one drink
			PRIMARY KEY (slot_number, hardware_id)
	);

	CREATE TABLE IF NOT EXISTS recipes (
		recipe_id SERIAL PRIMARY KEY,
		hardware_id INT REFERENCES hardware(hardware_id) ON DELETE CASCADE,  -- Each recipe belongs to a hardware
		recipe_name VARCHAR(100) NOT NULL UNIQUE,  -- Unique recipe name per hardware
		picture_id INT NOT NULL DEFAULT 0  -- Default picture for the recipe
	);

	CREATE TABLE IF NOT EXISTS recipe_ingredients (
		recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,  -- Ingredients belong to recipes
		drink_id INT REFERENCES drinks(drink_id) ON DELETE CASCADE,  -- Each ingredient is a drink
		quantity_ml INT NOT NULL,  -- Amount of the drink used in the recipe
		PRIMARY KEY (recipe_id, drink_id)
	);

	CREATE TABLE IF NOT EXISTS favorite_recipes (
		user_id INT REFERENCES users(user_id) ON DELETE CASCADE,  -- The user marking the favorite
		recipe_id INT REFERENCES recipes(recipe_id) ON DELETE CASCADE,  -- The recipe being marked as favorite
		PRIMARY KEY (user_id, recipe_id)  -- Ensure a user can only mark a recipe as favorite once
	);
	`

}

func PopulateDatabase() string {
	return `
	INSERT INTO users (username, password, email) VALUES
	    ('testuser', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser@example.com'),
        ('jonas69', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser1@example.com'),
        ('mingoTheFicker', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser2@example.com'),
        ('bigDickPhil', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser3@example.com')
	ON CONFLICT (username) DO NOTHING; -- Avoid duplicates
	
	InSERT INTO hardware (hardware_name, mac_address) VALUES
		('Smartender von Jonas', '00:00:00:00:00:01'),
		('Smartender von Fachschaft', '2c:cf:67:9d:dd:bb'),
		('Smartender von Philipp', '00:00:00:00:00:03');
	
	INSERT INTO drinks (hardware_id, drink_name, is_alcoholic) VALUES
		(2, 'Vodka', TRUE),
		(2, 'Rum', TRUE),
		(2, 'Gin', TRUE),
		(2, 'Tequila', TRUE),
		(1, 'Whiskey', TRUE),
		(1, 'Orange Juice', FALSE);

	INSERT INTO user_hardware (user_id, hardware_id, role) VALUES
		(2, 1, 'admin'),
		(1, 2, 'admin'),
		(4, 3, 'admin');

	INSERT INTO slots (hardware_id, slot_number, drink_id) VALUES
		(1, 1, NULL),
		(1, 2, NULL),
		(1, 3, 5),
		(1, 4, 6),
		(1, 5, NULL),
		(2, 1, 2),
		(2, 2, 1),
		(2, 3, 3),
		(2, 4, 4),
		(2, 5, NULL),
		(2, 6, NULL),
		(2, 7, NULL),
		(2, 8, NULL),
		(2, 9, NULL),
		(2, 10, NULL),
		(2, 11, NULL);

	INSERT INTO recipes (hardware_id, recipe_name, picture_id) VALUES
		(2, 'Vodka Martini', 1),
		(2, 'Mojito', 2),
		(2, 'Gin and Tonic', 3),
		(1, 'Whiskey O', 4);

	INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml) VALUES
		(1, 1, 60),
		(1, 2, 30),
		(2, 2, 60),
		(2, 3, 30),
		(3, 3, 60),
		(3, 4, 30);

	INSERT INTO favorite_recipes (user_id, recipe_id) VALUES
		(1, 1);
	`
}
