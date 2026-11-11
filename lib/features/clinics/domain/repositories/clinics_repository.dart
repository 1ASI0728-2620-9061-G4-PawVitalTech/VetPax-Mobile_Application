import '../entities/clinic.dart';
import '../entities/veterinarian.dart';

abstract class ClinicsRepository {
  /// Directorio completo de clínicas, ordenado por nombre.
  Future<List<Clinic>> getClinics();

  /// Veterinarios activos de una clínica.
  Future<List<Veterinarian>> getVeterinarians(String clinicId);
}
