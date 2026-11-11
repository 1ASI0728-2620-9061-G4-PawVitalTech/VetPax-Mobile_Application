import 'package:vetpax_frontend/core/api/api_client.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointments_repository.dart';
import '../datasources/appointments_local_data_source.dart';
import '../datasources/appointments_remote_data_source.dart';

class _Outcome {
  final Appointment? appointment;
  final Object? error;
  const _Outcome({this.appointment, this.error});
}

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource remote;
  final AppointmentsLocalDataSource local;
  AppointmentsRepositoryImpl({required this.remote, required this.local});

  @override
  Future<List<BookingPet>> getMyPets() => remote.fetchPets();

  @override
  Future<Availability> getAvailability({
    required String clinicId,
    required String veterinarianId,
    required String date,
  }) =>
      remote.fetchAvailability(
          clinicId: clinicId, veterinarianId: veterinarianId, date: date);

  @override
  Future<Appointment> book({
    required String petId,
    required String clinicId,
    required String veterinarianId,
    required String date,
    required String startTime,
    required String reason,
  }) async {
    final appointment = await remote.book(
      petId: petId,
      clinicId: clinicId,
      veterinarianId: veterinarianId,
      date: date,
      startTime: startTime,
      reason: reason,
    );
    // Se recuerda el id para poder listarla después en "Mis citas".
    await local.add(appointment.id);
    return appointment;
  }

  @override
  Future<List<Appointment>> getMyAppointments() async {
    final ids = await local.ids();
    if (ids.isEmpty) return const <Appointment>[];
    final outcomes = await Future.wait(ids.map(_load));
    final items = <Appointment>[];
    Object? firstError;
    for (final outcome in outcomes) {
      final appointment = outcome.appointment;
      if (appointment != null) {
        items.add(appointment);
      } else if (outcome.error != null) {
        firstError ??= outcome.error;
      }
    }
    // Si todas fallaron por un error real (red, sesión), se informa en lugar de mostrar vacío.
    if (items.isEmpty && firstError != null) throw firstError;
    return items;
  }

  Future<_Outcome> _load(String id) async {
    try {
      return _Outcome(appointment: await remote.fetch(id));
    } on VetPaxApiException catch (e) {
      if (e.statusCode == 404) {
        await local.remove(id); // la cita ya no existe
        return const _Outcome();
      }
      if (e.statusCode == 403) return const _Outcome(); // no es de esta cuenta
      return _Outcome(error: e);
    } catch (e) {
      return _Outcome(error: e);
    }
  }

  @override
  Future<Appointment> getAppointment(String id) => remote.fetch(id);

  @override
  Future<Appointment> cancel(String id) =>
      remote.patch(id, {'operation': 'cancel'});

  @override
  Future<Appointment> reschedule(String id,
          {required String date, required String startTime}) =>
      remote.patch(id, {
        'operation': 'reschedule',
        'date': date,
        'startTime': startTime,
      });
}
