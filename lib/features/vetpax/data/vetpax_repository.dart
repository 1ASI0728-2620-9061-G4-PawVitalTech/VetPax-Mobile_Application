import 'package:vetpax_frontend/core/api/api_client.dart';

// Adaptador único a los contratos JSON del backend de VetPax.
// Las operaciones del propietario son las únicas expuestas en la app móvil.
class VetPaxRepository {
  final ApiClient api;
  VetPaxRepository(this.api);

  static Map<String, dynamic> object(dynamic data) => Map<String, dynamic>.from(data as Map);
  static List<Map<String, dynamic>> list(dynamic data) =>
      (data as List).map((v) => object(v)).toList();

  Future<Map<String, dynamic>> me() async => object(await api.get('/auth/me'));
  Future<List<Map<String, dynamic>>> myPets() async => list(await api.get('/pets'));
  Future<Map<String, dynamic>> pet(String id) async => object(await api.get('/pets/$id'));
  Future<Map<String, dynamic>> createPet(Map<String, dynamic> values) async =>
      object(await api.post('/pets', body: values));
  Future<Map<String, dynamic>> clinicalHistory(String petId) async =>
      object(await api.get('/pets/$petId/clinical-records'));

  Future<List<Map<String, dynamic>>> clinics({int page = 1}) async {
    final payload = object(await api.get('/clinics', query: {'page': '$page', 'pageSize': '20'}));
    return list(payload['items']);
  }
  Future<List<Map<String, dynamic>>> veterinarians(String clinicId) async =>
      list(await api.get('/clinics/$clinicId/veterinarians'));
  Future<Map<String, dynamic>> availability({required String clinicId,
    required String veterinarianId, required String date}) async =>
      object(await api.get('/appointments/availability', query: {
        'clinicId': clinicId, 'veterinarianId': veterinarianId, 'date': date,
      }));
  Future<Map<String, dynamic>> bookAppointment({required String petId,
      required String clinicId, required String veterinarianId,
      required String date, required String startTime, required String reason}) async =>
      object(await api.post('/appointments', body: {
        'petId': petId, 'clinicId': clinicId, 'veterinarianId': veterinarianId,
        'date': date, 'startTime': startTime, 'reason': reason,
      }));
  Future<Map<String, dynamic>> appointment(String id) async =>
      object(await api.get('/appointments/$id'));
  Future<Map<String, dynamic>> cancelAppointment(String id) async =>
      object(await api.patch('/appointments/$id', body: {'operation': 'cancel'}));
  Future<Map<String, dynamic>> rescheduleAppointment(String id, String date,
      String time) async => object(await api.patch('/appointments/$id', body: {
      'operation': 'reschedule', 'date': date, 'startTime': time,
      }));

  Future<List<Map<String, dynamic>>> medicationPlans(String petId) async =>
      list(await api.get('/pets/$petId/medication-plans'));
  Future<List<Map<String, dynamic>>> medicationDoses(String planId) async =>
      list(await api.get('/medication-plans/$planId/doses'));
  Future<Map<String, dynamic>> administer(String doseId) async =>
      object(await api.post('/medication-doses/$doseId/administrations', body: {
        'administeredAtUtc': DateTime.now().toUtc().toIso8601String(),
      }));
  Future<Map<String, dynamic>> setMedicationReminders(String planId, bool value) async =>
      object(await api.patch('/medication-plans/$planId/reminders', body: {'enabled': value}));
  Future<Map<String, dynamic>?> activeFeedingPlan(String petId) async {
    try {
      return object(await api.get('/pets/$petId/feeding-plans/active'));
    } on VetPaxApiException catch (e) {
      if (e.statusCode == 404) return null; // Sin plan activo es normal.
      rethrow;
    }
  }
  Future<Map<String, dynamic>> setFeedingReminders(String planId, bool value) async =>
      object(await api.patch('/feeding-plans/$planId/reminders', body: {'enabled': value}));
  Future<Map<String, dynamic>> adherence() async => object(await api.get('/me/adherence'));
  Future<Map<String, dynamic>> permissions() async => object(await api.get('/auth/me/permissions'));
}
