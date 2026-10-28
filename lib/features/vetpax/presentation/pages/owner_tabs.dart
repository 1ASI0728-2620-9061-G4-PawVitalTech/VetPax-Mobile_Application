import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';

final VetPaxRepository _repo = injector<VetPaxRepository>();
const _blue = Color(0xFF2563EB);
const _gray = Color(0xFF6B7280);

String _s(dynamic value) => value?.toString() ?? '';
String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Widget _page(String title, Widget child, {VoidCallback? onRefresh}) => Scaffold(
  backgroundColor: Colors.white,
  appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    foregroundColor: const Color(0xFF1F2937), backgroundColor: Colors.white,
    actions: onRefresh == null ? null : [IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh)]),
  body: SafeArea(child: child),
);
Widget _tile(String title, String subtitle, {VoidCallback? onTap, Widget? trailing}) => Card(
  color: Colors.white, surfaceTintColor: Colors.white,
  child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle), onTap: onTap, trailing: trailing),
);
Widget _error(Object? err, VoidCallback reload) => Center(child: Padding(
  padding: const EdgeInsets.all(20),
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, color: Colors.red, size: 32),
    const SizedBox(height: 10), Text('$err', textAlign: TextAlign.center),
    TextButton(onPressed: reload, child: const Text('Reintentar')),
  ]),
));
void _message(BuildContext context, String text) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(text)));

class PetsTab extends StatefulWidget {
  const PetsTab({super.key});
  @override State<PetsTab> createState() => _PetsTabState();
}
class _PetsTabState extends State<PetsTab> {
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _reload(); }
  void _reload() => setState(() => _future = _repo.myPets());
  Future<void> _createPet() async {
    final name = TextEditingController();
    final breed = TextEditingController();
    var species = 'Dog';
    var sex = 'Male';
    var birth = DateTime(2022, 1, 1);
    if (!mounted) return;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, redraw) => AlertDialog(title: const Text('Registrar mascota'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        TextField(controller: breed, decoration: const InputDecoration(labelText: 'Raza (opcional)')),
        DropdownButtonFormField<String>(initialValue: species, decoration: const InputDecoration(labelText: 'Especie'),
          items: ['Dog','Cat'].map((v) => DropdownMenuItem(value: v,child: Text(v))).toList(),
          onChanged: (v) => redraw(() => species = v ?? species)),
        DropdownButtonFormField<String>(initialValue: sex, decoration: const InputDecoration(labelText: 'Sexo'),
          items: ['Male','Female'].map((v) => DropdownMenuItem(value: v,child: Text(v))).toList(),
          onChanged: (v) => redraw(() => sex = v ?? sex)),
        TextButton(onPressed: () async {
          final d = await showDatePicker(context: ctx, firstDate: DateTime(1990), lastDate: DateTime.now(), initialDate: birth);
          if (d != null) redraw(() => birth = d);
        }, child: Text('Nacimiento: ${_date(birth)}')),
      ])), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false),child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar'))]),
    ));
    if (ok != true) return;
    try {
      await _repo.createPet({'name': name.text.trim(), 'species': species,
        'breed': breed.text.trim().isEmpty ? null : breed.text.trim(),
        'birthDate': _date(birth), 'sex': sex});
      if (mounted) { _message(context,'Mascota registrada'); _reload(); }
    } catch (e) { if (mounted) _message(context,'Error: $e'); }
    name.dispose(); breed.dispose();
  }
  Future<void> _viewHistory(Map<String,dynamic> pet) async {
    final id = _s(pet['petId']);
    try {
      final history = await _repo.clinicalHistory(id);
      if (!mounted) return;
      final events = history['attentions'] is List ? history['attentions'] as List : <dynamic>[];
      await showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text('Historial: ${_s(pet['name'])}'),
        content: SizedBox(width: double.maxFinite, child: events.isEmpty
          ? const Text('Todavía no hay atenciones clínicas')
          : ListView(shrinkWrap: true, children: events.map((e) {
              final row = Map<String,dynamic>.from(e as Map);
              return ListTile(title: Text(_s(row['reason'])),
                subtitle: Text('${_s(row['attentionDate'])}\n${_s(row['diagnosis'])}'));
            }).toList())),
        actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text('Cerrar'))]));
    } catch (e) { if (mounted) _message(context,'Error consultando historial: $e'); }
  }
  @override Widget build(BuildContext context) => _page('Mis mascotas', FutureBuilder(
    future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error, _reload);
      final pets = snapshot.data ?? [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        FilledButton.icon(onPressed: _createPet, icon: const Icon(Icons.add), label: const Text('Registrar mascota')),
        const SizedBox(height: 12),
        if (pets.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('Registra tu primera mascota.')),
        for (final pet in pets) _tile(_s(pet['name']), '${_s(pet['species'])} · ${_s(pet['breed'])}',
          trailing: const Icon(Icons.chevron_right), onTap: () => _viewHistory(pet)),
      ]);
    }), onRefresh: _reload);
}

