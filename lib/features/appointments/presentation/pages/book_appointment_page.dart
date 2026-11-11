import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/clinic.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/veterinarian.dart';
import '../../domain/entities/appointment.dart';
import '../appointments_deps.dart';
import '../widgets/slot_selector.dart';

const List<String> _reasons = [
  'Consulta general',
  'Vacunación',
  'Control de seguimiento',
  'Revisión de tratamiento',
  'Emergencia',
  'Otro',
];

/// Agendar cita en un solo paso: paciente, clínica, veterinario, fecha, horario y motivo.
/// Devuelve la [Appointment] creada con Navigator.pop.
class BookAppointmentPage extends StatefulWidget {
  final AppointmentsDeps deps;
  final Clinic? initialClinic;
  final String? initialVeterinarianId;

  const BookAppointmentPage({
    super.key,
    required this.deps,
    this.initialClinic,
    this.initialVeterinarianId,
  });

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final TextEditingController _notes = TextEditingController();

  List<BookingPet> _pets = const [];
  List<Clinic> _clinics = const [];
  List<Veterinarian> _vets = const [];

  String? _petId;
  String? _clinicId;
  String? _vetId;
  DateTime? _date;
  String? _slot;
  String _reason = _reasons.first;

  bool _loading = true;
  String? _loadError;
  bool _loadingVets = false;
  bool _saving = false;
  int _slotsRefresh = 0;
  int _vetsRequest = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final pets = await widget.deps.getPets();
      final clinics = await widget.deps.getClinics();
      if (!mounted) return;
      setState(() {
        _pets = pets;
        _clinics = clinics;
        _petId = pets.length == 1 ? pets.first.id : null;
        final initial = widget.initialClinic;
        if (initial != null && clinics.any((c) => c.id == initial.id)) {
          _clinicId = initial.id;
        }
        _loading = false;
      });
      if (_clinicId != null) await _loadVets(preselect: widget.initialVeterinarianId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadVets({String? preselect}) async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    final request = ++_vetsRequest;
    setState(() {
      _loadingVets = true;
      _vets = const [];
      _vetId = null;
      _slot = null;
    });
    try {
      final vets = await widget.deps.getVeterinarians(clinicId);
      if (!mounted || request != _vetsRequest) return;
      setState(() {
        _vets = vets;
        if (preselect != null && vets.any((v) => v.id == preselect)) {
          _vetId = preselect;
        } else if (vets.length == 1) {
          _vetId = vets.first.id;
        }
        _loadingVets = false;
      });
    } catch (e) {
      if (!mounted || request != _vetsRequest) return;
      setState(() => _loadingVets = false);
      showAppMessage(context, friendlyError(e), isError: true);
    }
  }

