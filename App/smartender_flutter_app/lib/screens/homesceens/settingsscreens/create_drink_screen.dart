import 'package:flutter/material.dart';

class CreateDrinkScreen extends StatefulWidget {
  const CreateDrinkScreen({Key? key}) : super(key: key);

  @override
  State<CreateDrinkScreen> createState() => _CreateDrinkScreenState();
}

class _CreateDrinkScreenState extends State<CreateDrinkScreen> {
  bool isLiterMode = true; // Toggle between Liter and Percent
  double filledAmount = 0.2; // Example filled amount (in Liters)
  final double maxCapacity = 0.4; // Maximum capacity of the cup in Liters

  void _toggleMode() {
    setState(() {
      isLiterMode = !isLiterMode;
    });
  }

  String _getDisplayValue() {
    if (isLiterMode) {
      return "${filledAmount.toStringAsFixed(2)} L / ${maxCapacity.toStringAsFixed(2)} L";
    } else {
      double percent = (filledAmount / maxCapacity) * 100;
      return "${percent.toStringAsFixed(1)}%";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          "Create Drink",
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: _toggleMode,
                  child: Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isLiterMode ? Colors.green : Colors.grey[400],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: isLiterMode ? 10 : 35,
                          top: 7,
                          child: Text(
                            isLiterMode ? 'L' : '%',
                            style: TextStyle(
                              color: isLiterMode? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          left: isLiterMode ? 5 : 30,
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Füllmengenanzeige
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    _getDisplayValue(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Abstand zwischen Anzeige und Becher
                // Becheranzeige
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Becherrahmen
                    ClipPath(
                      clipper: CupClipper(),
                      child: Container(
                        width: 170,
                        height: 200,
                        color: Colors.grey[300],
                      ),
                    ),
                    // Füllstandsanzeige
                    ClipPath(
                      clipper: CupClipper(),
                      child: Container(
                        width: 170,
                        height: (filledAmount / maxCapacity) * 200, // Dynamische Höhe basierend auf der Füllmenge
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Buttons for testing (Optional)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (filledAmount + 0.05 <= maxCapacity) {
                      filledAmount += 0.05;
                    }
                  });
                },
                child: const Text("Add 0.05L"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (filledAmount - 0.05 >= 0) {
                      filledAmount -= 0.05;
                    }
                  });
                },
                child: const Text("Remove 0.05L"),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class CupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(size.width * 0.2, 0); // Start oben leicht schmal
    path.lineTo(size.width * 0.8, 0); // Obere Kante
    path.lineTo(size.width, size.height); // Rechte Kante leicht breiter
    path.lineTo(0, size.height); // Linke Kante
    path.close(); // Schließen des Pfads
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
