import 'dart:async';

class FetchData {
  final List<FetchableService> _services = [];
  Timer? _pollingTimer;

  void addService(FetchableService service) {
    _services.add(service);
  }

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    stopPolling(); // Bestehende Timer stoppen
    _pollingTimer = Timer.periodic(interval, (timer) {
      _fetchAllServices();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  void _fetchAllServices() async {
    for (var service in _services) {
      try {
        await service.fetchAndSaveData();
        print("Service ${service.runtimeType} updated data successfully.");
      } catch (e) {
        print("Error fetching data for service ${service.runtimeType}: $e");
      }
    }
  }
}

abstract class FetchableService {
  Future<void> fetchAndSaveData();
}
