import '../../domain/entities/clinic.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/repositories/clinics_repository.dart';
import '../datasources/clinics_remote_data_source.dart';

class ClinicsRepositoryImpl implements ClinicsRepository {
  final ClinicsRemoteDataSource remote;
  ClinicsRepositoryImpl(this.remote);

  @override
  Future<List<Clinic>> getClinics() async {
    final clinics = await remote.fetchClinics();
    clinics.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return clinics;
  }

  @override
  Future<List<Veterinarian>> getVeterinarians(String clinicId) =>
      remote.fetchVeterinarians(clinicId);
}
