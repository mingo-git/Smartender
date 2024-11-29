
//TODO: Evtl loeschen, da es aktuell ersetzt wurde
import 'package:flutter/material.dart';

class SearchDropdown extends StatefulWidget {
  final List<String> items; // Liste der Dropdown-Optionen
  final String hintText; // Platzhaltertext
  final Function(String) onItemSelected; // Callback für die Auswahl

  const SearchDropdown({
    Key? key,
    required this.items,
    required this.hintText,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<SearchDropdown> createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];
  bool _isDropdownVisible = false;
  String? _selectedItem; // Der ausgewählte Wert

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items
          .where((item) => item.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onItemSelected(String value) {
    print("Selected item: $value"); // Debug-Ausgabe
    setState(() {
      _selectedItem = value; // Aktualisiere den ausgewählten Wert
      _searchController.text = value; // Aktualisiere den Textfeldwert
      _isDropdownVisible = false; // Schließe das Dropdown
    });
    widget.onItemSelected(value); // Löse den Callback aus
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: _selectedItem ?? widget.hintText, // Zeige die Auswahl oder den Platzhalter
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                _isDropdownVisible ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
              onPressed: () {
                setState(() {
                  _isDropdownVisible = !_isDropdownVisible;
                });
              },
            ),
          ),
          onTap: () {
            setState(() {
              _isDropdownVisible = true;
            });
          },
        ),
        if (_isDropdownVisible)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredItems[index]),
                  onTap: () => _onItemSelected(_filteredItems[index]),
                );
              },
            ),
          ),
      ],
    );
  }
}
