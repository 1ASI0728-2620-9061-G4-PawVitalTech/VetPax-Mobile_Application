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
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FF),
    appBar: AppBar(centerTitle: true, title: const Text('Cuidados',
      style: TextStyle(fontWeight: FontWeight.w700)), backgroundColor: const Color(0xFFF7F9FF),
      foregroundColor: const Color(0xFF14213D), surfaceTintColor: Colors.transparent,
      actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))]),
    body: SafeArea(child: FutureBuilder(future: _pets, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final pets = snapshot.data ?? [];
      if (pets.isEmpty) return const Center(child: Text('Registra una mascota para ver sus cuidados.'));
      final selected = pets.any((p) => _s(p['petId']) == _selected) ? _selected! : _s(pets.first['petId']);
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16,8,16,12), child: Container(
          padding: const EdgeInsets.symmetric(horizontal:14,vertical:4),
          decoration: BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),
          child: DropdownButtonHideUnderline(child: DropdownButton<String>(value:selected,isExpanded:true,
            icon: const Icon(Icons.keyboard_arrow_down),
            items:pets.map((p)=>DropdownMenuItem(value:_s(p['petId']),child:Row(children:[
              const CircleAvatar(radius:20,backgroundColor:Color(0xFFE8F7F6),
                child:Icon(Icons.pets,color:Color(0xFF139D91))),
              const SizedBox(width:10),
              Expanded(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(_s(p['name']),style:const TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF14213D))),
                Text(_s(p['breed']).isEmpty?_s(p['species']):_s(p['breed']),overflow:TextOverflow.ellipsis,
                  style:const TextStyle(fontSize:12,color:Color(0xFF667085))),
              ])),
            ]))).toList(),onChanged:(v)=>setState(()=>_selected=v))),
        )),
        Expanded(child:_PetTreatments(key:ValueKey(selected),petId:selected)),
      ]);
    })),
  );
}

class _PetTreatments extends StatefulWidget {
  final String petId;
  const _PetTreatments({super.key, required this.petId});
  @override State<_PetTreatments> createState() => _PetTreatmentsState();
}
class _PetTreatmentsState extends State<_PetTreatments> {
  late Future<(List<Map<String,dynamic>>, Map<String,dynamic>?)> _future;
  int _section = 0;
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

  Widget _selector() => Container(padding:const EdgeInsets.all(4),
    decoration:BoxDecoration(color:const Color(0xFFE8F0FD),borderRadius:BorderRadius.circular(24)),
    child:Row(children:[
      Expanded(child:_sectionButton(0,Icons.medication_outlined,'Medicación activa')),
      Expanded(child:_sectionButton(1,Icons.restaurant_outlined,'Plan alimentario')),
    ]));