class ClinicsTab extends StatefulWidget {
  const ClinicsTab({super.key});
  @override State<ClinicsTab> createState() => _ClinicsTabState();
}
class _ClinicsTabState extends State<ClinicsTab> {
  late Future<List<Map<String,dynamic>>> _future;
  @override void initState() {super.initState(); _reload();}
  void _reload() => setState(() => _future = _repo.clinics());
  Future<void> _clinic(Map<String,dynamic> clinic) async {
    final clinicId = _s(clinic['clinicId']);
    try {
      final vets = await _repo.veterinarians(clinicId);
      if (!mounted) return;
      await showModalBottomSheet(context: context, isScrollControlled: true,
        builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Veterinarios · ${_s(clinic['name'])}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            if (vets.isEmpty) const Text('No hay veterinarios activos'),
            for (final vet in vets) _tile('Veterinario', _s(vet['veterinarianId']),
              trailing: const Icon(Icons.calendar_month), onTap: () {
                Navigator.pop(ctx);
                _chooseDate(clinicId, _s(vet['veterinarianId']));
              }),
          ]))));
    } catch (e) { if (mounted) _message(context,'Error: $e'); }
  }
  Future<void> _chooseDate(String clinicId, String vetId) async {
    final now = DateTime.now();
    final day = await showDatePicker(context: context, initialDate: now,
        firstDate: now, lastDate: now.add(const Duration(days: 90)));
    if (day == null || !mounted) return;
    try {
      final availability = await _repo.availability(clinicId: clinicId,
        veterinarianId: vetId, date: _date(day));
      final slots = availability['slots'] is List ? availability['slots'] as List : <dynamic>[];
      if (!mounted) return;
      await showModalBottomSheet(context: context, isScrollControlled: true,
        builder: (ctx) => SafeArea(child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.60,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(14), child: Text('Horarios · ${_date(day)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            Expanded(child: slots.isEmpty ? const Center(child: Text('Sin horarios libres')) :
              ListView(children: slots.map((s) {
                final slot = Map<String,dynamic>.from(s as Map);
                return _tile(_s(slot['startTime']), 'Hasta ${_s(slot['endTime'])}',
                  trailing: const Icon(Icons.chevron_right), onTap: () {
                    Navigator.pop(ctx);
                    _book(clinicId, vetId, _date(day), _s(slot['startTime']));
                  });
              }).toList())),
          ]))));
    } catch (e) { if (mounted) _message(context,'Error de disponibilidad: $e'); }
  }
  Future<void> _book(String clinicId, String vetId, String date, String time) async {
    try {
      final pets = await _repo.myPets();
      if (!mounted) return;
      if (pets.isEmpty) { _message(context,'Primero debes registrar una mascota.'); return; }
      var petId = _s(pets.first['petId']);
      final reason = TextEditingController();
      final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
        builder: (ctx, redraw) => AlertDialog(title: const Text('Confirmar cita'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$date · $time'),
            DropdownButtonFormField<String>(initialValue: petId,
              decoration: const InputDecoration(labelText:'Mascota'),
              items: pets.map((p) => DropdownMenuItem(value: _s(p['petId']), child: Text(_s(p['name'])))).toList(),
              onChanged: (v) => redraw(() => petId = v ?? petId)),
            TextField(controller: reason, decoration: const InputDecoration(labelText:'Motivo')),
          ]), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Volver')),
            FilledButton(onPressed: () => Navigator.pop(ctx,true), child: const Text('Agendar'))]),
      ));
      if (ok == true) {
        final appointment = await _repo.bookAppointment(petId: petId, clinicId: clinicId,
          veterinarianId: vetId, date: date, startTime: time,
          reason: reason.text.trim().isEmpty ? 'Consulta veterinaria' : reason.text.trim());
        if (mounted) _message(context, 'Cita creada: ${_s(appointment['appointmentId'])}');
      }
      reason.dispose();
    } catch (e) { if (mounted) _message(context,'No se pudo agendar: $e'); }
  }
  @override Widget build(BuildContext context) => _page('Clínicas', FutureBuilder(
    future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final clinics = snapshot.data ?? [];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Selecciona una clínica para ver horarios disponibles', style: TextStyle(color: _gray)),
        const SizedBox(height: 10),
        for (final c in clinics) _tile(_s(c['name']), _s(c['address']),
          trailing: const Icon(Icons.chevron_right), onTap: () => _clinic(c)),
        if (clinics.isEmpty) const Text('No hay clínicas registradas'),
      ]);
    }), onRefresh: _reload);
}

