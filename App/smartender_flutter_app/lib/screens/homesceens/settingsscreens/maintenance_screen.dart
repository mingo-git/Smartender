import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:smartender_flutter_app/config/constants.dart';
import 'package:smartender_flutter_app/provider/theme_provider.dart';
import 'package:smartender_flutter_app/services/maintenance_service.dart';
import 'package:smartender_flutter_app/services/slot_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isProcessing = false;
  String _statusMessage = "";
  final Set<int> _activePumps = <int>{}; // 0..5
  static const bool _showFlushAll = false; // Feature-Flag Step 2
  bool _cleaningPositionActive = false; // false=home/normal, true=at slot 3

  // -------------------- Processing feedback --------------------
  void _showProcessingDialog(String operation) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.tertiaryColor),
              const SizedBox(height: 20),
              Text(
                operation,
                style: TextStyle(
                  color: theme.tertiaryColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _hideProcessingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _performMaintenance(String maintenanceType, {int? slotNumber}) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "";
    });

    String operation = switch (maintenanceType) {
      "flush_all" => "Flushing all pumps…",
      "flush_slot" => "Flushing slot $slotNumber…",
      _ => "Processing…",
    };

    _showProcessingDialog(operation);

    try {
      final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
      final success = await maintenanceService.performMaintenance(
        maintenanceType: maintenanceType,
        slotNumber: slotNumber,
      );

      _hideProcessingDialog();

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      _hideProcessingDialog();
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // -------------------- Large confirm popup --------------------
  Future<bool?> _showConfirmPopup({
    required String title,
    required Widget description,
    required String confirmLabel,
    bool large = false,
  }) async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final width = MediaQuery.of(context).size.width;
    final maxDialogWidth = width * 0.92;
    final targetWidth = large ? (maxDialogWidth.clamp(360.0, 720.0)) : (maxDialogWidth.clamp(320.0, 560.0));

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: Text(title, style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: targetWidth),
              child: DefaultTextStyle(
                style: TextStyle(color: theme.tertiaryColor, fontSize: 15, height: 1.35),
                child: description,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: TextStyle(color: theme.tertiaryColor)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.tertiaryColor,
                shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
                side: BorderSide(color: theme.tertiaryColor),
              ),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
  }

  // -------------------- Bottle selection (image grid) --------------------
  Future<void> _showBottleSelectionDialog() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    // TODO(Jonas): Replace placeholder list with your real bottle/slot data + images (like on your slot page).
    const int itemCount = 11;

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.backgroundColor,
          title: Text("Select bottle", style: TextStyle(color: theme.tertiaryColor)),
          content: SizedBox(
            width: MediaQuery.of(ctx).size.width * 0.92,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: itemCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final slotNumber = index + 1;

                return InkWell(
                  onTap: () async {
                    final confirmed = await _showConfirmPopup(
                      title: "Flush selected bottle (slot $slotNumber)",
                      description: const Text(
                        "This will flush only the selected bottle line.\n"
                            "Ensure a waste container is placed correctly.",
                      ),
                      confirmLabel: "Start flush",
                      large: false,
                    );
                    if (confirmed == true) {
                      if (mounted) Navigator.pop(ctx);
                      _performMaintenance("flush_slot", slotNumber: slotNumber);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.tertiaryColor),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              // TODO(Jonas): Insert real bottle image path (same as slot page).
                              "lib/images/cocktails/cocktail_unavailable.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Bottle $slotNumber",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.tertiaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: TextStyle(color: theme.tertiaryColor)),
            ),
          ],
        );
      },
    );
  }

  // -------------------- Light settings popup --------------------
  Future<void> _showLightSettingsPopup() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);

    double brightness = 128;
    bool isOn = true;
    Timer? _brightnessDebounce;
    // Predefined palette of 16 colors (as ARGB)
    final List<Color> palette = [
      const Color(0xFFFF0000), // Red
      const Color(0xFFFFA500), // Orange
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFF0000FF), // Blue
      const Color(0xFF4B0082), // Indigo
      const Color(0xFF8B00FF), // Violet
      const Color(0xFFFFFFFF), // White
      const Color(0xFF808080), // Gray
      const Color(0xFFFFC0CB), // Pink
      const Color(0xFF00FF7F), // Spring Green
      const Color(0xFFFF4500), // OrangeRed
      const Color(0xFF1E90FF), // DodgerBlue
      const Color(0xFFADFF2F), // GreenYellow
      const Color(0xFF8B4513), // SaddleBrown
    ];
    Color selected = palette[3];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateLocal) {
          final screen = MediaQuery.of(context).size;
          final maxH = screen.height * 0.6; // cap dialog content height to 60% of screen
          final gridH = (screen.height * 0.32).clamp(160.0, 320.0);
          return AlertDialog(
            backgroundColor: theme.backgroundColor,
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            title: Row(
              children: [
                Expanded(child: Text("Light settings", style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.bold))),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.tertiaryColor),
                  tooltip: 'Close',
                ),
              ],
            ),
            content: SizedBox(
              width: 320,
              height: maxH,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Master On/Off toggle
                SwitchListTile(
                  value: isOn,
                  onChanged: (val) async {
                    setStateLocal(() => isOn = val);
                    if (!val) {
                      await maintenanceService.turnOffLights();
                    } else {
                      await maintenanceService.setSolidColor(r: selected.red, g: selected.green, b: selected.blue, brightness: brightness.toInt());
                    }
                  },
                    title: Text('Lights', style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.w600)),
                    activeColor: theme.tertiaryColor,
                    inactiveThumbColor: theme.tertiaryColor.withOpacity(0.6),
                    inactiveTrackColor: theme.tertiaryColor.withOpacity(0.3),
                  ),
                  // Color palette grid (16 colors) with fixed height
                  SizedBox(
                    height: gridH,
                    child: GridView.builder(
                      itemCount: palette.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (ctx, index) {
                        final c = palette[index];
                        final isSel = c.value == selected.value;
                        return InkWell(
                          onTap: () async {
                            setStateLocal(() => selected = c);
                            if (isOn) {
                              await maintenanceService.setSolidColor(r: c.red, g: c.green, b: c.blue, brightness: brightness.toInt());
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: defaultBorderRadius,
                              border: Border.all(color: isSel ? theme.trueColor : theme.tertiaryColor, width: isSel ? 2 : 1),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _doubleSlider(
                    theme: theme,
                    label: 'Brightness',
                    value: brightness,
                    min: 0,
                    max: 255,
                    onChanged: (v) {
                      setStateLocal(() => brightness = v);
                      if (!isOn) return;
                      _brightnessDebounce?.cancel();
                      _brightnessDebounce = Timer(const Duration(milliseconds: 100), () {
                        maintenanceService.setSolidColor(
                          r: selected.red,
                          g: selected.green,
                          b: selected.blue,
                          brightness: brightness.toInt(),
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: const [],
          );
        });
      },
    );
  }

  // -------------------- Manual motor control popup --------------------
  Future<void> _showManualMotorControlPopup() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);

    double x = 0; // -100 .. 100
    double z = 0; // -100 .. 100

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateLocal) {
          return AlertDialog(
            backgroundColor: theme.backgroundColor,
            title: Text("Manual motor control", style: TextStyle(color: theme.tertiaryColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAxisSlider(
                  theme: theme,
                  label: "X-Axis (left ↔ right)",
                  value: x,
                  onChanged: (val) => setStateLocal(() => x = val),
                ),
                const SizedBox(height: 12),
                _buildAxisSlider(
                  theme: theme,
                  label: "Z-Axis (down ↕ up)",
                  value: z,
                  onChanged: (val) => setStateLocal(() => z = val),
                ),
                const SizedBox(height: 6),
                Text(
                  "Values range from -100 to 100.",
                  style: TextStyle(color: theme.tertiaryColor.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Close", style: TextStyle(color: theme.tertiaryColor)),
              ),
              ElevatedButton(
                onPressed: () async {
                  await maintenanceService.moveAxes(x: x, z: z);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.tertiaryColor,
                  shape: RoundedRectangleBorder(borderRadius: defaultBorderRadius),
                  side: BorderSide(color: theme.tertiaryColor),
                ),
                child: const Text("Move"),
              ),
            ],
          );
        });
      },
    );
  }

  // -------------------- Hold-to-Flush UI (2x3) --------------------
  Widget _buildHoldToFlushGrid() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);
    final slotService = Provider.of<SlotService>(context, listen: false);

    Widget buildTile(int pumpNumber) {
      final pumpIndex = pumpNumber - 1; // 0..5
      final isActive = _activePumps.contains(pumpIndex);
      final color = isActive
          ? theme.trueColor.withOpacity(0.18)
          : theme.primaryColor;

      // Map pump 1..6 to slots 6..11
      final int slotNumber = 5 + pumpNumber;
      Future<String> ingredientFuture() async {
        try {
          final slots = await slotService.fetchSlotsFromLocal();
          final slot = slots.firstWhere(
            (s) => (s['slot_number'] as int?) == slotNumber,
            orElse: () => {},
          );
          final drink = slot['drink'];
          final name = (drink != null)
              ? (drink['name'] ?? drink['drink_name'] ?? '')
              : '';
          if (name is String && name.trim().isNotEmpty) return name;
          return 'Empty';
        } catch (_) {
          return 'Empty';
        }
      }

      return GestureDetector(
        onTapDown: (_) async {
          setState(() => _activePumps.add(pumpIndex));
          await maintenanceService.startPumpHold(pumpIndex);
        },
        onTapUp: (_) async {
          await maintenanceService.stopPumpHold(pumpIndex);
          setState(() => _activePumps.remove(pumpIndex));
        },
        onTapCancel: () async {
          await maintenanceService.stopPumpHold(pumpIndex);
          setState(() => _activePumps.remove(pumpIndex));
        },
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: defaultBorderRadius,
            border: Border.all(color: isActive ? theme.trueColor : theme.tertiaryColor),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.water, color: theme.tertiaryColor, size: 32),
              const SizedBox(height: 8),
              Text(
                'Pump $pumpNumber',
                style: TextStyle(
                  color: theme.tertiaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FutureBuilder<String>(
                future: ingredientFuture(),
                builder: (ctx, snap) {
                  final text = (snap.connectionState == ConnectionState.waiting)
                      ? '…'
                      : (snap.data ?? 'Empty');
                  return Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.tertiaryColor.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flush single slot (Hold)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.tertiaryColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: List.generate(6, (i) => buildTile(i + 1)),
        ),
      ],
    );
  }

  Widget _buildAxisSlider({
    required dynamic theme,
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: -100,
          max: 100,
          divisions: 200,
          onChanged: onChanged,
          activeColor: theme.tertiaryColor,
          inactiveColor: theme.tertiaryColor.withOpacity(0.3),
          label: value.toStringAsFixed(0),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => onChanged(0),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.tertiaryColor),
                foregroundColor: theme.tertiaryColor,
              ),
              child: const Text("Center"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rgbSlider({required dynamic theme, required String label, required double value, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.w600)),
            Text(value.toInt().toString(), style: TextStyle(color: theme.tertiaryColor)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 255,
          divisions: 255,
          onChanged: onChanged,
          activeColor: theme.tertiaryColor,
          inactiveColor: theme.tertiaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _doubleSlider({required dynamic theme, required String label, required double value, required double min, required double max, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.tertiaryColor, fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(1), style: TextStyle(color: theme.tertiaryColor)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
          activeColor: theme.tertiaryColor,
          inactiveColor: theme.tertiaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  // -------------------- UI helpers --------------------
  Widget _buildMaintenanceButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
    Color? buttonColor,
  }) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ?? theme.primaryColor,
          foregroundColor: theme.tertiaryColor,
          minimumSize: const Size(double.infinity, 80),
          shape: RoundedRectangleBorder(
            borderRadius: defaultBorderRadius,
          ),
          side: BorderSide(color: theme.tertiaryColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: theme.tertiaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.tertiaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.tertiaryColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- Cleaning position toggle --------------------
  Future<void> _toggleCleaningPosition() async {
    final maintenanceService = Provider.of<MaintenanceService>(context, listen: false);

    final goingToClean = !_cleaningPositionActive;
    final dialogText = goingToClean ? 'Moving cart to cleaning position…' : 'Returning cart to home…';
    _showProcessingDialog(dialogText);
    try {
      final ok = await maintenanceService.sendMaintenanceCommand(
        goingToClean
            ? { 'maintenance_type': 'go_to_slot', 'slot_number': 3 }
            : { 'maintenance_type': 'go_home' },
      );
      _hideProcessingDialog();
      if (ok) {
        setState(() => _cleaningPositionActive = goingToClean);
      }
    } catch (_) {
      _hideProcessingDialog();
    }
  }

  // -------------------- Build --------------------
  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context, listen: false).currentTheme;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 35, color: theme.tertiaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Maintenance & Flush",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: theme.tertiaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ---- Flush options ----
            Text(
              "Flush options",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.tertiaryColor,
              ),
            ),
            const SizedBox(height: 16),

            if (_showFlushAll)
              _buildMaintenanceButton(
                title: "Flush complete system",
                subtitle: "Flushes all pumps",
                icon: Icons.water_drop,
                onPressed: () async {
                  final confirmed = await _showConfirmPopup(
                    title: "Flush complete system",
                    large: true,
                    description: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "This operation will flush all pumps.",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 10),
                        Text("• The cart will move to the RIGHT to make space for a large container."),
                        SizedBox(height: 6),
                        Text("• Please place a container with at least 2 liters capacity under the outlet."),
                        SizedBox(height: 6),
                        Text("• Ensure the area is clear and do not interrupt the process."),
                      ],
                    ),
                    confirmLabel: "Start flush",
                  );
                  if (confirmed == true) {
                    _performMaintenance("flush_all");
                  }
                },
              ),

            // Hold-to-Flush (2x3 grid for pumps 1..6)
            _buildHoldToFlushGrid(),

            const SizedBox(height: 24),
            Text(
              "Maintenance options",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.tertiaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Move cart to cleaning position (slot 3) / Return to home
            _buildMaintenanceButton(
              title: _cleaningPositionActive ? "Return cart to home" : "Move cart for cleaning",
              subtitle: _cleaningPositionActive
                  ? "Moves back to position 0"
                  : "Moves cart to position 3 to place bucket",
              icon: Icons.cleaning_services,
              onPressed: _toggleCleaningPosition,
            ),

            // --- Keep: Light settings ---
            _buildMaintenanceButton(
              title: "Light settings",
              subtitle: "Switch between different light modes",
              icon: Icons.light_mode,
              onPressed: _showLightSettingsPopup,
            ),

            // --- Keep: Manual motor control ---
            // Manual motor control disabled for now (to be reintroduced later)

            const SizedBox(height: 40),

          ],
        ),
      ),
    );
  }
}
