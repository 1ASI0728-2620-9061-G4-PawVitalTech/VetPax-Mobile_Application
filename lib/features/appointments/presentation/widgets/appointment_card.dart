import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_status_chip.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String petName;
  final String? petSpecies;
  final String clinicName;
  final DateTime nowLima;
  final VoidCallback onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.petName,
    required this.clinicName,
    required this.nowLima,
    required this.onTap,
    this.petSpecies,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppointmentStatusChip.accent(appointment, nowLima);
    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, color: accent),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(petName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark)),
                      if (petSpecies != null)
                        Text(petSpecies!, style: const TextStyle(color: kMuted, fontSize: 13)),
                    ]),
                  ),
                  AppointmentStatusChip(appointment: appointment, nowLima: nowLima),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: kBrandBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        '${mediumDateEs(appointment.dateOnly)} · ${appointment.startLabel} hrs',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.local_hospital_outlined, size: 18, color: kMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(clinicName, style: const TextStyle(color: kMuted))),
                ]),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: kSoftBlue, borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Motivo de consulta',
                        style: TextStyle(fontSize: 11, color: kMuted)),
                    Text(appointment.reason.isEmpty ? 'Sin motivo indicado' : appointment.reason,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(onPressed: onTap, child: const Text('Ver detalle')),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
