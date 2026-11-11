import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/features/appointments/data/datasources/appointments_local_data_source.dart';
import 'package:vetpax_frontend/features/appointments/data/datasources/appointments_remote_data_source.dart';
import 'package:vetpax_frontend/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:vetpax_frontend/features/appointments/domain/entities/appointment.dart';
import 'package:vetpax_frontend/features/appointments/domain/usecases/get_my_appointments.dart';
import 'support/memory_key_value_store.dart';
import 'support/test_support.dart';

Map<String, dynamic> _appt(String id, {String date = '2026-11-12', String start = '10:30:00', String end = '11:00:00', String status = 'Pending'}) => {
      'appointmentId': id, 'ownerId': 'o1', 'petId': 'p1', 'clinicId': 'c1', 'veterinarianId': 'v1',
      'date': date, 'startTime': start, 'endTime': end, 'reason': 'Control', 'status': status,
      'clinicalAttentionId': status == 'Attended' ? 'att-1' : null,
      'createdAt': '2026-11-01T10:00:00Z', 'updatedAt': '2026-11-01T10:00:00Z',
    };

AppointmentsRepositoryImpl _repo(ApiClient api, MemoryKeyValueStore store, {MemoryTokenStorage? tokens}) =>
    AppointmentsRepositoryImpl(
      remote: AppointmentsRemoteDataSource(api),
      local: AppointmentsLocalDataSource(store: store, tokenStorage: tokens ?? MemoryTokenStorage()),
    );

// "Ahora" fijo en Lima: martes 10/11/2026 12:00.
DateTime _now() => DateTime(2026, 11, 10, 12);

