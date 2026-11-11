import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/usecases/get_availability.dart';

/// Muestra los horarios libres (bloques de 30 min) de un veterinario en una fecha.
/// Se recarga solo cuando cambian clínica, veterinario, fecha o [refreshToken].
/// La pantalla que lo usa debe borrar su selección cuando cambie alguno de esos datos.
class SlotSelector extends StatefulWidget {
  final GetAvailability getAvailability;
  final String? clinicId;
  final String? veterinarianId;
  final DateTime? date;
  final String? selected; // startTime tal como lo devuelve la API ("10:30:00")
  final ValueChanged<String> onSelected;
  final int refreshToken;

  const SlotSelector({
    super.key,
    required this.getAvailability,
    required this.clinicId,
    required this.veterinarianId,
    required this.date,
    required this.selected,
    required this.onSelected,
    this.refreshToken = 0,
  });

  @override
  State<SlotSelector> createState() => _SlotSelectorState();
}

class _SlotSelectorState extends State<SlotSelector> {
  Availability? _availability;
  bool _loading = false;
  String? _error;
  int _request = 0;

  bool get _ready =>
      widget.clinicId != null && widget.veterinarianId != null && widget.date != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SlotSelector old) {
    super.didUpdateWidget(old);
    if (old.clinicId != widget.clinicId ||
        old.veterinarianId != widget.veterinarianId ||
        old.date != widget.date ||
        old.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    if (!_ready) {
      setState(() {
        _availability = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.getAvailability(
        clinicId: widget.clinicId!,
        veterinarianId: widget.veterinarianId!,
        date: toDateOnly(widget.date!),
      );
      if (!mounted || request != _request) return; // llegó una respuesta vieja
      setState(() {
        _availability = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  /// Si la fecha es hoy, oculta los horarios que ya pasaron (hora de Lima).
  List<AvailableSlot> _visibleSlots(Availability availability) {
    final date = widget.date!;
    final now = limaNow();
    return availability.slots.where((slot) {
      final t = parseTimeOnly(slot.startTime);
      return DateTime(date.year, date.month, date.day, t.hour, t.minute).isAfter(now);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Text('Elige clínica, veterinario y fecha para ver los horarios.',
          style: TextStyle(color: kMuted));
    }
    if (_loading) {
      return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SizedBox(height: 150, child: ErrorState(message: _error!, onRetry: _load));
    }
    final availability = _availability;
    if (availability == null) return const SizedBox.shrink();
    final slots = _visibleSlots(availability);
    if (slots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No hay horarios libres para esta fecha. Prueba con otro día.',
            style: TextStyle(color: kMuted)),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Horarios en hora de Lima · ${availability.durationMinutes} min por cita',
          style: const TextStyle(fontSize: 12, color: kMuted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final slot in slots)
          ChoiceChip(
            label: Text('${slot.label} hrs'),
            selected: widget.selected == slot.startTime,
            onSelected: (_) => widget.onSelected(slot.startTime),
          ),
      ]),
    ]);
  }
}
