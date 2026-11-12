import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';
import 'pet_ui.dart';
import 'pet_history_page.dart';

class PetDetailPage extends StatefulWidget {
  final String petId;
  final Map<String, dynamic>? preview;
  const PetDetailPage({super.key, required this.petId, this.preview});
  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _future = injector<VetPaxRepository>().pet(widget.petId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: petCanvas,
      appBar: AppBar(title: const Text('Perfil clínico'), backgroundColor: petCanvas,
        foregroundColor: petInk),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: petTeal));
          }
          if (snapshot.hasError) return petFailure(snapshot.error!, _reload);
          final pet = snapshot.data!;
          final age = petAge(pet['birthDate']);
          return ListView(padding: const EdgeInsets.all(18), children: [
            petPanel(child: Column(children: [
              Row(children: [
                Container(width: 76, height: 76, decoration: BoxDecoration(
                  color: const Color(0xFFE8F9F5), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.pets, color: petTeal, size: 43)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(petText(pet['name']), style: const TextStyle(
                    color: petInk, fontSize: 23, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${speciesLabel(pet['species'])} · ${petText(pet['breed'], fallback: 'Raza no informada')}',
                    style: const TextStyle(color: petMuted)),
                ])),
              ]),
              const SizedBox(height: 19),
              Row(children: [
                _Fact(label: 'Edad', value: age ?? 'Sin dato'),
                const SizedBox(width: 8),
                _Fact(label: 'Sexo', value: sexLabel(pet['sex'])),
              ]),
              const SizedBox(height: 13),
              Align(alignment: Alignment.centerLeft,
                child: Text('Nacimiento: ${readableDate(pet['birthDate'])}',
                  style: const TextStyle(color: petMuted))),
            ])),
            const SizedBox(height: 16),
            petPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Expediente clínico', style: TextStyle(fontSize: 19,
                color: petInk, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Las atenciones, diagnósticos e indicadores se consultan en el historial clínico.',
                style: TextStyle(color: petMuted, height: 1.5)),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                style: petPrimaryStyle(), icon: const Icon(Icons.history),
                label: const Text('Ver historial clínico'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PetHistoryPage(petId: widget.petId,
                    petName: petText(pet['name'])))),
              )),
            ])),
            const SizedBox(height: 16),
            petNotice('La API actual no entrega foto, peso actual, diagnósticos resumidos ni próxima cita dentro del detalle de mascota. Estos datos no se muestran de manera ficticia.'),
          ]);
        },
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  const _Fact({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
    decoration: BoxDecoration(color: const Color(0xFFEEF3FF),
      borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: petMuted)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(color: petInk,
        fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
    ]),
  ));
}