void main() {
  group('Entidades', () {
    test('Appointment.fromJson y etiquetas de hora', () {
      final a = Appointment.fromJson(_appt('a1'));
      expect(a.id, 'a1');
      expect(a.status, AppointmentStatus.pending);
      expect(a.startLabel, '10:30');
      expect(a.endLabel, '11:00');
      expect(a.startsAt, DateTime(2026, 11, 12, 10, 30));
    });

    test('vigente y modificable según la hora de Lima', () {
      final future = Appointment.fromJson(_appt('a1'));
      final ongoing = Appointment.fromJson(_appt('a2', date: '2026-11-10', start: '11:45:00', end: '12:15:00'));
      final cancelled = Appointment.fromJson(_appt('a3', status: 'Cancelled'));
      expect(future.isUpcoming(_now()), isTrue);
      expect(future.canModify(_now()), isTrue);
      expect(ongoing.isUpcoming(_now()), isTrue);   // aún no termina
      expect(ongoing.canModify(_now()), isFalse);   // ya empezó
      expect(cancelled.isUpcoming(_now()), isFalse);
      expect(cancelled.canModify(_now()), isFalse);
    });

    test('estado desconocido no rompe', () {
      expect(appointmentStatusFrom('Algo'), AppointmentStatus.unknown);
      expect(appointmentStatusFrom(null), AppointmentStatus.unknown);
      expect(appointmentStatusFrom('Attended'), AppointmentStatus.attended);
    });

    test('Availability.fromJson', () {
      final a = Availability.fromJson({
        'clinicId': 'c1', 'veterinarianId': 'v1', 'date': '2026-11-12', 'timeZoneId': 'America/Lima',
        'durationMinutes': 30, 'slots': [{'startTime': '09:00:00', 'endTime': '09:30:00'}, {'startTime': '09:30:00', 'endTime': '10:00:00'}],
      });
      expect(a.slots, hasLength(2));
      expect(a.slots.first.label, '09:00');
      expect(a.durationMinutes, 30);
    });
  });

  group('GetMyAppointments', () {
    test('separa próximas (ascendente) y anteriores (más reciente primero)', () async {
      final store = MemoryKeyValueStore();
      final data = {
        'late': _appt('late', date: '2026-12-01'),
        'soon': _appt('soon', date: '2026-11-11'),
        'old1': _appt('old1', date: '2026-10-01'),
        'old2': _appt('old2', date: '2026-10-20'),
        'cancelled': _appt('cancelled', date: '2026-11-20', status: 'Cancelled'),
      };
      store.data['vp_appointments_user-1'] = data.keys.toList();
      final api = apiWith((r) async => http.Response(jsonEncode(data[r.url.pathSegments.last]), 200));
      final result = await GetMyAppointments(_repo(api, store), clock: _now)();
      expect(result.upcoming.map((a) => a.id).toList(), ['soon', 'late']);
      expect(result.past.map((a) => a.id).toList(), ['cancelled', 'old2', 'old1']);
    });
  });

  group('Repositorio', () {
    test('agendar envía el cuerpo correcto y guarda el id', () async {
      final store = MemoryKeyValueStore();
      late Map<String, dynamic> sent;
      final api = apiWith((r) async {
        expect(r.method, 'POST');
        expect(r.url.path, '/api/v1/appointments');
        sent = Map<String, dynamic>.from(jsonDecode(r.body) as Map);
        return http.Response(jsonEncode(_appt('new-1')), 201);
      });
      final appt = await _repo(api, store).book(
          petId: 'p1', clinicId: 'c1', veterinarianId: 'v1', date: '2026-11-12', startTime: '10:30:00', reason: 'Control');
      expect(appt.id, 'new-1');
      expect(sent, {'petId': 'p1', 'clinicId': 'c1', 'veterinarianId': 'v1', 'date': '2026-11-12', 'startTime': '10:30:00', 'reason': 'Control'});
      expect(store.data['vp_appointments_user-1'], ['new-1']);
    });

    test('no guarda el id si el backend rechaza la cita (409)', () async {
      final store = MemoryKeyValueStore();
      final api = apiWith((r) async => http.Response(jsonEncode({'detail': 'Slot taken'}), 409));
      await expectLater(
          _repo(api, store).book(petId: 'p', clinicId: 'c', veterinarianId: 'v', date: '2026-11-12', startTime: '10:30:00', reason: 'x'),
          throwsA(isA<VetPaxApiException>()));
      expect(store.data.isEmpty, isTrue);
    });

    test('cada usuario tiene su propio registro', () async {
      final store = MemoryKeyValueStore();
      final api = apiWith((r) async => http.Response(jsonEncode(_appt('x1')), 201));
      await _repo(api, store, tokens: MemoryTokenStorage(userId: 'ana')).book(
          petId: 'p', clinicId: 'c', veterinarianId: 'v', date: '2026-11-12', startTime: '10:30:00', reason: 'x');
      expect(store.data['vp_appointments_ana'], ['x1']);
      expect(store.data['vp_appointments_luis'], isNull);
    });

    test('elimina del registro las citas que ya no existen (404) y conserva el resto', () async {
      final store = MemoryKeyValueStore();
      store.data['vp_appointments_user-1'] = ['gone', 'ok'];
      final api = apiWith((r) async => r.url.pathSegments.last == 'gone'
          ? http.Response(jsonEncode({'message': 'Appointment not found.'}), 404)
          : http.Response(jsonEncode(_appt('ok')), 200));
      final items = await _repo(api, store).getMyAppointments();
      expect(items.map((a) => a.id).toList(), ['ok']);
      expect(store.data['vp_appointments_user-1'], ['ok']);
    });

    test('un fallo de red no borra el registro y se informa si todas fallan', () async {
      final store = MemoryKeyValueStore();
      store.data['vp_appointments_user-1'] = ['a', 'b'];
      final api = apiWith((r) async => throw http.ClientException('sin red'));
      await expectLater(_repo(api, store).getMyAppointments(), throwsA(isA<http.ClientException>()));
      expect(store.data['vp_appointments_user-1'], ['a', 'b']);
    });

    test('si solo falla una, se muestran las demás', () async {
      final store = MemoryKeyValueStore();
      store.data['vp_appointments_user-1'] = ['a', 'b'];
      final api = apiWith((r) async => r.url.pathSegments.last == 'a'
          ? http.Response('{}', 500)
          : http.Response(jsonEncode(_appt('b')), 200));
      final items = await _repo(api, store).getMyAppointments();
      expect(items.map((a) => a.id).toList(), ['b']);
    });

    test('sin citas guardadas no llama a la API', () async {
      var calls = 0;
      final api = apiWith((r) async { calls++; return http.Response('[]', 200); });
      expect(await _repo(api, MemoryKeyValueStore()).getMyAppointments(), isEmpty);
      expect(calls, 0);
    });

    test('cancelar y reprogramar usan PATCH con la operación correcta', () async {
      final bodies = <Map<String, dynamic>>[];
      final api = apiWith((r) async {
        expect(r.method, 'PATCH');
        expect(r.url.path, '/api/v1/appointments/a1');
        bodies.add(Map<String, dynamic>.from(jsonDecode(r.body) as Map));
        return http.Response(jsonEncode(_appt('a1', status: bodies.length == 1 ? 'Cancelled' : 'Pending')), 200);
      });
      final repo = _repo(api, MemoryKeyValueStore());
      final cancelled = await repo.cancel('a1');
      await repo.reschedule('a1', date: '2026-11-15', startTime: '09:00:00');
      expect(cancelled.status, AppointmentStatus.cancelled);
      expect(bodies[0], {'operation': 'cancel'});
      expect(bodies[1], {'operation': 'reschedule', 'date': '2026-11-15', 'startTime': '09:00:00'});
    });

    test('mascotas y disponibilidad usan los parámetros del backend', () async {
      final api = apiWith((r) async {
        if (r.url.path.endsWith('/pets')) return http.Response(jsonEncode([{'petId': 'p1', 'name': 'Luna', 'species': 'Dog'}]), 200);
        expect(r.url.queryParameters, {'clinicId': 'c1', 'veterinarianId': 'v1', 'date': '2026-11-12'});
        return http.Response(jsonEncode({'clinicId': 'c1', 'veterinarianId': 'v1', 'date': '2026-11-12', 'timeZoneId': 'America/Lima', 'durationMinutes': 30, 'slots': []}), 200);
      });
      final repo = _repo(api, MemoryKeyValueStore());
      expect((await repo.getMyPets()).single.name, 'Luna');
      expect((await repo.getAvailability(clinicId: 'c1', veterinarianId: 'v1', date: '2026-11-12')).slots, isEmpty);
    });
  });
}
