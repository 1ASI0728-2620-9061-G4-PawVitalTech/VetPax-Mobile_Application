import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/clinic.dart';
import '../../domain/entities/appointment.dart';
import '../appointments_deps.dart';
import '../widgets/appointment_card.dart';
import 'appointment_detail_page.dart';
import 'book_appointment_page.dart';

class _ViewData {
  final MyAppointments appointments;
  final Map<String, BookingPet> pets;
  final Map<String, Clinic> clinics;
  const _ViewData(this.appointments, this.pets, this.clinics);
}

Future<T> _safe<T>(Future<T> future, T fallback) async {
  try {
    return await future;
  } catch (_) {
    return fallback;
  }
}

/// Lista de citas del propietario (Próximas / Anteriores) con acceso a agendar.
class AppointmentsView extends StatefulWidget {
  final AppointmentsDeps deps;
  const AppointmentsView({super.key, required this.deps});

  @override
  State<AppointmentsView> createState() => AppointmentsViewState();
}

class AppointmentsViewState extends State<AppointmentsView>
    with AutomaticKeepAliveClientMixin {
  late Future<_ViewData> _future;
  bool _showUpcoming = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  /// Vuelve a cargar la lista (lo usa la pantalla contenedora tras agendar).
  void reload() {
    if (!mounted) return;
    setState(() => _future = _load());
  }

  Future<_ViewData> _load() async {
    final appointmentsFuture = widget.deps.getMyAppointments();
    final petsFuture = _safe(widget.deps.getPets(), const <BookingPet>[]);
    final clinicsFuture = _safe(widget.deps.getClinics(), const <Clinic>[]);
    final appointments = await appointmentsFuture;
    final pets = await petsFuture;
    final clinics = await clinicsFuture;
    return _ViewData(
      appointments,
      {for (final p in pets) p.id: p},
      {for (final c in clinics) c.id: c},
    );
  }

  Future<void> _book() async {
    final created = await Navigator.of(context).push<Appointment>(
      MaterialPageRoute<Appointment>(builder: (_) => BookAppointmentPage(deps: widget.deps)),
    );
    if (created == null || !mounted) return;
    showAppMessage(context,
        'Cita agendada para el ${shortDateEs(created.dateOnly)} a las ${created.startLabel} hrs');
    setState(() {
      _showUpcoming = true;
      _future = _load();
    });
  }

  Future<void> _openDetail(Appointment appointment, _ViewData data) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AppointmentDetailPage(
          deps: widget.deps,
          appointment: appointment,
          pet: data.pets[appointment.petId],
          clinic: data.clinics[appointment.clinicId],
        ),
      ),
    );
    if (changed == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<_ViewData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const LoadingState();
        if (snapshot.hasError) {
          return ErrorState(message: friendlyError(snapshot.error!), onRetry: reload);
        }
        final data = snapshot.data!;
        final upcoming = data.appointments.upcoming;
        final past = data.appointments.past;
        final shown = _showUpcoming ? upcoming : past;
        final now = limaNow();

        return RefreshIndicator(
          onRefresh: () async {
            reload();
            await _future;
          },
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Citas veterinarias',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
                  SizedBox(height: 2),
                  Text('Seguimiento médico de tus mascotas', style: TextStyle(color: kMuted)),
                ]),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kBrandBlue),
                onPressed: _book,
                icon: const Icon(Icons.add),
                label: const Text('Agendar'),
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: true, label: Text('Próximas (${upcoming.length})')),
                  ButtonSegment(value: false, label: Text('Anteriores (${past.length})')),
                ],
                selected: {_showUpcoming},
                onSelectionChanged: (s) => setState(() => _showUpcoming = s.first),
              ),
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              EmptyState(
                icon: Icons.event_available_outlined,
                message: _showUpcoming
                    ? 'No tienes citas próximas. Toca "Agendar" para reservar una.'
                    : 'Aún no tienes citas anteriores.',
              )
            else
              for (final appointment in shown)
                AppointmentCard(
                  appointment: appointment,
                  petName: data.pets[appointment.petId]?.name ?? 'Mascota',
                  petSpecies: data.pets[appointment.petId]?.species,
                  clinicName: data.clinics[appointment.clinicId]?.name ?? 'Clínica',
                  nowLima: now,
                  onTap: () => _openDetail(appointment, data),
                ),
            const SizedBox(height: 8),
            const Text(
              'Aquí aparecen las citas agendadas desde esta aplicación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: kMuted),
            ),
          ]),
        );
      },
    );
  }
}