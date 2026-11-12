import 'package:flutter_test/flutter_test.dart';
import 'package:vetpax_frontend/features/vetpax/presentation/pets/pet_ui.dart';

void main() {
  test('traduce valores de especie y sexo del backend', () {
    expect(speciesLabel('Dog'), 'Perro');
    expect(speciesLabel('Cat'), 'Gato');
    expect(sexLabel('Male'), 'Macho');
    expect(sexLabel('Female'), 'Hembra');
  });

  test('el perfil no inventa valores inexistentes', () {
    expect(petText(null), 'No informado');
    expect(petText(''), 'No informado');
    expect(petAge('fecha-invalida'), isNull);
  });

  test('muestra fechas del backend legibles', () {
    expect(readableDate('2020-03-15'), '15/03/2020');
  });
}