  Widget _sectionButton(int value,IconData icon,String label) {
    final selected=_section==value;
    return InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>setState(()=>_section=value),
      child:AnimatedContainer(duration:const Duration(milliseconds:180),
        padding:const EdgeInsets.symmetric(vertical:11,horizontal:8),
        decoration:BoxDecoration(color:selected?const Color(0xFF1DB9A9):Colors.transparent,
          borderRadius:BorderRadius.circular(20)),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(icon,size:18,color:selected?Colors.white:const Color(0xFF52606D)),
          const SizedBox(width:6),
          Flexible(child:Text(label,overflow:TextOverflow.ellipsis,style:TextStyle(fontWeight:FontWeight.w600,
            color:selected?Colors.white:const Color(0xFF52606D)))),
        ])));
  }

  Widget _reminders(bool enabled,String message,ValueChanged<bool> onChanged) => Container(
    padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFFEAF2FF),
      borderRadius:BorderRadius.circular(22)),child:Row(children:[
        const CircleAvatar(backgroundColor:Color(0xFFD4F3F0),
          child:Icon(Icons.alarm_on_outlined,color:Color(0xFF139D91))),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Recordatorios automáticos',style:TextStyle(fontWeight:FontWeight.w700,color:Color(0xFF24324A))),
          const SizedBox(height:4),Text(message,style:const TextStyle(fontSize:13,color:Color(0xFF667085))),
        ])),
        Switch(value:enabled,activeTrackColor:const Color(0xFF1DB9A9),onChanged:onChanged),
      ]));

  Widget _medications(List<Map<String,dynamic>> plans) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _reminders(plans.isNotEmpty&&plans.every((p)=>p['remindersEnabled']==true),
      'Te avisaremos cuando sea momento de administrar cada dosis.',(value) async {
        try { await Future.wait(plans.map((p)=>_repo.setMedicationReminders(_s(p['planId']),value))); _reload(); }
        catch(e) { if(mounted) _message(context,'Error: $e'); }
      }),
    const SizedBox(height:24),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      const Text('Medicación activa',style:TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:Color(0xFF14213D))),
      Text('${plans.length} ${plans.length==1?'tratamiento':'tratamientos'}',style:const TextStyle(fontSize:12,color:Color(0xFF667085))),
    ]),
    const SizedBox(height:12),
    if(plans.isEmpty) _empty(Icons.medication_outlined,'Sin planes de medicación activos'),
    for(final plan in plans) Container(margin:const EdgeInsets.only(bottom:14),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),
        border:const Border(left:BorderSide(color:Color(0xFFF4A000),width:5))),
      padding:const EdgeInsets.all(18),child:Column(children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const CircleAvatar(backgroundColor:Color(0xFFFFF5DC),
            child:Icon(Icons.medication_outlined,color:Color(0xFFE39400))),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(_s(plan['medicationName']).isEmpty?'Medicamento':_s(plan['medicationName']),
              style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700,color:Color(0xFF14213D))),
            const SizedBox(height:4),Text('${_s(plan['startDate'])} — ${_s(plan['endDate'])}',
              style:const TextStyle(fontSize:13,color:Color(0xFF667085))),
          ])),_chip(_s(plan['status'])),
        ]),
        const SizedBox(height:16),
        SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_doses(plan),
          style:FilledButton.styleFrom(backgroundColor:const Color(0xFF1DB9A9),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
          icon:const Icon(Icons.schedule),label:const Text('Ver dosis programadas'))),
      ])),
  ]);

  Widget _feeding(Map<String,dynamic>? food) => Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    _reminders(food?['remindersEnabled']==true,'Te avisaremos cuando sea momento de servir cada porción.',(value) async {
      if(food==null)return;
      try { await _repo.setFeedingReminders(_s(food['planId']),value); _reload(); }
      catch(e) { if(mounted) _message(context,'Error: $e'); }
    }),
    const SizedBox(height:24),
    const Text('Plan alimentario',style:TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:Color(0xFF14213D))),
    const SizedBox(height:12),
    if(food==null) _empty(Icons.restaurant_outlined,'Sin plan alimentario activo'),
    if(food!=null) Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22),
      border:const Border(left:BorderSide(color:Color(0xFFF4A000),width:5))),padding:const EdgeInsets.all(18),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const CircleAvatar(backgroundColor:Color(0xFFFFF1E5),
          child:Icon(Icons.restaurant,color:Color(0xFFB76A00))),const SizedBox(width:12),
          Expanded(child:Text(_s(food['foodName']).isEmpty?'Alimento indicado':_s(food['foodName']),
            style:const TextStyle(fontSize:18,fontWeight:FontWeight.w700,color:Color(0xFF14213D)))),_chip('Activo')]),
        if(_s(food['recommendations']).isNotEmpty) ...[const SizedBox(height:18),Container(width:double.infinity,
          padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFF3F6FC),
            borderRadius:BorderRadius.circular(14)),child:Text(_s(food['recommendations']),
              style:const TextStyle(height:1.4,color:Color(0xFF52606D))))],
      ])),
  ]);

  Widget _chip(String status) { final active=status.toLowerCase()=='active'||status.toLowerCase()=='activo';
    return Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:6),
      decoration:BoxDecoration(color:active?const Color(0xFFDDF7F1):const Color(0xFFFFF2D6),
        borderRadius:BorderRadius.circular(18)),child:Text(status.isEmpty?'Activo':status,
          style:TextStyle(fontSize:12,fontWeight:FontWeight.w600,
            color:active?const Color(0xFF12806F):const Color(0xFF9A6200)))); }

  Widget _empty(IconData icon,String message) => Container(width:double.infinity,padding:const EdgeInsets.all(24),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(22)),child:Column(children:[
      Icon(icon,size:34,color:const Color(0xFF98A2B3)),const SizedBox(height:10),
      Text(message,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFF667085))),
    ]));
  @override Widget build(BuildContext context) => FutureBuilder(
    future: _future, builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return _error(snapshot.error,_reload);
      final data = snapshot.data!;
      final med = data.$1, food = data.$2;
      return RefreshIndicator(onRefresh:() async=>_reload(),child:ListView(
        physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,4,16,24),children:[
          _selector(),const SizedBox(height:20),if(_section==0)_medications(med)else _feeding(food),
        ]));
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
