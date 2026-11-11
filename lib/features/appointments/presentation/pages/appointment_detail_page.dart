import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/clinic.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/veterinarian.dart';
import '../../domain/entities/appointment.dart';
import '../appointments_deps.dart';
import '../widgets/appointment_status_chip.dart';
import 'reschedule_sheet.dart';

/// Detalle de una cita con acciones de reprogramar y cancelar.
/// Al cerrarse devuelve `true` si la cita cambió (para que la lista se actualice).
class AppointmentDetailPage extends StatefulWidget {
  final AppointmentsDeps deps;
  final Appointment appointment;
  final BookingPet? pet;
  final Clinic? clinic;

  const AppointmentDetailPage({
    super.key,
    required this.deps,
    required this.appointment,
    this.pet,
    this.clinic,
  });

  @override
  State<AppointmentDetailPage> createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  late Appointment _appointment;
  bool _changed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
    _refresh();
  }

  /// Actualiza en silencio con el estado real del servidor.
  Future<void> _refresh() async {
    try {
      final latest = await widget.deps.getAppointment(_appointment.id);
      if (!mounted) return;
      setState(() => _appointment = latest);
    } catch (_) {
      // Se conserva lo que ya se mostraba; no es un error para la persona usuaria.
    }
  }

  Future<void> _reschedule() async {
    final updated = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => RescheduleSheet(deps: widget.deps, appointment: _appointment),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _appointment = updated;
      _changed = true;
    });
    showAppMessage(context, 'Cita reprogramada');
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar la cita?'),
        content: const Text('El horario quedará libre para otras personas. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await widget.deps.cancel(_appointment.id);
      if (!mounted) return;
      setState(() {
        _appointment = updated;
        _changed = true;
        _busy = false;
      });
      showAppMessage(context, 'Cita cancelada');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showAppMessage(context, friendlyError(e), isError: true);
    }
  }

  Widget _section(List<Widget> children) => Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _kv(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: kSoftBlue, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: kBrandBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final now = limaNow();
    final a = _appointment;
    final clinic = widget.clinic;
    final pet = widget.pet;
    final vet = Veterinarian(id: a.veterinarianId);
    final canModify = a.canModify(now);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detalle de cita', style: TextStyle(fontWeight: FontWeight.bold)),
          foregroundColor: kTextDark,
          backgroundColor: Colors.white,
        ),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _section([
              AppointmentStatusChip(appointment: a, nowLima: now),
              const SizedBox(height: 10),
              const Text('FECHA PROGRAMADA',
                  style: TextStyle(fontSize: 11, color: kMuted, letterSpacing: 0.6)),
              const SizedBox(height: 2),
              Text(longDateEs(a.dateOnly),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: kSoftBlue, borderRadius: BorderRadius.circular(10)),
                child: Text('${a.startLabel} – ${a.endLabel} hrs',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: kBrandBlue)),
              ),
              const SizedBox(height: 6),
              const Text('Horario de Lima', style: TextStyle(fontSize: 12, color: kMuted)),
            ]),
            _section([
              _kv(Icons.pets, 'Paciente',
                  pet == null ? 'Mascota' : (pet.species == null ? pet.name : '${pet.name} · ${pet.species}')),
              _kv(Icons.local_hospital_outlined, 'Centro veterinario', clinic?.name ?? 'Clínica'),
              if (clinic != null && clinic.address.isNotEmpty)
                _kv(Icons.place_outlined, 'Dirección', clinic.address),
              if (clinic?.phone != null) _kv(Icons.phone_outlined, 'Teléfono', clinic!.phone!),
              _kv(Icons.medical_services_outlined, 'Veterinario a cargo', vet.displayName),
            ]),
            _section([
              const Text('Motivo de consulta',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 6),
              Text(a.reason.isEmpty ? 'Sin motivo indicado' : a.reason),
            ]),
            const SizedBox(height: 4),
            if (canModify) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: kBrandBlue, minimumSize: const Size.fromHeight(52)),
                onPressed: _busy ? null : _reschedule,
                icon: const Icon(Icons.event_repeat),
                label: const Text('Reprogramar cita'),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: kDanger),
                onPressed: _busy ? null : _cancel,
                icon: _busy
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar cita'),
              ),
            ] else if (a.status == AppointmentStatus.pending)
              const Text('Esta cita ya comenzó o terminó, por eso no se puede modificar.',
                  textAlign: TextAlign.center, style: TextStyle(color: kMuted)),
          ]),
        ),
      ),
    );
  }
}