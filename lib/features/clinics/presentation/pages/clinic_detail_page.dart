import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import '../../domain/entities/clinic.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/usecases/get_clinic_veterinarians.dart';
import 'clinics_view.dart';

class ClinicDetailPage extends StatefulWidget {
  final Clinic clinic;
  final GetClinicVeterinarians getVeterinarians;
  final BookAppointmentCallback onBook;

  const ClinicDetailPage({
    super.key,
    required this.clinic,
    required this.getVeterinarians,
    required this.onBook,
  });

  @override
  State<ClinicDetailPage> createState() => _ClinicDetailPageState();
}

class _ClinicDetailPageState extends State<ClinicDetailPage> {
  late Future<List<Veterinarian>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getVeterinarians(widget.clinic.id);
  }

  void _reload() =>
      setState(() => _future = widget.getVeterinarians(widget.clinic.id));

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showAppMessage(context, '$label copiado');
  }

  Widget _infoRow(IconData icon, String label, String value, {bool copyable = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: kBrandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: kMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
          if (copyable)
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copy(label, value),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final clinic = widget.clinic;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(clinic.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: kTextDark,
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: kBrandBlue, minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.event_available),
            label: const Text('Agendar cita en esta clínica'),
            onPressed: () => widget.onBook(context, clinic, null),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                _infoRow(Icons.place_outlined, 'Dirección',
                    clinic.address.isEmpty ? 'Sin dirección registrada' : clinic.address),
                if (clinic.phone != null)
                  _infoRow(Icons.phone_outlined, 'Teléfono', clinic.phone!, copyable: true),
                if (clinic.email != null)
                  _infoRow(Icons.email_outlined, 'Correo de contacto', clinic.email!, copyable: true),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Veterinarios disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextDark)),
          const SizedBox(height: 8),
          FutureBuilder<List<Veterinarian>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                    padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return SizedBox(
                    height: 160,
                    child: ErrorState(message: friendlyError(snapshot.error!), onRetry: _reload));
              }
              final vets = snapshot.data ?? const <Veterinarian>[];
              if (vets.isEmpty) {
                return const EmptyState(
                    icon: Icons.medical_services_outlined,
                    message: 'Esta clínica aún no tiene veterinarios activos.');
              }
              return Column(children: [
                for (final vet in vets)
                  Card(
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                          backgroundColor: kSoftBlue,
                          child: Icon(Icons.medical_services_outlined, color: kBrandBlue)),
                      title: Text(vet.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Toca para agendar con este veterinario'),
                      trailing: const Icon(Icons.calendar_month, color: kBrandBlue),
                      onTap: () => widget.onBook(context, clinic, vet),
                    ),
                  ),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}
