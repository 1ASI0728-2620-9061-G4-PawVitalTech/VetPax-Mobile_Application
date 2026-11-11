import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import '../../domain/entities/clinic.dart';
import '../../domain/entities/veterinarian.dart';
import '../../domain/usecases/get_clinic_veterinarians.dart';
import '../../domain/usecases/get_clinics.dart';
import '../widgets/clinic_card.dart';
import 'clinic_detail_page.dart';

/// Callback que la pantalla contenedora usa para iniciar el agendamiento.
/// Así Clínicas no depende de la feature de Citas.
typedef BookAppointmentCallback = void Function(
    BuildContext context, Clinic clinic, Veterinarian? veterinarian);

/// Directorio de clínicas con búsqueda. Se muestra dentro de la pestaña de Citas.
class ClinicsView extends StatefulWidget {
  final GetClinics getClinics;
  final GetClinicVeterinarians getVeterinarians;
  final BookAppointmentCallback onBook;

  const ClinicsView({
    super.key,
    required this.getClinics,
    required this.getVeterinarians,
    required this.onBook,
  });

  @override
  State<ClinicsView> createState() => _ClinicsViewState();
}

class _ClinicsViewState extends State<ClinicsView>
    with AutomaticKeepAliveClientMixin {
  late Future<List<Clinic>> _future;
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = widget.getClinics();
  }

  void _reload() => setState(() => _future = widget.getClinics());

  void _open(Clinic clinic) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ClinicDetailPage(
        clinic: clinic,
        getVeterinarians: widget.getVeterinarians,
        onBook: widget.onBook,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Clinic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingState();
        }
        if (snapshot.hasError) {
          return ErrorState(message: friendlyError(snapshot.error!), onRetry: _reload);
        }
        final clinics = snapshot.data ?? const <Clinic>[];
        final visible = clinics.where((c) => c.matches(_query)).toList();
        return RefreshIndicator(
          onRefresh: () async {
            _reload();
            await _future;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Clínicas veterinarias',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kTextDark)),
              const SizedBox(height: 4),
              const Text('Encuentra una clínica y agenda tu cita.',
                  style: TextStyle(color: kMuted)),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o dirección',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 14),
              if (clinics.isEmpty)
                const EmptyState(
                    icon: Icons.local_hospital_outlined,
                    message: 'Todavía no hay clínicas registradas.')
              else if (visible.isEmpty)
                const EmptyState(
                    icon: Icons.search_off, message: 'No encontramos clínicas con esa búsqueda.')
              else
                for (final clinic in visible)
                  ClinicCard(clinic: clinic, onTap: () => _open(clinic)),
            ],
          ),
        );
      },
    );
  }
}