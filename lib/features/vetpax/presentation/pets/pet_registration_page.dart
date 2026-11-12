import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';
import 'pet_ui.dart';

class PetRegistrationPage extends StatefulWidget {
  const PetRegistrationPage({super.key});
  @override
  State<PetRegistrationPage> createState() => _PetRegistrationPageState();
}

class _PetRegistrationPageState extends State<PetRegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  String _species = 'Dog';
  String _sex = 'Male';
  DateTime? _birth;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(context: context,
      firstDate: DateTime(1980), lastDate: now,
      initialDate: _birth ?? DateTime(now.year - 1, now.month, now.day));
    if (selected != null && mounted) setState(() => _birth = selected);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_birth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha de nacimiento.')));
      return;
    }
    setState(() => _saving = true);
    final date = _birth!;
    final birthDate = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      await injector<VetPaxRepository>().createPet({
        'name': _name.text.trim(),
        'species': _species,
        'birthDate': birthDate,
        'breed': _breed.text.trim().isEmpty ? null : _breed.text.trim(),
        'sex': _sex,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No fue posible registrar la mascota: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: petCanvas,
      appBar: AppBar(backgroundColor: petCanvas, title: const Text('Nueva mascota'),
        foregroundColor: petInk),
      body: SafeArea(child: Form(key: _form, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text('Registra a tu compañero', style: TextStyle(
            color: petInk, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text('Ingresa sus datos básicos para crear el perfil clínico.',
            style: TextStyle(color: petMuted)),
          const SizedBox(height: 22),
          Center(child: CircleAvatar(radius: 47, backgroundColor: const Color(0xFFE5F9F5),
            child: const Icon(Icons.pets, color: petTeal, size: 48))),
          const SizedBox(height: 10),
          const Center(child: Text('La carga de fotos no está disponible en esta API.',
            style: TextStyle(color: petMuted, fontSize: 12))),
          const SizedBox(height: 23),
          petPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _name, maxLength: 80, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre de la mascota *',
                prefixIcon: Icon(Icons.pets_outlined)),
              validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Ingresa un nombre.' : null),
            const SizedBox(height: 9),
            const Text('Especie *', style: TextStyle(fontWeight: FontWeight.w700, color: petInk)),
            const SizedBox(height: 5),
            SegmentedButton<String>(segments: const [
              ButtonSegment(value: 'Dog', label: Text('Perro')),
              ButtonSegment(value: 'Cat', label: Text('Gato')),
            ], selected: {_species},
              onSelectionChanged: (value) => setState(() => _species = value.first)),
            const SizedBox(height: 15),
            TextFormField(controller: _breed, maxLength: 80,
              decoration: const InputDecoration(labelText: 'Raza (opcional)',
                hintText: 'Golden Retriever, mestizo...')),
            const SizedBox(height: 8),
            const Text('Sexo', style: TextStyle(fontWeight: FontWeight.w700, color: petInk)),
            const SizedBox(height: 5),
            SegmentedButton<String>(segments: const [
              ButtonSegment(value: 'Male', label: Text('Macho')),
              ButtonSegment(value: 'Female', label: Text('Hembra')),
            ], selected: {_sex},
              onSelectionChanged: (value) => setState(() => _sex = value.first)),
            const SizedBox(height: 20),
            OutlinedButton.icon(onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_birth == null ? 'Fecha de nacimiento *'
                : 'Nacimiento: ${readableDate(_birth!.toIso8601String())}')),
            const SizedBox(height: 8),
            const Text('La edad se calcula a partir de la fecha de nacimiento.',
              style: TextStyle(color: petMuted, fontSize: 12)),
          ])),
          const SizedBox(height: 14),
          petNotice('Este registro guarda nombre, especie, raza, sexo y nacimiento. El peso y las condiciones médicas se registran mediante atenciones veterinarias.'),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _saving ? null : _save, style: petPrimaryStyle(),
            icon: _saving ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.check_circle_outline),
            label: Text(_saving ? 'Guardando...' : 'Registrar mascota'),
          )),
          TextButton(onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ],
      ))),
    );
  }
}
