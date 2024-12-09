import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';

import '../provider/theme_provider.dart';

class DeviceDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final String selectedDevice;
  final ValueChanged<String?> onChanged;

  const DeviceDropdown({
    Key? key,
    required this.devices,
    required this.selectedDevice,
    required this.onChanged,
  }) : super(key: key);

  @override
  _DeviceDropdownState createState() => _DeviceDropdownState();
}

class _DeviceDropdownState extends State<DeviceDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    setState(() {
      if (_isOpen) {
        _closeDropdown();
      } else {
        _openDropdown();
      }
    });
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)?.insert(_overlayEntry!);
    _isOpen = true;
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  OverlayEntry _createOverlayEntry() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;


    return OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - (horizontalPadding * 2),
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, 0), // Dropdown über dem Button anzeigen
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: defaultBorderRadius,
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                border: Border.all(color: theme.tertiaryColor),
                borderRadius: defaultBorderRadius,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.devices.map((device) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text(device['name']),
                        trailing: device['status'] == "new"
                            ? Icon(Icons.add, color: theme.tertiaryColor)
                            : Icon(
                          Icons.circle,
                          color: device['status'] == "active"
                              ? theme.trueColor
                              : theme.falseColor,
                          size: 18,
                        ),
                        onTap: () {
                          widget.onChanged(device['name']);
                          _closeDropdown();
                        },
                      ),
                      if (device != widget.devices.last)
                        Divider(
                          color: theme.tertiaryColor,
                          thickness: 1,
                          height: 1,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // Finde den Status des aktuell ausgewählten Geräts
    final selectedDeviceStatus = widget.devices.firstWhere(
          (device) => device['name'] == widget.selectedDevice,
      orElse: () => {'status': 'inactive'},
    )['status'];

    // Definiere die Farbe des Punktes basierend auf dem Status
    final statusColor = selectedDeviceStatus == "active"
        ? theme.trueColor
        : selectedDeviceStatus == "inactive"
        ? theme.falseColor
        : theme.uncertainColor;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: theme.primaryColor,
            border: Border.all(color: theme.tertiaryColor),
            borderRadius: defaultBorderRadius,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.selectedDevice),
              Row(
                children: [
                  Icon(Icons.circle, color: statusColor, size: 16),
                  const SizedBox(width: 8),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
