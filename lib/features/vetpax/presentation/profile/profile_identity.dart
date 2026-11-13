// Vista segura del contrato GET /api/v1/auth/me: userId, email y role.
// El backend actual NO devuelve nombres, telefono ni preferencias.
String profileValue(Object? value, {String fallback = 'No disponible'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String profileDisplayName(Map<String, dynamic> user) {
  final firstName = user['firstName']?.toString().trim() ?? '';
  final lastName = user['lastName']?.toString().trim() ?? '';
  final combined = [firstName, lastName].where((part) => part.isNotEmpty).join(' ');
  return combined.isNotEmpty ? combined : 'Mi cuenta';
}

String profileRoleLabel(Object? role) {
  switch (role?.toString().toLowerCase()) {
    case 'owner': return 'Propietario';
    case 'veterinarian': return 'Veterinario';
    case 'clinic_administrator': return 'Administrador de clínica';
    default: return profileValue(role);
  }
}

String profilePetsSummary(int count) =>
    count == 1 ? '1 mascota registrada' : '$count mascotas registradas';
