import '../entities/appointment.dart';

abstract class AppointmentsRepository {
  Future<List<BookingPet>> getMyPets();

  Future<Availability> getAvailability({
    required String clinicId,
    required String veterinarianId,
    required String date,
  });

  Future<Appointment> book({
    required String petId,
    required String clinicId,
    required String veterinarianId,
    required String date,
    required String startTime,
    required String reason,
  });

  /// El backend no ofrece un listado de citas del propietario: se consultan
  /// una a una las citas creadas desde este dispositivo.
  Future<List<Appointment>> getMyAppointments();

  Future<Appointment> getAppointment(String id);
  Future<Appointment> cancel(String id);
  Future<Appointment> reschedule(String id,
      {required String date, required String startTime});
}
