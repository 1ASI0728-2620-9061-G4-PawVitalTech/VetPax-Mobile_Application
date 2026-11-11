/// Clínica del directorio (GET /clinics). El propietario solo ve estos datos:
/// el detalle con horarios de atención es exclusivo de veterinarios y administradores.
class Clinic {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? email;

  const Clinic({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.email,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(
        id: (json['clinicId'] ?? json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        phone: _clean(json['phone']),
        email: _clean(json['contactEmail'] ?? json['email']),
      );

  /// Búsqueda simple por nombre o dirección, sin distinguir mayúsculas.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || address.toLowerCase().contains(q);
  }
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}