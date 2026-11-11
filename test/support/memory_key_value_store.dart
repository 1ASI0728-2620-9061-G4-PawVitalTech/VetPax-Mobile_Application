import 'package:vetpax_frontend/features/appointments/data/datasources/appointments_local_data_source.dart';

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, List<String>> data = {};
  @override Future<List<String>> readList(String key) async => List<String>.from(data[key] ?? const <String>[]);
  @override Future<void> writeList(String key, List<String> values) async { data[key] = List<String>.from(values); }
}
