import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import '../../domain/entities/appointment.dart';

class AppointmentStatusChip extends StatelessWidget {
  final Appointment appointment;
  final DateTime nowLima;
  const AppointmentStatusChip({super.key, required this.appointment, required this.nowLima});

  @override
  Widget build(BuildContext context) {
    final (String label, Color background, Color foreground) = switch (appointment.status) {
      AppointmentStatus.pending when appointment.isUpcoming(nowLima) =>
        ('Programada', const Color(0xFFDBEAFE), kBrandBlue),
      AppointmentStatus.pending =>
        ('Vencida', const Color(0xFFF3F4F6), kMuted),
      AppointmentStatus.cancelled =>
        ('Cancelada', const Color(0xFFFEE2E2), kDanger),
      AppointmentStatus.attended =>
        ('Atendida', const Color(0xFFD1FAE5), kOk),
      AppointmentStatus.unknown =>
        ('Sin estado', const Color(0xFFF3F4F6), kMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  /// Color de la franja lateral de la tarjeta.
  static Color accent(Appointment a, DateTime nowLima) {
    switch (a.status) {
      case AppointmentStatus.pending:
        return a.isUpcoming(nowLima) ? kBrandBlue : kMuted;
      case AppointmentStatus.cancelled:
        return kDanger;
      case AppointmentStatus.attended:
        return kOk;
      case AppointmentStatus.unknown:
        return kMuted;
    }
  }
}