import 'package:vetpax_frontend/core/utils/date_time_utils.dart';

/// Estados que expone el backend para una cita.
enum AppointmentStatus { pending, cancelled, attended, unknown }

AppointmentStatus appointmentStatusFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'pending':
      return AppointmentStatus.pending;
    case 'cancelled':
    case 'canceled':
      return AppointmentStatus.cancelled;
    case 'attended':
      return AppointmentStatus.attended;
    default:
      return AppointmentStatus.unknown;
  }
}

/// Cita (AppointmentResponse). Fecha y horas llegan como DateOnly/TimeOnly
/// en hora de Lima: "2026-11-10", "10:30:00".
class Appointment {
  final String id;
  final String petId;
  final String clinicId;
  final String veterinarianId;
  final String date;
  final String startTime;
  final String endTime;
  final String reason;
  final AppointmentStatus status;
  final String? clinicalAttentionId;

  const Appointment({
    required this.id,
    required this.petId,
    required this.clinicId,
    required this.veterinarianId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.reason,
    required this.status,
    this.clinicalAttentionId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: (json['appointmentId'] ?? json['id'] ?? '').toString(),
        petId: (json['petId'] ?? '').toString(),
        clinicId: (json['clinicId'] ?? '').toString(),
        veterinarianId: (json['veterinarianId'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        startTime: (json['startTime'] ?? '').toString(),
        endTime: (json['endTime'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        status: appointmentStatusFrom(json['status']?.toString()),
        clinicalAttentionId: json['clinicalAttentionId']?.toString(),
      );

  DateTime get dateOnly => parseDateOnly(date);

  DateTime get startsAt {
    final d = parseDateOnly(date);
    final t = parseTimeOnly(startTime);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  DateTime get endsAt {
    final d = parseDateOnly(date);
    final t = parseTimeOnly(endTime);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  String get startLabel => hhmm(startTime);
  String get endLabel => hhmm(endTime);

  /// Cita vigente: pendiente y que aún no terminó (hora de Lima).
  bool isUpcoming(DateTime nowLima) =>
      status == AppointmentStatus.pending && endsAt.isAfter(nowLima);

  /// Solo se puede reprogramar o cancelar una cita pendiente que aún no empezó.
  bool canModify(DateTime nowLima) =>
      status == AppointmentStatus.pending && startsAt.isAfter(nowLima);
}

/// Bloque libre de 30 minutos devuelto por la disponibilidad.
class AvailableSlot {
  final String startTime;
  final String endTime;
  const AvailableSlot({required this.startTime, required this.endTime});

  factory AvailableSlot.fromJson(Map<String, dynamic> json) => AvailableSlot(
        startTime: (json['startTime'] ?? '').toString(),
        endTime: (json['endTime'] ?? '').toString(),
      );

  String get label => hhmm(startTime);
}

/// Respuesta de GET /appointments/availability.
class Availability {
  final String clinicId;
  final String veterinarianId;
  final String date;
  final String timeZoneId;
  final int durationMinutes;
  final List<AvailableSlot> slots;

  const Availability({
    required this.clinicId,
    required this.veterinarianId,
    required this.date,
    required this.timeZoneId,
    required this.durationMinutes,
    required this.slots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'];
    return Availability(
      clinicId: (json['clinicId'] ?? '').toString(),
      veterinarianId: (json['veterinarianId'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      timeZoneId: (json['timeZoneId'] ?? 'America/Lima').toString(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      slots: (raw is List ? raw : const <dynamic>[])
          .map((e) => AvailableSlot.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

/// Mascota que el propietario puede elegir al agendar.
class BookingPet {
  final String id;
  final String name;
  final String? species;

  const BookingPet({required this.id, required this.name, this.species});

  factory BookingPet.fromJson(Map<String, dynamic> json) => BookingPet(
        id: (json['petId'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        species: json['species']?.toString(),
      );
}

/// Citas del propietario separadas en próximas y anteriores.
class MyAppointments {
  final List<Appointment> upcoming;
  final List<Appointment> past;
  const MyAppointments({required this.upcoming, required this.past});
}