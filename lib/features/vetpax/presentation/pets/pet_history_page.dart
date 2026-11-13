import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';
import 'pet_ui.dart';

class PetHistoryPage extends StatefulWidget {
  final String petId;
  final String petName;
  const PetHistoryPage({super.key, required this.petId, required this.petName});
  @override
  State<PetHistoryPage> createState() => _PetHistoryPageState();
}

class _PetHistoryPageState extends State<PetHistoryPage> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() { super.initState(); _reload(); }
  void _reload() => setState(() { _future = injector<VetPaxRepository>().clinicalHistory(widget.petId); });

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: petCanvas,
      appBar: AppBar(title: const Text('Historial clínico'), backgroundColor: petCanvas,
        foregroundColor: petInk),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: petTeal));
          }
          if (snapshot.hasError) return petFailure(snapshot.error!, _reload);
          final history = snapshot.data!;
          final raw = history['attentions'];
          final attentions = raw is List
              ? raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
              : <Map<String, dynamic>>[];
          attentions.sort((a, b) => (b['attentionDate']?.toString() ?? '')
            .compareTo(a['attentionDate']?.toString() ?? ''));
          return ListView(padding: const EdgeInsets.all(18), children: [
            Text(widget.petName, style: const TextStyle(color: petInk,
              fontSize: 23, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('${attentions.length} ${attentions.length == 1 ? 'atención registrada' : 'atenciones registradas'}',
              style: const TextStyle(color: petMuted)),
            const SizedBox(height: 18),
            if (attentions.isEmpty) petPanel(child: Column(children: [
              const Icon(Icons.medical_information_outlined, color: petTeal, size: 45),
              const SizedBox(height: 12),
              Text(petText(history['message'], fallback: 'Aún no hay atenciones clínicas registradas.'),
                style: const TextStyle(color: petMuted), textAlign: TextAlign.center),
            ])),
            for (final attention in attentions) ...[
              _AttentionCard(attention: attention),
              const SizedBox(height: 13),
            ],
          ]);
        },
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  final Map<String, dynamic> attention;
  const _AttentionCard({required this.attention});

  @override
  Widget build(BuildContext context) {
    final indicators = attention['indicators'];
    return petPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.medical_services_outlined, color: petTeal),
        const SizedBox(width: 9),
        Expanded(child: Text(readableDate(attention['attentionDate']),
          style: const TextStyle(color: petTeal, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 13),
      Text(petText(attention['reason']), style: const TextStyle(
        color: petInk, fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 13),
      _recordField('Diagnóstico', attention['diagnosis']),
      _recordField('Resumen del tratamiento', attention['treatmentSummary']),
      if (petText(attention['observations'], fallback: '').isNotEmpty)
        _recordField('Observaciones', attention['observations']),
      if (indicators is List && indicators.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Indicadores', style: TextStyle(color: petInk,
          fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        for (final item in indicators)
          if (item is Map)
            Text('${petText(item['name'])}: ${petText(item['value'])} ${petText(item['unit'], fallback: '')}',
              style: const TextStyle(color: petMuted)),
      ],
    ]));
  }

  Widget _recordField(String label, dynamic value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: petMuted,
        fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(petText(value), style: const TextStyle(color: petInk, height: 1.4)),
    ]),
  );
}
