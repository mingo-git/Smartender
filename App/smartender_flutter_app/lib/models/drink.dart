class Drink {
  final int drinkId;
  final String drinkName;
  final int hardwareId;
  final bool isAlcoholic;

  Drink({
    required this.drinkId,
    required this.drinkName,
    required this.hardwareId,
    required this.isAlcoholic,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      drinkId: json['drink_id'],
      drinkName: json['drink_name'],
      hardwareId: json['hardware_id'],
      isAlcoholic: json['is_alcoholic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drink_id': drinkId,
      'drink_name': drinkName,
      'hardware_id': hardwareId,
      'is_alcoholic': isAlcoholic,
    };
  }
}
