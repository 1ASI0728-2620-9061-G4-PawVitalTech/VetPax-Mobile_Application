enum Role { owner, veterinarian, clinicAdministrator }

class User {
  final String id; // UUID de Keycloak, no entero de la app anterior.
  final String email;
  final Role role;
  final String firstName;
  final String lastName;
  const User({required this.id, required this.email, required this.role,
    this.firstName = '', this.lastName = ''});

  factory User.fromJson(Map<String, dynamic> json) {
    final roleName = (json['role'] ?? 'owner').toString().toLowerCase();
    final role = switch (roleName) {
      'owner' => Role.owner,
      'veterinarian' => Role.veterinarian,
      'clinic_administrator' => Role.clinicAdministrator,
      _ => throw FormatException('Rol de VetPax desconocido: $roleName'),
    };
    return User(
      id: (json['userId'] ?? json['id']).toString(),
      email: (json['email'] ?? '').toString(),
      role: role,
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
    );
  }
}
