import 'package:vetpax_frontend/core/storage/token_storage.dart';

/// Almacén clave-lista mínimo. Se abstrae para poder probar sin plugins.
abstract class KeyValueStore {
  Future<List<String>> readList(String key);
  Future<void> writeList(String key, List<String> values);
}

/// Registro local de las citas creadas desde este dispositivo.
///
/// El backend no tiene un endpoint "mis citas" para el propietario, así que
/// se guardan los identificadores (nunca datos médicos) por usuario y luego
/// se consultan con GET /appointments/{id}.
class AppointmentsLocalDataSource {
  final KeyValueStore store;
  final TokenStorage tokenStorage;
  AppointmentsLocalDataSource({required this.store, required this.tokenStorage});

  Future<String> _key() async {
    final userId = await tokenStorage.getUserId();
    return 'vp_appointments_${userId ?? 'anonymous'}';
  }

  Future<List<String>> ids() async => store.readList(await _key());

  Future<void> add(String id) async {
    final key = await _key();
    final current = await store.readList(key);
    if (current.contains(id)) return;
    await store.writeList(key, [...current, id]);
  }

  Future<void> remove(String id) async {
    final key = await _key();
    final current = await store.readList(key);
    if (!current.contains(id)) return;
    await store.writeList(key, current.where((e) => e != id).toList());
  }
}
