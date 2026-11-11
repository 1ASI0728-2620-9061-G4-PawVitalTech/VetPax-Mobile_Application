import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class GetAppointment {
  final AppointmentsRepository repository;
  GetAppointment(this.repository);
  Future<Appointment> call(String id) => repository.getAppointment(id);
}
