import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/di/injector.dart';
import 'package:vetpax_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';
import 'profile_identity.dart';

const _ink = Color(0xFF183047);
const _muted = Color(0xFF64748B);
const _teal = Color(0xFF12B5A5);
const _canvas = Color(0xFFF5F7FC);

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final VetPaxRepository _repository = injector<VetPaxRepository>();
  late Future<({Map<String, dynamic> user, int? petCount})> _profile;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<({Map<String, dynamic> user, int? petCount})> _load() async {
    final user = await _repository.me();
    // El conteo es informativo: un fallo en /pets no debe ocultar el perfil.
    int? petCount;
    try {
      petCount = (await _repository.myPets()).length;
    } catch (_) {
      petCount = null;
    }
    return (user: user, petCount: petCount);
  }

  void _refresh() {
    setState(() {
      _profile = _load();
    });
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta de VetPax?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _signingOut) return;
    setState(() { _signingOut = true; });
    try {
      await injector<AuthRepository>().logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() { _signingOut = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cerrar sesión. Inténtalo nuevamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas,
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      centerTitle: true,
      actions: [
        IconButton(onPressed: _refresh, tooltip: 'Actualizar perfil',
          icon: const Icon(Icons.refresh, color: _ink)),
      ],
    ),
    body: SafeArea(child: FutureBuilder<({Map<String, dynamic> user, int? petCount})>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: _teal));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: _muted),
              const SizedBox(height: 12),
              const Text('No se pudo cargar tu perfil', style: TextStyle(fontWeight: FontWeight.bold, color: _ink)),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh),
                label: const Text('Reintentar')),
            ])));
        }
        final data = snapshot.data!;
        final user = data.user;
        final email = profileValue(user['email']);
        final name = profileDisplayName(user);
        final role = profileRoleLabel(user['role']);
        return RefreshIndicator(
          onRefresh: () async {
            final next = _load();
            setState(() { _profile = next; });
            try { await next; } catch (_) { /* FutureBuilder muestra el error. */ }
          },
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 22, 16, 30), children: [
            _panel(child: Column(children: [
              const CircleAvatar(radius: 43, backgroundColor: Color(0xFFE7E8FF),
                child: Icon(Icons.person_outline, size: 46, color: _teal)),
              const SizedBox(height: 14),
              Text(name, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 6),
              Text(role, style: const TextStyle(color: _muted)),
              if (data.petCount != null) ...[
                const SizedBox(height: 5),
                Text(profilePetsSummary(data.petCount!),
                  style: const TextStyle(color: _muted, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              _unavailableAction('Editar perfil', Icons.edit_outlined),
            ])),
            const SizedBox(height: 18),
            _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionTitle('INFORMACIÓN DE CONTACTO'),
              const SizedBox(height: 16),
              _infoRow(Icons.email_outlined, 'Correo electrónico', email),
              const Divider(height: 26, color: Color(0xFFE9EEF5)),
              _infoRow(Icons.phone_outlined, 'Teléfono', 'No disponible en la API'),
              const Divider(height: 26, color: Color(0xFFE9EEF5)),
              _infoRow(Icons.badge_outlined, 'ID del propietario', profileValue(user['userId'])),
            ])),
            const SizedBox(height: 18),
            _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _SectionTitle('PREFERENCIAS'),
              const SizedBox(height: 16),
              Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFFFFF7ED),
                  child: Icon(Icons.notifications_none, color: Color(0xFFEA8B23))),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w600, color: _ink)),
                  SizedBox(height: 3),
                  Text('Configuración pendiente de integración',
                    style: TextStyle(fontSize: 12, color: _muted)),
                ])),
                const Icon(Icons.info_outline, color: _muted, size: 20),
              ]),
            ])),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE34D61),
                side: const BorderSide(color: Color(0xFFFFCED5)),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 20),
            const Center(child: Text('VetPax · Cuidado continuo veterinario',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
          ]),
        );
      },
    )),
  );
}

Widget _panel({required Widget child}) => Container(
  width: double.infinity,
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFEBEFF5))),
  child: child,
);

Widget _infoRow(IconData icon, String label, String value) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CircleAvatar(backgroundColor: const Color(0xFFEFF6FF),
      child: Icon(icon, color: _teal, size: 21)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      const SizedBox(height: 4),
      SelectableText(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
    ])),
  ],
);

Widget _unavailableAction(String label, IconData icon) => SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: null,
    icon: Icon(icon, size: 18), label: Text('$label · Próximamente'),
    style: OutlinedButton.styleFrom(
      disabledForegroundColor: const Color(0xFF688A85),
      backgroundColor: const Color(0xFFF1FAF8),
      side: const BorderSide(color: Color(0xFFBCF0E7)),
      minimumSize: const Size.fromHeight(48),
    ),
  ),
);

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override Widget build(BuildContext context) => Text(title,
    style: const TextStyle(fontSize: 12, letterSpacing: .7,
      fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)));
}
