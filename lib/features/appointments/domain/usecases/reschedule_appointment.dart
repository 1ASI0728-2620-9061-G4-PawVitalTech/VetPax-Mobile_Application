import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

class RescheduleAppointment {
  final AppointmentsRepository repository;
  RescheduleAppointment(this.repository);

  Future<Appointment> call(String id,
          {required String date, required String startTime}) =>
      repository.reschedule(id, date: date, startTime: startTime);
}
