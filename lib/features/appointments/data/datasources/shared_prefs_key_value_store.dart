import 'package:shared_preferences/shared_preferences.dart';
import 'appointments_local_data_source.dart';

/// Implementación de KeyValueStore sobre shared_preferences.
class SharedPrefsKeyValueStore implements KeyValueStore {
  @override
  Future<List<String>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? <String>[];
  }

  @override
  Future<void> writeList(String key, List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, values);
  }
}
