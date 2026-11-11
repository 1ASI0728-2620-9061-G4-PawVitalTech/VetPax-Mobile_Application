import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import '../entities/appointment.dart';
import '../repositories/appointments_repository.dart';

/// Obtiene las citas del propietario y las clasifica con la hora de Lima:
/// próximas (ascendente) y anteriores (la más reciente primero).
class GetMyAppointments {
  final AppointmentsRepository repository;
  final DateTime Function() clock;

  GetMyAppointments(this.repository, {DateTime Function()? clock})
      : clock = clock ?? limaNow;

  Future<MyAppointments> call() async {
    final all = await repository.getMyAppointments();
    final now = clock();
    final upcoming = all.where((a) => a.isUpcoming(now)).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    final past = all.where((a) => !a.isUpcoming(now)).toList()
      ..sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return MyAppointments(upcoming: upcoming, past: past);
  }
}
