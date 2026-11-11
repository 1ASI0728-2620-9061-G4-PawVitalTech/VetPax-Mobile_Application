import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import '../../domain/entities/appointment.dart';
import '../appointments_deps.dart';
import '../widgets/slot_selector.dart';

/// Hoja inferior para elegir un nuevo día y horario.
/// Devuelve la [Appointment] actualizada con Navigator.pop.
class RescheduleSheet extends StatefulWidget {
  final AppointmentsDeps deps;
  final Appointment appointment;

  const RescheduleSheet({super.key, required this.deps, required this.appointment});

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late DateTime _date;
  String? _slot;
  bool _saving = false;
  int _refresh = 0;

  @override
  void initState() {
    super.initState();
    final today = limaNow();
    final current = widget.appointment.dateOnly;
    final first = DateTime(today.year, today.month, today.day);
    _date = current.isBefore(first) ? first : current;
  }

  Future<void> _pickDate() async {
    final today = limaNow();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: first,
      lastDate: first.add(const Duration(days: 90)),
      helpText: 'Nueva fecha',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _slot = null;
    });
  }

  bool get _isSameSchedule =>
      _slot != null &&
      toDateOnly(_date) == widget.appointment.date &&
      hhmm(_slot!) == widget.appointment.startLabel;

  Future<void> _confirm() async {
    final slot = _slot;
    if (slot == null || _saving || _isSameSchedule) return;
    setState(() => _saving = true);
    try {
      final updated = await widget.deps.reschedule(widget.appointment.id,
          date: toDateOnly(_date), startTime: slot);
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _slot = null;
        _refresh++;
      });
      showAppMessage(context, friendlyError(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Reprogramar cita',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kTextDark)),
            const SizedBox(height: 4),
            Text(
                'Actual: ${mediumDateEs(widget.appointment.dateOnly)} · ${widget.appointment.startLabel} hrs',
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.calendar_month),
              label: Text(longDateEs(_date)),
              onPressed: _pickDate,
            ),
            const SizedBox(height: 16),
            SlotSelector(
              getAvailability: widget.deps.getAvailability,
              clinicId: widget.appointment.clinicId,
              veterinarianId: widget.appointment.veterinarianId,
              date: _date,
              selected: _slot,
              refreshToken: _refresh,
              onSelected: (slot) => setState(() => _slot = slot),
            ),
            if (_isSameSchedule)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Elige un horario distinto al actual.',
                    style: TextStyle(color: kDanger, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: kBrandBlue, minimumSize: const Size.fromHeight(50)),
              onPressed: (_slot == null || _saving || _isSameSchedule) ? null : _confirm,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.event_repeat),
              label: const Text('Confirmar nuevo horario'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ]),
        ),
      ),
    );
  }
}