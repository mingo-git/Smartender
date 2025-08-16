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
  bool _isFetching = false; // Flag, um doppelte Abrufe zu verhindern

  /// Füge einen neuen Service hinzu, der regelmäßig abgefragt werden soll
  void addService(FetchableService service) {
    if (!_services.any((s) => s.runtimeType == service.runtimeType)) {
      _services.add(service);
      print("Service hinzugefügt: ${service.runtimeType}");
    } else {
      print("Service bereits registriert: ${service.runtimeType}");
    }
  }

  /// Starte das regelmäßige Abrufen der Daten
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    stopPolling(); // Beende eventuell laufendes Polling

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
    if (_isFetching) {
      print("Abruf übersprungen: Ein Abruf läuft bereits.");
      return; // Kein Abruf starten, wenn einer bereits läuft
    }

    _isFetching = true; // Setze das Flag auf "läuft"
    print("Datenabruf gestartet...");

    final servicesCopy = List<FetchableService>.from(_services);

    for (var service in servicesCopy) {
      try {
        await service.fetchAndSaveData();
        print("Daten von ${service.runtimeType} aktualisiert.");
      } catch (e) {
        print("Fehler beim Abrufen der Daten für ${service.runtimeType}: $e");
      }
    }

    _isFetching = false; // Abruf abgeschlossen
    notifyListeners(); // Optional: Benachrichtige Listener über Aktualisierungen
    print("Datenabruf abgeschlossen.");
  }

  /// Manuelles Abrufen aller Services (sofort)
  Future<void> fetchAllNow() async {
    await _fetchAllServices();
  }

  /// Debugging: Liste aller registrierten Services anzeigen
  void debugServices() {
    print("Registrierte Services:");
    for (var service in _services) {
      print("- ${service.runtimeType}");
    }
  }
}
