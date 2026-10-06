import 'package:tidal2wiim/services/tidal_auth_service.dart';

/// Ausschließlich für Tests. Hier stehen niemals echte TIDAL-Zugangsdaten.
class MemorySessionStore implements TidalSessionStore {
  MemorySessionStore([this.value]);
  String? value;
  bool failWrites = false;
  int writes = 0;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? newValue) async {
    if (failWrites) throw StateError('simulierter Speicherfehler');
    writes++;
    value = newValue;
  }
}
