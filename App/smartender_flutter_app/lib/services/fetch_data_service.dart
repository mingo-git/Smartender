import 'dart:async';

class FetchdData {
  final List<FetchableService> _services = [];
  Timer? _pollingTimer;

  /// Füge einen neuen Service hinzu, der regelmäßig abgefragt werden soll
  void addService(FetchableService service) {
    _services.add(service);
  }

  /// Starte das regelmäßige Abrufen der Daten
  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    stopPolling(); // Vorherige Timer stoppen, falls vorhanden
    _pollingTimer = Timer.periodic(interval, (timer) {
      _fetchAllServices();
    });
  }

  /// Stoppe das regelmäßige Abrufen
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Hole die Daten von allen registrierten Services
  Future<void> _fetchAllServices() async {
    for (var service in _services) {
      try {
        await service.fetchAndSaveData();
      } catch (e) {
        print("Error fetching data for service ${service.runtimeType}: $e");
      }
    }
  }
}

/// Schnittstelle, die alle abrufbaren Services implementieren müssen
abstract class FetchableService {
  Future<void> fetchAndSaveData();
}
