import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vetpax_frontend/features/clinics/data/datasources/clinics_remote_data_source.dart';
import 'package:vetpax_frontend/features/clinics/data/repositories/clinics_repository_impl.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/clinic.dart';
import 'package:vetpax_frontend/features/clinics/domain/entities/veterinarian.dart';
import 'support/test_support.dart';

Map<String, dynamic> _clinic(String id, String name) =>
    {'clinicId': id, 'name': name, 'address': 'Av. $name 123', 'phone': '999', 'contactEmail': '$id@vet.pe'};

void main() {
  group('Clínicas', () {
    test('Clinic.fromJson lee contactEmail y limpia vacíos', () {
      final clinic = Clinic.fromJson({'clinicId': 'c1', 'name': 'VetCare', 'address': 'Lima', 'phone': '  ', 'contactEmail': 'a@b.pe'});
      expect(clinic.id, 'c1');
      expect(clinic.phone, isNull);
      expect(clinic.email, 'a@b.pe');
    });

    test('la búsqueda ignora mayúsculas y revisa nombre y dirección', () {
      final clinic = Clinic.fromJson(_clinic('c1', 'VetCare'));
      expect(clinic.matches('vetcare'), isTrue);
      expect(clinic.matches('av. vet'), isTrue);
      expect(clinic.matches('otra'), isFalse);
      expect(clinic.matches('  '), isTrue);
    });

    test('recorre todas las páginas del directorio (pageSize 50)', () async {
      final requested = <String>[];
      final api = apiWith((request) async {
        requested.add('${request.url.queryParameters['page']}/${request.url.queryParameters['pageSize']}');
        final page = request.url.queryParameters['page'];
        final items = page == '1' ? [_clinic('c1', 'Zeta'), _clinic('c2', 'Alfa')] : [_clinic('c3', 'Beta')];
        return http.Response(jsonEncode({'page': 1, 'pageSize': 50, 'totalCount': 3, 'items': items}), 200);
      });
      final clinics = await ClinicsRepositoryImpl(ClinicsRemoteDataSource(api)).getClinics();
      expect(requested, ['1/50', '2/50']);
      expect(clinics.map((c) => c.name).toList(), ['Alfa', 'Beta', 'Zeta']); // ordenadas
    });

    test('se detiene si la API devuelve una página vacía', () async {
      var calls = 0;
      final api = apiWith((request) async {
        calls++;
        return http.Response(jsonEncode({'page': 1, 'pageSize': 50, 'totalCount': 10, 'items': []}), 200);
      });
      final clinics = await ClinicsRemoteDataSource(api).fetchClinics();
      expect(clinics, isEmpty);
      expect(calls, 1);
    });

    test('veterinarios: arreglo de veterinarianId', () async {
      final api = apiWith((request) async {
        expect(request.url.path, '/api/v1/clinics/c1/veterinarians');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(jsonEncode([{'veterinarianId': 'abcdef12-0000-0000-0000-000000000000'}]), 200);
      });
      final vets = await ClinicsRemoteDataSource(api).fetchVeterinarians('c1');
      expect(vets, hasLength(1));
      expect(vets.single.shortId, 'abcdef12');
      expect(vets.single.displayName, 'Veterinario ABCDEF12');
    });

    test('Veterinarian con id corto no falla', () {
      expect(const Veterinarian(id: 'abc').shortId, 'abc');
    });
  });
}