  Future<void> _pickDate() async {
    final today = limaNow();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? first,
      firstDate: first,
      lastDate: first.add(const Duration(days: 90)),
      helpText: 'Fecha de la cita',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _slot = null;
    });
  }

  bool get _canSubmit =>
      !_saving &&
      _petId != null &&
      _clinicId != null &&
      _vetId != null &&
      _date != null &&
      _slot != null;

  String get _reasonText {
    final notes = _notes.text.trim();
    return notes.isEmpty ? _reason : '$_reason — $notes';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      final appointment = await widget.deps.book(
        petId: _petId!,
        clinicId: _clinicId!,
        veterinarianId: _vetId!,
        date: toDateOnly(_date!),
        startTime: _slot!,
        reason: _reasonText,
      );
      if (!mounted) return;
      Navigator.of(context).pop(appointment);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _slot = null;
        _slotsRefresh++; // el horario pudo ocuparse: se vuelve a consultar
      });
      showAppMessage(context, friendlyError(e), isError: true);
    }
  }

  Widget _label(String text, {String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: kTextDark))),
          if (hint != null) Text(hint, style: const TextStyle(fontSize: 12, color: kMuted)),
        ]),
      );

  InputDecoration get _fieldDecoration => InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: false,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agendar cita', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: kTextDark,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingState();
    if (_loadError != null) return ErrorState(message: _loadError!, onRetry: _init);
    if (_pets.isEmpty) {
      return const EmptyState(
          icon: Icons.pets,
          message: 'Primero registra una mascota en la pestaña Mascotas para poder agendar una cita.');
    }
    if (_clinics.isEmpty) {
      return const EmptyState(
          icon: Icons.local_hospital_outlined,
          message: 'Todavía no hay clínicas disponibles para agendar.');
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      const SizedBox(height: 12),
      const Text('Selecciona los datos para la consulta veterinaria.',
          style: TextStyle(color: kMuted)),
      _label('Paciente'),
      DropdownButtonFormField<String>(
        key: ValueKey('pet-$_petId'),
        initialValue: _petId,
        isExpanded: true,
        decoration: _fieldDecoration.copyWith(hintText: 'Elige a tu mascota'),
        items: [
          for (final pet in _pets)
            DropdownMenuItem(
                value: pet.id,
                child: Text(pet.species == null ? pet.name : '${pet.name} · ${pet.species}')),
        ],
        onChanged: (v) => setState(() => _petId = v),
      ),
      _label('Clínica veterinaria'),
      DropdownButtonFormField<String>(
        key: ValueKey('clinic-$_clinicId'),
        initialValue: _clinicId,
        isExpanded: true,
        decoration: _fieldDecoration.copyWith(hintText: 'Elige una clínica'),
        items: [
          for (final clinic in _clinics)
            DropdownMenuItem(value: clinic.id, child: Text(clinic.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) {
          if (v == null || v == _clinicId) return;
          setState(() => _clinicId = v);
          _loadVets();
        },
      ),
      _label('Veterinario'),
      if (_loadingVets)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()))
      else if (_clinicId != null && _vets.isEmpty)
        const Text('Esta clínica no tiene veterinarios activos por ahora.',
            style: TextStyle(color: kMuted))
      else
        DropdownButtonFormField<String>(
          key: ValueKey('vet-$_clinicId-${_vets.length}-$_vetId'),
          initialValue: _vetId,
          isExpanded: true,
          decoration: _fieldDecoration.copyWith(
              hintText: _clinicId == null ? 'Primero elige una clínica' : 'Elige un veterinario'),
          items: [
            for (final vet in _vets) DropdownMenuItem(value: vet.id, child: Text(vet.displayName)),
          ],
          onChanged: _clinicId == null
              ? null
              : (v) => setState(() {
                    _vetId = v;
                    _slot = null;
                  }),
        ),
      _label('Fecha'),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            alignment: Alignment.centerLeft,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.calendar_month),
        label: Text(_date == null ? 'Elige una fecha' : longDateEs(_date!)),
        onPressed: _pickDate,
      ),
      _label('Horario preferente'),
      SlotSelector(
        getAvailability: widget.deps.getAvailability,
        clinicId: _clinicId,
        veterinarianId: _vetId,
        date: _date,
        selected: _slot,
        refreshToken: _slotsRefresh,
        onSelected: (slot) => setState(() => _slot = slot),
      ),
      _label('Motivo de consulta'),
      DropdownButtonFormField<String>(
        initialValue: _reason,
        isExpanded: true,
        decoration: _fieldDecoration,
        items: [for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r))],
        onChanged: (v) => setState(() => _reason = v ?? _reason),
      ),
      _label('Observación adicional', hint: 'Opcional'),
      TextField(
        controller: _notes,
        maxLines: 3,
        maxLength: 400,
        decoration: _fieldDecoration.copyWith(
            hintText: 'Cuéntale al veterinario cualquier síntoma o consulta previa.'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        style: FilledButton.styleFrom(
            backgroundColor: kBrandBlue, minimumSize: const Size.fromHeight(52)),
        onPressed: _canSubmit ? _submit : null,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline),
        label: const Text('Confirmar cita'),
      ),
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
    ]);
  }
}
