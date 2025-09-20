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
    -- Users (sample admin/dev users)
    INSERT INTO users (username, password, email) VALUES
        ('testuser', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser@example.com'),
        ('jonas69', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser1@example.com'),
        ('mingoTheFicker', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser2@example.com'),
        ('bigDickPhil', '$2a$10$6vfPb12fs0SY2xiFLQvB7eMRit52Ys4g5vH3InrCb/JPC4H4w5b.G', 'testuser3@example.com')
    ON CONFLICT (username) DO NOTHING;

    -- Single-device hardware (fixed MAC)
    INSERT INTO hardware (hardware_name, mac_address) VALUES
        ('Smartender Single-Device', 'AA:BB:CC:DD:EE:FF')
    ON CONFLICT (mac_address) DO NOTHING;

    -- Map users to hardware 1 as admin
    INSERT INTO user_hardware (user_id, hardware_id, role) VALUES
        (1, 1, 'admin')
    ON CONFLICT (user_id, hardware_id) DO NOTHING;

    -- Drinks for hardware 1 (requested baseline)
    INSERT INTO drinks (hardware_id, drink_name, is_alcoholic) VALUES
        (1, 'Vodka', TRUE),
        (1, 'Havana', TRUE),
        (1, 'Tequila', TRUE),
        (1, 'Asbach', TRUE),
        (1, 'Gin', TRUE),
        (1, 'Aperol', TRUE),
        (1, 'Orangensaft', FALSE),
        (1, 'Cola', FALSE),
        (1, 'Sprite', FALSE),
        (1, 'Pfanner Grüner', FALSE),
        (1, 'Energy Drink', FALSE),
        (1, 'Cranberry Saft', FALSE),
        (1, 'Eistee Pfirsich', FALSE)
    ON CONFLICT DO NOTHING;

    -- Empty slots for hardware 1 (1..11)
    INSERT INTO slots (hardware_id, slot_number, drink_id) VALUES
        (1, 1, NULL), (1, 2, NULL), (1, 3, NULL), (1, 4, NULL), (1, 5, NULL),
        (1, 6, NULL), (1, 7, NULL), (1, 8, NULL), (1, 9, NULL), (1,10, NULL), (1,11, NULL)
    ON CONFLICT (slot_number, hardware_id) DO NOTHING;

    -- Standard longdrinks (hardware 1)
    -- Cuba Libre (Havana + Cola) 70/330 ml
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Cuba Libre', 0)
    ON CONFLICT (recipe_name) DO NOTHING;

    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Cuba Libre','Havana',70), ('Cuba Libre','Cola',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Vodka E (Vodka + Energy Drink) 70/330 ml
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Vodka E', 0)
    ON CONFLICT (recipe_name) DO NOTHING;

    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Vodka E','Vodka',70), ('Vodka E','Energy Drink',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Vodka O (Vodka + Orangensaft) 70/330 ml
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Vodka O', 0)
    ON CONFLICT (recipe_name) DO NOTHING;

    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Vodka O','Vodka',70), ('Vodka O','Orangensaft',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Asbach Cola (Asbach + Cola) 70/330 ml
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Asbach Cola', 0)
    ON CONFLICT (recipe_name) DO NOTHING;

    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Asbach Cola','Asbach',70), ('Asbach Cola','Cola',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Additional longdrinks (all 70/330 ml)
    -- Vodka Cranberry
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Vodka Cranberry', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Vodka Cranberry','Vodka',70), ('Vodka Cranberry','Cranberry Saft',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Vodka Pfirsich (Vodka + Eistee Pfirsich)
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Vodka Pfirsich', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Vodka Pfirsich','Vodka',70), ('Vodka Pfirsich','Eistee Pfirsich',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Vodka Sprite
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Vodka Sprite', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Vodka Sprite','Vodka',70), ('Vodka Sprite','Sprite',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Gin Sprite
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Gin Sprite', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Gin Sprite','Gin',70), ('Gin Sprite','Sprite',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Havana Sprite
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Havana Sprite', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Havana Sprite','Havana',70), ('Havana Sprite','Sprite',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Havana Energy
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Havana Energy', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Havana Energy','Havana',70), ('Havana Energy','Energy Drink',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Tequila Orange
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Tequila Orange', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Tequila Orange','Tequila',70), ('Tequila Orange','Orangensaft',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Tequila Sprite
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Tequila Sprite', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Tequila Sprite','Tequila',70), ('Tequila Sprite','Sprite',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Asbach Energy
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Asbach Energy', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Asbach Energy','Asbach',70), ('Asbach Energy','Energy Drink',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Aperol Sprite (als alkoh. Longdrink)
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Aperol Sprite', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Aperol Sprite','Aperol',70), ('Aperol Sprite','Sprite',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Aperol Orange
    INSERT INTO recipes (hardware_id, recipe_name, picture_id)
    VALUES (1, 'Aperol Orange', 0)
    ON CONFLICT (recipe_name) DO NOTHING;
    INSERT INTO recipe_ingredients (recipe_id, drink_id, quantity_ml)
    SELECT r.recipe_id, d.drink_id, q.qty FROM
    (VALUES ('Aperol Orange','Aperol',70), ('Aperol Orange','Orangensaft',330)) AS q(rname,dname,qty)
    JOIN recipes r ON r.recipe_name = q.rname AND r.hardware_id = 1
    JOIN drinks d ON d.drink_name = q.dname AND d.hardware_id = 1
    ON CONFLICT DO NOTHING;

    -- Remove old demo recipe if present
    DELETE FROM recipes WHERE hardware_id = 1 AND recipe_name ILIKE 'Whiskey O';
    `
}
