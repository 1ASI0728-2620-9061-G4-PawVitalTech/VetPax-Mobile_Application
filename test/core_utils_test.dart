import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/core/errors/error_messages.dart';
import 'package:vetpax_frontend/core/utils/date_time_utils.dart';

void main() {
  group('Fechas', () {
    test('hora de Lima es UTC-5 sin importar la zona del teléfono', () {
      // 03:00 UTC del 11/11 = 22:00 del 10/11 en Lima
      expect(limaNow(DateTime.utc(2026, 11, 11, 3)), DateTime(2026, 11, 10, 22));
    });
    test('parse y formato de DateOnly/TimeOnly', () {
      expect(parseDateOnly('2026-11-10'), DateTime(2026, 11, 10));
      expect(parseDateOnly('2026-11-10T00:00:00'), DateTime(2026, 11, 10));
      expect(toDateOnly(DateTime(2026, 1, 5)), '2026-01-05');
      expect(hhmm('09:30:00'), '09:30');
      expect(hhmm('9:05'), '09:05');
    });
    test('formatos en español', () {
      expect(longDateEs(DateTime(2026, 11, 10)), 'Martes, 10 de noviembre de 2026');
      expect(mediumDateEs(DateTime(2026, 12, 25)), 'Viernes, 25 de diciembre');
      expect(shortDateEs(DateTime(2026, 3, 4)), '04/03/2026');
    });
    test('valores inválidos lanzan FormatException', () {
      expect(() => parseDateOnly('hoy'), throwsA(isA<FormatException>()));
      expect(() => parseTimeOnly('abc'), throwsA(isA<FormatException>()));
    });
  });

  group('friendlyError', () {
    test('traduce mensajes conocidos y códigos HTTP', () {
      expect(friendlyError(const VetPaxApiException(400, 'Appointment must be scheduled in the future.')),
          'La cita debe programarse en un horario futuro.');
      expect(friendlyError(const VetPaxApiException(409, 'Horario ocupado')), 'Horario ocupado');
      expect(friendlyError(const VetPaxApiException(403, 'x')), 'No tienes permiso para realizar esta acción.');
      expect(friendlyError(const VetPaxApiException(401, 'x')), 'Tu sesión expiró. Inicia sesión nuevamente.');
      expect(friendlyError(const VetPaxApiException(500, 'x')), contains('servidor'));
      expect(friendlyError(const VetPaxApiException(404, 'otro')), 'No se encontró lo que buscas.');
    });
    test('red y timeout', () {
      expect(friendlyError(http.ClientException('x')), contains('conectar'));
      expect(friendlyError(TimeoutException('x')), contains('tardó'));
      expect(friendlyError(StateError('x')), contains('inesperado'));
    });
  });
}
