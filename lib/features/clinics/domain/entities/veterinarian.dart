/// Veterinario activo de una clínica. La API solo expone su identificador.
class Veterinarian {
  final String id;
  const Veterinarian({required this.id});

  factory Veterinarian.fromJson(Map<String, dynamic> json) =>
      Veterinarian(id: (json['veterinarianId'] ?? json['id'] ?? '').toString());

  String get shortId => id.length > 8 ? id.substring(0, 8) : id;

  /// Texto para mostrar mientras la API no entregue el nombre.
  String get displayName => 'Veterinario ${shortId.toUpperCase()}';
}
