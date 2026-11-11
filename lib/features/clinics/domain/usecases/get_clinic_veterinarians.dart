import '../entities/veterinarian.dart';
import '../repositories/clinics_repository.dart';

class GetClinicVeterinarians {
  final ClinicsRepository repository;
  GetClinicVeterinarians(this.repository);

  Future<List<Veterinarian>> call(String clinicId) =>
      repository.getVeterinarians(clinicId);
}
