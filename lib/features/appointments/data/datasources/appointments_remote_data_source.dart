import 'package:vetpax_frontend/core/api/api_client.dart';
import '../../domain/entities/appointment.dart';

/// Contratos del backend (AppointmentsController, rol owner):
///  - POST  /appointments                      -> AppointmentResponse
///  - GET   /appointments/availability?clinicId&veterinarianId&date
///  - GET   /appointments/{id}
///  - PATCH /appointments/{id}  { operation: "cancel" | "reschedule", date?, startTime? }
///  - GET   /pets                              -> [ { petId, name, species, ... } ]
class AppointmentsRemoteDataSource {
  final ApiClient api;
  AppointmentsRemoteDataSource(this.api);

  Map<String, dynamic> _object(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError('El servidor devolvió una respuesta vacía o inesperada.');
  }

  Future<List<BookingPet>> fetchPets() async {
    final data = await api.get('/pets');
    final items = data is List ? data : const <dynamic>[];
    return items
        .map((e) => BookingPet.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  Future<Availability> fetchAvailability({
    required String clinicId,
    required String veterinarianId,
    required String date,
  }) async {
    final data = await api.get('/appointments/availability', query: {
      'clinicId': clinicId,
      'veterinarianId': veterinarianId,
      'date': date,
    });
    return Availability.fromJson(_object(data));
  }

  Future<Appointment> book({
    required String petId,
    required String clinicId,
    required String veterinarianId,
    required String date,
    required String startTime,
    required String reason,
  }) async {
    final data = await api.post('/appointments', body: {
      'petId': petId,
      'clinicId': clinicId,
      'veterinarianId': veterinarianId,
      'date': date,
      'startTime': startTime,
      'reason': reason,
    });
    return Appointment.fromJson(_object(data));
  }

  Future<Appointment> fetch(String id) async =>
      Appointment.fromJson(_object(await api.get('/appointments/$id')));

  Future<Appointment> patch(String id, Map<String, dynamic> body) async =>
      Appointment.fromJson(_object(await api.patch('/appointments/$id', body: body)));
}