class TreatmentsTab extends StatefulWidget {
  const TreatmentsTab({super.key});
  @override State<TreatmentsTab> createState() => _TreatmentsTabState();
}
class _TreatmentsTabState extends State<TreatmentsTab> {
  late Future<List<Map<String,dynamic>>> _pets;
  String? _selected;
  @override void initState(){super.initState(); _reload();}
  void _reload() => setState(() => _pets = _repo.myPets());
  @override Widget build(BuildContext context) => _page('Cuidados', FutureBuilder(
    future: _pets, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final pets = snapshot.data ?? [];
      if (pets.isEmpty) return const Center(child: Text('Registra una mascota para ver sus cuidados.'));
      final selected = pets.any((p) => p['petId'] == _selected) ? _selected! : _s(pets.first['petId']);
      return Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<String>(
          initialValue: selected, decoration: const InputDecoration(labelText:'Mascota', border: OutlineInputBorder()),
          items: pets.map((p) => DropdownMenuItem(value:_s(p['petId']),child: Text(_s(p['name'])))).toList(),
          onChanged: (v) => setState(() => _selected = v))),
        Expanded(child: _PetTreatments(key: ValueKey(selected), petId: selected)),
      ]);
    }), onRefresh: _reload);
}

class _PetTreatments extends StatefulWidget {
  final String petId;
  const _PetTreatments({super.key, required this.petId});
  @override State<_PetTreatments> createState() => _PetTreatmentsState();
}
class _PetTreatmentsState extends State<_PetTreatments> {
  late Future<(List<Map<String,dynamic>>, Map<String,dynamic>?)> _future;
  @override void initState(){super.initState();_reload();}
  void _reload() => setState(() => _future = _load());
  Future<(List<Map<String,dynamic>>, Map<String,dynamic>?)> _load() async {
    final med = await _repo.medicationPlans(widget.petId);
    final food = await _repo.activeFeedingPlan(widget.petId);
    return (med, food);
  }
  Future<void> _doses(Map<String,dynamic> med) async {
    try {
      final doses = await _repo.medicationDoses(_s(med['planId']));
      if (!mounted) return;
      await showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) =>
        SafeArea(child: SizedBox(height: MediaQuery.of(ctx).size.height * 0.7,
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: Text('Dosis · ${_s(med['medicationName'])}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
            Expanded(child: doses.isEmpty ? const Center(child: Text('Todavía no se han generado dosis')) :
              ListView(children: doses.map((dose) => _tile(
                '${_s(dose['localDate'])} · ${_s(dose['localTime'])}',
                'Estado: ${_s(dose['status'])}',
                trailing: dose['status'] == 'Pending'
                    ? IconButton(icon: const Icon(Icons.check_circle_outline, color: _blue), onPressed: () async {
                        final confirmed = await showDialog<bool>(context: ctx, builder: (dialog) => AlertDialog(
                          title: const Text('Confirmar administración'),
                          content: const Text('Marca como administrada solo si realmente suministraste la dosis.'),
                          actions: [TextButton(onPressed:()=>Navigator.pop(dialog,false),child: const Text('Cancelar')),
                          FilledButton(onPressed:()=>Navigator.pop(dialog,true),child: const Text('Confirmar'))]));
                        if (confirmed != true) return;
                        try {
                          await _repo.administer(_s(dose['doseId']));
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {_message(context,'Administración registrada');_doses(med);}
                        } catch(e) { if (mounted) _message(context,'Error: $e'); }
                      }) : null,
              )).toList())),
          ]))));
    } catch (e) { if(mounted) _message(context,'Error consultando dosis: $e'); }
  }
  @override Widget build(BuildContext context) => FutureBuilder(
    future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final data = snapshot.data!;
      final med = data.$1, food = data.$2;
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Medicación', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
        if (med.isEmpty) const Padding(padding: EdgeInsets.all(12),child: Text('Sin planes de medicación')),
        for (final m in med) _tile(_s(m['medicationName']),
          '${_s(m['status'])} · ${_s(m['startDate'])} a ${_s(m['endDate'])}',
          trailing: const Icon(Icons.chevron_right), onTap: () => _doses(m)),
        const SizedBox(height: 24),
        const Text('Alimentación', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold)),
        if (food == null) const Padding(padding: EdgeInsets.all(12),child: Text('Sin plan de alimentación activo')),
        if (food != null) _tile(_s(food['foodName']),
          '${_s(food['recommendations'])}\nRecordatorios: ${food['remindersEnabled'] == true ? 'activados' : 'desactivados'}',
          trailing: Switch(value: food['remindersEnabled'] == true, onChanged: (v) async {
            try { await _repo.setFeedingReminders(_s(food['planId']), v); _reload(); }
            catch(e) { if (mounted) _message(context,'Error: $e'); }
          })),
      ]);
    });
}

