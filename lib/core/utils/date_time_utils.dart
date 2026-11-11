// Utilidades de fecha y hora sin dependencias externas (sin Flutter ni intl).
//
// El backend trabaja con DateOnly ("2026-11-10") y TimeOnly ("10:30:00") y
// valida las citas con la hora de Lima (UTC-5, sin horario de verano).
// Aquí un DateTime "naive" representa siempre la hora de pared de Lima.

const List<String> _weekdays = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];
const List<String> _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto',
  'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Offset fijo de Lima respecto a UTC.
const Duration limaOffset = Duration(hours: -5);

/// Hora actual de Lima como DateTime sin zona (independiente de la zona del teléfono).
DateTime limaNow([DateTime? now]) {
  final shifted = (now ?? DateTime.now()).toUtc().add(limaOffset);
  return DateTime(shifted.year, shifted.month, shifted.day, shifted.hour,
      shifted.minute, shifted.second);
}

/// "2026-11-10" -> DateTime(2026, 11, 10). Lanza FormatException si no es válida.
DateTime parseDateOnly(String value) {
  final parts = value.split('T').first.split('-');
  if (parts.length != 3) throw FormatException('Fecha inválida: $value');
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw FormatException('Fecha inválida: $value');
  }
  return DateTime(year, month, day);
}

/// DateTime -> "2026-11-10" (formato que espera la API).
String toDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// "10:30:00" o "10:30" -> (10, 30). Lanza FormatException si no es válida.
({int hour, int minute}) parseTimeOnly(String value) {
  final parts = value.split(':');
  if (parts.length < 2) throw FormatException('Hora inválida: $value');
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) throw FormatException('Hora inválida: $value');
  return (hour: hour, minute: minute);
}

/// "10:30:00" -> "10:30"
String hhmm(String value) {
  final t = parseTimeOnly(value);
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// "Miércoles, 15 de octubre de 2026"
String longDateEs(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1]} de ${date.year}';

/// "Miércoles, 15 de octubre"
String mediumDateEs(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1]}';

/// "15/10/2026"
String shortDateEs(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';