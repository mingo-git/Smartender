import 'dart:async';
import 'package:flutter/foundation.dart';
import 'fetchable_service.dart';

class FetchdData extends ChangeNotifier {
  // Singleton-Implementierung
  static final FetchdData _instance = FetchdData._internal();

  factory FetchdData() {
    return _instance;
  }

  FetchdData._internal();

  final List<FetchableService> _services = [];
  Timer? _pollingTimer;

  /// Füge einen neuen Service hinzu, der regelmäßig abgefragt werden soll
  void addService(FetchableService service) {
    if (!_services.contains(service)) {
      _services.add(service);
    }
  }

  /// Starte das regelmäßige Abrufen der Daten
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    if (_pollingTimer != null) return; // Timer bereits gestartet

    _pollingTimer = Timer.periodic(interval, (timer) {
      _fetchAllServices();
    });

    print("Polling gestartet mit Intervall: ${interval.inSeconds} Sekunden");
  }

  /// Stoppe das regelmäßige Abrufen
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    print("Polling gestoppt.");
  }

  /// Hole die Daten von allen registrierten Services
  Future<void> _fetchAllServices() async {
    // Wir erstellen eine Kopie der Liste, um ConcurrentModification zu vermeiden,
    // falls ein Service während des fetch-Aufrufs entfernt oder hinzugefügt wird.
    final servicesCopy = List<FetchableService>.from(_services);

    for (var service in servicesCopy) {
      try {
        await service.fetchAndSaveData();
        print("Daten von ${service.runtimeType} aktualisiert.");
      } catch (e) {
        print("Fehler beim Abrufen der Daten für ${service.runtimeType}: $e");
      }
    }

    notifyListeners(); // Optional: Benachrichtige Listener über Aktualisierungen
  }

  /// Manuelles Abrufen aller Services (sofort)
  Future<void> fetchAllNow() async {
    await _fetchAllServices();
  }
}
