import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:vetpax_frontend/core/api/api_client.dart';

// Mensajes del backend (en inglés) que conviene mostrar en español.
const Map<String, String> _knownMessages = {
  'Appointment must be scheduled in the future.':
      'La cita debe programarse en un horario futuro.',
  'Appointment reason cannot exceed 500 characters.':
      'El motivo no puede superar los 500 caracteres.',
  'Appointments must start on a 30-minute boundary.':
      'Las citas deben iniciar en punto o y media.',
  'The new schedule must be different.':
      'El nuevo horario debe ser distinto al actual.',
  'Appointment not found.': 'No se encontró la cita.',
  'Clinic not found.': 'No se encontró la clínica.',
};

/// Convierte cualquier error en un texto claro para la persona usuaria.
String friendlyError(Object error) {
  if (error is VetPaxApiException) {
    final known = _knownMessages[error.message];
    switch (error.statusCode) {
      case 400:
      case 409:
        return known ?? error.message;
      case 401:
        return 'Tu sesión expiró. Inicia sesión nuevamente.';
      case 403:
        return 'No tienes permiso para realizar esta acción.';
      case 404:
        return known ?? 'No se encontró lo que buscas.';
      default:
        if (error.statusCode >= 500) {
          return 'El servidor no pudo procesar la solicitud. Inténtalo de nuevo en unos minutos.';
        }
        return known ?? error.message;
    }
  }
  if (error is TimeoutException) {
    return 'La solicitud tardó demasiado. Revisa tu conexión e inténtalo otra vez.';
  }
  if (error is http.ClientException) {
    return 'No se pudo conectar con el servidor. Revisa tu conexión.';
  }
  return 'Ocurrió un error inesperado. Inténtalo otra vez.';
}