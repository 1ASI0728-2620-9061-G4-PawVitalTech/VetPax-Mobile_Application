import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/features/appointments/domain/entities/appointment.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/book_appointment.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/cancel_appointment.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/get_appointment.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/get_availability.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/get_booking_pets.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/get_my_appointments.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/reschedule_appointment.dart';
import 'package:vetpax_frontend/features/appointments/presentation/appointments_deps.dart';
import 'package:vetpax_frontend/features/appointments/presentation/pages/appointments_view.dart';
import 'package:vetpax_frontend/features/appointments/presentation/pages/book_appointment_page.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/clinic.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/veterinarian.dart';
import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinic_veterinarians.dart';
import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinics.dart';
import 'package:vetpax_frontend/features/clinics/presentation/pages/clinics_view.dart';

/// Pestaña "Citas": reúne las features de Citas (lista, agendar, detalle) y de
/// Clínicas (directorio). Es la única pieza que conoce a ambas.
class CitasTab extends StatefulWidget {
  const CitasTab({super.key});

  @override
  State<CitasTab> createState() => _CitasTabState();
}

class _CitasTabState extends State<CitasTab> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final GlobalKey<AppointmentsViewState> _appointmentsKey = GlobalKey<AppointmentsViewState>();

  late final AppointmentsDeps _deps = AppointmentsDeps(
    getMyAppointments: injector<GetMyAppointments>(),
    getPets: injector<GetBookingPets>(),
    getAvailability: injector<GetAvailability>(),
    book: injector<BookAppointment>(),
    getAppointment: injector<GetAppointment>(),
    cancel: injector<CancelAppointment>(),
    reschedule: injector<RescheduleAppointment>(),
    getClinics: injector<GetClinics>(),
    getVeterinarians: injector<GetClinicVeterinarians>(),
  );

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Agendar desde el directorio de clínicas (con clínica y, si se eligió, veterinario ya elegidos).
  Future<void> _bookFromClinic(BuildContext pageContext, Clinic clinic, Veterinarian? vet) async {
    final created = await Navigator.of(pageContext).push<Appointment>(
      MaterialPageRoute<Appointment>(
        builder: (_) => BookAppointmentPage(
          deps: _deps,
          initialClinic: clinic,
          initialVeterinarianId: vet?.id,
        ),
      ),
    );
    if (created == null) return;
    if (pageContext.mounted) {
      // Vuelve al directorio y luego a la lista de citas.
      Navigator.of(pageContext).popUntil((route) => route.isFirst);
    }
    if (!mounted) return;
    _tabs.animateTo(0);
    _appointmentsKey.currentState?.reload();
    showAppMessage(context, 'Cita agendada para el ${created.date} a las ${created.startLabel} hrs');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Citas', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: kTextDark,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: kBrandBlue,
          unselectedLabelColor: kMuted,
          indicatorColor: kBrandBlue,
          tabs: const [Tab(text: 'Mis citas'), Tab(text: 'Clínicas')],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabs,
          children: [
            AppointmentsView(key: _appointmentsKey, deps: _deps),
            ClinicsView(
              getClinics: _deps.getClinics,
              getVeterinarians: _deps.getVeterinarians,
              onBook: _bookFromClinic,
            ),
          ],
        ),
      ),
    );
  }
}
