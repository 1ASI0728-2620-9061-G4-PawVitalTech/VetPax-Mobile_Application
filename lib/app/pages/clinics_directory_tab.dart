import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinic_veterinarians.dart';
import 'package:vetpax_frontend/features/clinics/domain/usecases/get_clinics.dart';
import 'package:vetpax_frontend/features/clinics/presentation/pages/clinics_view.dart';

/// Pestaña con solo el directorio de clínicas.
/// Se usa mientras la feature de Citas no esté integrada; luego tenemos que 
//  reemplazarlo con CitasTab.
class ClinicsDirectoryTab extends StatelessWidget {
  const ClinicsDirectoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Clínicas', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: kTextDark,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ClinicsView(
          getClinics: injector<GetClinics>(),
          getVeterinarians: injector<GetClinicVeterinarians>(),
          onBook: (context, clinic, veterinarian) =>
              showAppMessage(context, 'Agendar citas estará disponible muy pronto.'),
        ),
      ),
    );
  }
}
