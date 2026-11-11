import '../entities/clinic.dart';
import '../repositories/clinics_repository.dart';

class GetClinics {
  final ClinicsRepository repository;
  GetClinics(this.repository);

  Future<List<Clinic>> call() => repository.getClinics();
}
