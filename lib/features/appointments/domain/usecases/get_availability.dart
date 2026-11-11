import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class GetAvailability {
  final AppointmentsRepository repository;
  GetAvailability(this.repository);

  Future<Availability> call({
    required String clinicId,
    required String veterinarianId,
    required String date,
  }) =>
      repository.getAvailability(
          clinicId: clinicId, veterinarianId: veterinarianId, date: date);
}
