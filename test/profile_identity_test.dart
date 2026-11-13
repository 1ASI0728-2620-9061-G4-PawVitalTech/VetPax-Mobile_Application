import 'package:flutter_test/flutter_test.dart';
import 'package:vetpax_frontend/features/vetpax/presentation/profile/profile_identity.dart';

void main() {
  test('la cuenta sin nombre no inventa datos personales', () {
    expect(profileDisplayName({'email': 'persona@example.com'}), 'Mi cuenta');
  });
  test('muestra nombres solo si el backend los devuelve', () {
    expect(profileDisplayName({'firstName': 'Ana', 'lastName': 'Pérez'}), 'Ana Pérez');
  });
  test('traduce el rol de propietario', () {
    expect(profileRoleLabel('owner'), 'Propietario');
  });
  test('distingue singular y plural de mascotas', () {
    expect(profilePetsSummary(1), '1 mascota registrada');
    expect(profilePetsSummary(0), '0 mascotas registradas');
  });
  test('maneja valores ausentes', () {
    expect(profileValue(null), 'No disponible');
    expect(profileValue('  '), 'No disponible');
  });
}