class AdherenceTab extends StatefulWidget {
  const AdherenceTab({super.key});
  @override State<AdherenceTab> createState() => _AdherenceTabState();
}
class _AdherenceTabState extends State<AdherenceTab> {
  late Future<Map<String,dynamic>> _future;
  @override void initState(){super.initState();_reload();}
  void _reload() => setState(() => _future = _repo.adherence());
  @override Widget build(BuildContext context) => _page('Mi constancia', FutureBuilder(
    future: _future, builder: (context,snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final adherence = snapshot.data!;
      final ready = adherence['hasSufficientEvidence'] == true;
      final awards = adherence['recognitions'] is List ? adherence['recognitions'] as List : <dynamic>[];
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Icon(Icons.emoji_events_outlined, size: 70, color: _blue),
        const SizedBox(height: 16),
        Center(child: Text('Nivel: ${ready ? _s(adherence['level']) : 'Aún sin evaluar'}',
          style: const TextStyle(fontSize: 22,fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Center(child: Text('Evidencias: ${_s(adherence['evidenceCount'])} · Puntuación: ${_s(adherence['score'])}',
          style: const TextStyle(color:_gray))),
        if (!ready) const Padding(padding: EdgeInsets.all(20), child:
          Text('Necesitas más actividades registradas para recibir una evaluación.', textAlign: TextAlign.center)),
        for (final award in awards) _tile('Reconocimiento', _s(award)),
      ]);
    }), onRefresh: _reload);
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override State<ProfileTab> createState() => _ProfileTabState();
}
class _ProfileTabState extends State<ProfileTab> {
  late Future<Map<String,dynamic>> _future;
  @override void initState(){super.initState();_reload();}
  void _reload() => setState(() => _future = _repo.me());
  @override Widget build(BuildContext context) => _page('Mi perfil', FutureBuilder(
    future: _future, builder: (context,snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final user = snapshot.data!;
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: CircleAvatar(radius: 38, backgroundColor: Color(0xFFEFF6FF),
          child: Icon(Icons.person, color: _blue, size: 42))),
        const SizedBox(height: 12),
        Center(child: Text(_s(user['email']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        const SizedBox(height: 8),
        Center(child: Text('Rol: ${_s(user['role'])}', style: const TextStyle(color: _gray))),
        const SizedBox(height: 24),
        _tile('ID de propietario', _s(user['userId'])),
        const SizedBox(height: 20),
        FilledButton.icon(icon: const Icon(Icons.logout), label: const Text('Cerrar sesión'),
          style: FilledButton.styleFrom(backgroundColor: _blue), onPressed: () async {
            await injector<AuthRepository>().logout();
            if (context.mounted) Navigator.pushNamedAndRemoveUntil(context,'/login',(route)=>false);
          }),
      ]);
    }), onRefresh: _reload);
}
