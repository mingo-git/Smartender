import 'package:flutter/material.dart';
import 'cocktail.dart';

class CocktailCard extends ChangeNotifier{
  final List<Cocktail> _card = [
    Cocktail(
      name: 'Aperol Spritz',
      ingredients: [
        '3 Teile Prosecco',
        '2 Teile Aperol',
        '1 Spritzer Sodawasser',
        'Eiswürfel',
        'Orangenscheibe zur Garnierung'
      ],
      imagePath: 'assets/images/cocktails/aperol.png',
    ),
    Cocktail(
      name: 'Gin Tino',
      ingredients: [
        '123445',
        'Gin',
        "Tino"
      ],
      imagePath: 'assets/images/cocktails/gin_tino.png',
    ),
    Cocktail(
      name: 'Guaro',
      ingredients: [
        'Vodka',
        '2 Teile Aperol',
      ],
      imagePath: 'assets/images/cocktails/guaro.png',
    ),
    Cocktail(
      name: 'Strawberry Ice',
      ingredients: [
        'Erdbeer',
        'Ice',
        'Rum'
      ],
      imagePath: 'assets/images/cocktails/strawberry_ice.png',
    ),
    Cocktail(
      name: 'Tequila Sunrise',
      ingredients: [
        'Tequila',
        'Ice',
        'O-Saft'
      ],
      imagePath: 'assets/images/cocktails/tequila_sunrise.png',
    ),
    Cocktail(
      name: 'Touchdown',
      ingredients: [
        'Vodka',
        'Ice',
        'Grenadine'
      ],
      imagePath: 'assets/images/cocktails/touch_down.png',
    ),
  ];

  List<Cocktail> get cocktailCard => _card;

}