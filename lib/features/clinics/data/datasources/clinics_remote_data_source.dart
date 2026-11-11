import 'package:vetpax_frontend/core/api/api_client.dart';
import '../../domain/entities/clinic.dart';
import '../../domain/entities/veterinarian.dart';

/// Contratos del backend (ClinicsController):
///  - GET /clinics?page&pageSize  -> { page, pageSize, totalCount, items: [...] }  (pageSize máx. 50)
///  - GET /clinics/{id}/veterinarians -> [ { veterinarianId } ]
class ClinicsRemoteDataSource {
  static const int pageSize = 50;
  static const int maxPages = 20; // tope de seguridad ante respuestas inconsistentes

  final ApiClient api;
  ClinicsRemoteDataSource(this.api);

  Future<List<Clinic>> fetchClinics() async {
    final clinics = <Clinic>[];
    var page = 1;
    var total = 0;
    do {
      final data = await api.get('/clinics',
          query: {'page': '$page', 'pageSize': '$pageSize'});
      final payload = Map<String, dynamic>.from(data as Map);
      final rawItems = payload['items'];
      final items = (rawItems is List ? rawItems : const <dynamic>[])
          .map((e) => Clinic.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      total = (payload['totalCount'] as num?)?.toInt() ?? items.length;
      if (items.isEmpty) break;
      clinics.addAll(items);
      page++;
    } while (clinics.length < total && page <= maxPages);
    return clinics;
  }

  Future<List<Veterinarian>> fetchVeterinarians(String clinicId) async {
    final data = await api.get('/clinics/$clinicId/veterinarians');
    final items = data is List ? data : const <dynamic>[];
    return items
        .map((e) => Veterinarian.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((v) => v.id.isNotEmpty)
        .toList();
  }
}
