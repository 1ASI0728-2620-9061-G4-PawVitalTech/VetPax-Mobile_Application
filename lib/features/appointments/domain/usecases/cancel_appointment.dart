import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class CancelAppointment {
  final AppointmentsRepository repository;
  CancelAppointment(this.repository);
  Future<Appointment> call(String id) => repository.cancel(id);
}
