from flask import Flask, request, jsonify # type: ignore

# Erstelle die Flask-Anwendung
app = Flask(__name__)

# Basis-Route
@app.route("/")
def home():
    return jsonify({"message": "Welcome to your Flask server!"})

# Beispiel-Route mit Parameter
@app.route("/items/<int:item_id>")
def get_item(item_id):
    detail = request.args.get("detail", "false").lower() == "true"
    return jsonify({
        "item_id": item_id,
        "detail": detail,
        "description": "This is an example endpoint."
    })

# Beispiel-Route für POST-Anfragen
@app.route("/create", methods=["POST"])
def create_item():
    data = request.get_json()
    if not data or "name" not in data:
        return jsonify({"error": "Invalid input"}), 400
    return jsonify({"message": f"Item '{data['name']}' has been created successfully!"})

# Starte den Server
if __name__ == "__main__":
    app.run(debug=True)