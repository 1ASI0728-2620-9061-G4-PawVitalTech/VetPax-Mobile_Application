import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';
import 'pet_ui.dart';
import 'pet_registration_page.dart';
import 'pet_detail_page.dart';

class PetsTab extends StatefulWidget {
  const PetsTab({super.key});
  @override
  State<PetsTab> createState() => _PetsTabState();
}

class _PetsTabState extends State<PetsTab> {
  final VetPaxRepository _repo = injector<VetPaxRepository>();
  late Future<List<Map<String, dynamic>>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => setState(() => _petsFuture = _repo.myPets());

  Future<void> _refresh() async {
    final future = _repo.myPets();
    setState(() => _petsFuture = future);
    try { await future; } catch (_) { /* FutureBuilder muestra el error. */ }
  }

  Future<void> _newPet() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PetRegistrationPage()),
    );
    if (created == true && mounted) _reload();
  }

  Future<void> _openPet(Map<String, dynamic> pet) async {
    final id = petText(pet['petId'], fallback: '');
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La mascota no tiene un identificador válido.')),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PetDetailPage(petId: id, preview: pet),
    ));
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: petCanvas,
      appBar: AppBar(title: const Text('Mascotas', style: TextStyle(color: petInk, fontWeight: FontWeight.w700)),
        centerTitle: true, backgroundColor: petCanvas, elevation: 0),
      body: SafeArea(child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: petTeal));
          }
          if (snapshot.hasError) return petFailure(snapshot.error!, _reload);
          final pets = snapshot.data ?? [];
          return RefreshIndicator(color: petTeal, onRefresh: _refresh,
            child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 30), children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Mis mascotas', style: TextStyle(color: petInk,
                    fontSize: 25, fontWeight: FontWeight.bold)),
                  Text('${pets.length} ${pets.length == 1 ? 'registrada' : 'registradas'}',
                    style: const TextStyle(color: petMuted)),
                ])),
                FilledButton.icon(onPressed: _newPet, style: petPrimaryStyle(),
                  icon: const Icon(Icons.add), label: const Text('Nueva')),
              ]),
              const SizedBox(height: 20),
              petNotice('Consulta las mascotas registradas en tu cuenta. Los cuidados y citas se muestran en sus módulos correspondientes.',
                icon: Icons.health_and_safety_outlined),
              const SizedBox(height: 20),
              if (pets.isEmpty) petPanel(child: Column(children: [
                const Icon(Icons.pets_outlined, color: petTeal, size: 56),
                const SizedBox(height: 12),
                const Text('Todavía no tienes mascotas registradas',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17,
                    color: petInk, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                const Text('Registra tu primera mascota para consultar su perfil clínico.',
                  textAlign: TextAlign.center, style: TextStyle(color: petMuted)),
                const SizedBox(height: 16),
                FilledButton(onPressed: _newPet, style: petPrimaryStyle(),
                  child: const Text('Registrar mascota')),
              ])),
              for (final pet in pets) ...[
                _PetCard(pet: pet, onTap: () => _openPet(pet)),
                const SizedBox(height: 14),
              ],
            ]),
          );
        },
      )),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final VoidCallback onTap;
  const _PetCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final age = petAge(pet['birthDate']);
    final breed = petText(pet['breed'], fallback: 'Raza no informada');
    return petPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 68, height: 68, decoration: BoxDecoration(
          color: const Color(0xFFE5F9F5), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.pets, color: petTeal, size: 35)),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(petText(pet['name']), style: const TextStyle(color: petInk,
            fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${speciesLabel(pet['species'])} · $breed',
            style: const TextStyle(color: petMuted)),
          if (age != null) ...[
            const SizedBox(height: 5),
            Text(age, style: const TextStyle(color: petTeal, fontWeight: FontWeight.w600)),
          ],
        ])),
      ]),
      const SizedBox(height: 17),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEAF0FF),
          foregroundColor: const Color(0xFF1857B8)),
        onPressed: onTap, icon: const Icon(Icons.arrow_forward),
        label: const Text('Ver perfil clínico'),
      )),
    ]));
  }
}
