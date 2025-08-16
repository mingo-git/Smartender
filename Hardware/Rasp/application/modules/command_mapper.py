import json
from modules.utils.logger import Logger


class Ingredient:
    def __init__(self, quantity_ml, slot_number):
        self.quantity_ml = quantity_ml
        self.slot_number = slot_number

    def __repr__(self):
        return f"Ingredient(quantity_ml={self.quantity_ml}, slot_number={self.slot_number})"


class CommandMapper:
    def __init__(self):
        """
        Initialize the CommandMapper with a logger instance.
        """
        self.logger = Logger()

    def map_command(self, message):
        """
        Deserialize and process the received message to map commands.

        Args:
            message (str): JSON string received from the WebSocket.

        Returns:
            list[Ingredient]: A list of Ingredient objects or None if an error occurs.
        """
        try:
            # Deserialize the JSON message
            commands = json.loads(message)
            self.logger.log("INFO", "Command deserialization successful", "CommandMapper")

            # Convert to a list of Ingredient objects
            ingredients = []
            for ingredient_name, details in commands.items():
                if not all(key in details for key in ("quantity_ml", "slot_number")):
                    raise ValueError(f"Missing keys in ingredient '{ingredient_name}': {details}")
                ingredients.append(Ingredient(details["quantity_ml"], details["slot_number"]))

            # Log the processed ingredients
            for ingredient in ingredients:
                self.logger.log(
                    "DEBUG",
                    f"Processed Ingredient: {ingredient}",
                    "CommandMapper",
                )

            return ingredients

        except json.JSONDecodeError as e:
            self.logger.log("ERROR", f"Error decoding JSON: {e}", "CommandMapper")
            return None
        except ValueError as e:
            self.logger.log("ERROR", f"Error processing command: {e}", "CommandMapper")
            return None
