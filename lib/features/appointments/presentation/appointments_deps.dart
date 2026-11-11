import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinic_veterinarians.dart';
import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinics.dart';
import '../domain/usecases/book_appointment.dart';
import '../domain/usecases/cancel_appointment.dart';
import '../domain/usecases/get_appointment.dart';
import '../domain/usecases/get_availability.dart';
import '../domain/usecases/get_booking_pets.dart';
import '../domain/usecases/get_my_appointments.dart';
import '../domain/usecases/reschedule_appointment.dart';

/// Casos de uso que necesitan las pantallas de Citas.
/// Incluye los de Clínicas porque agendar exige elegir clínica y veterinario.
class AppointmentsDeps {
  final GetMyAppointments getMyAppointments;
  final GetBookingPets getPets;
  final GetAvailability getAvailability;
  final BookAppointment book;
  final GetAppointment getAppointment;
  final CancelAppointment cancel;
  final RescheduleAppointment reschedule;
  final GetClinics getClinics;
  final GetClinicVeterinarians getVeterinarians;

  const AppointmentsDeps({
    required this.getMyAppointments,
    required this.getPets,
    required this.getAvailability,
    required this.book,
    required this.getAppointment,
    required this.cancel,
    required this.reschedule,
    required this.getClinics,
    required this.getVeterinarians,
  });
}
