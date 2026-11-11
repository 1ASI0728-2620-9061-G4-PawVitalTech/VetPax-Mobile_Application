import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class BookAppointment {
  final AppointmentsRepository repository;
  BookAppointment(this.repository);

  Future<Appointment> call({
    required String petId,
    required String clinicId,
    required String veterinarianId,
    required String date,
    required String startTime,
    required String reason,
  }) =>
      repository.book(
        petId: petId,
        clinicId: clinicId,
        veterinarianId: veterinarianId,
        date: date,
        startTime: startTime,
        reason: reason,
      );
}
