import 'package:flutter/material.dart';

const petTeal = Color(0xFF12B5A5);
const petInk = Color(0xFF183047);
const petMuted = Color(0xFF64748B);
const petCanvas = Color(0xFFF5F7FC);

String petText(dynamic value, {String fallback = 'No informado'}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String speciesLabel(dynamic species) {
  switch (species?.toString().toLowerCase()) {
    case 'dog': return 'Perro';
    case 'cat': return 'Gato';
    default: return petText(species);
  }
}

String sexLabel(dynamic sex) {
  switch (sex?.toString().toLowerCase()) {
    case 'male': return 'Macho';
    case 'female': return 'Hembra';
    default: return petText(sex);
  }
}

String readableDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return petText(value);
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String? petAge(dynamic value) {
  final birth = DateTime.tryParse(value?.toString() ?? '');
  if (birth == null) return null;
  final now = DateTime.now();
  var years = now.year - birth.year;
  if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
  if (years < 0) return null;
  return '$years ${years == 1 ? 'año' : 'años'}';
}

Widget petPanel({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(18)}) =>
    Container(width: double.infinity, padding: padding,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EDF5))), child: child);

Widget petNotice(String message, {IconData icon = Icons.info_outline, Color color = petTeal}) =>
    Container(padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [Icon(icon, color: color), const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: petInk, height: 1.45)))]));

Widget petFailure(Object error, VoidCallback onRetry) => Center(
  child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.wifi_off_outlined, color: petMuted, size: 42),
    const SizedBox(height: 12), const Text('No se pudo cargar la información',
      textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: petInk)),
    const SizedBox(height: 8), Text('$error', textAlign: TextAlign.center,
      style: const TextStyle(color: petMuted)),
    const SizedBox(height: 12), OutlinedButton.icon(onPressed: onRetry,
      icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
  ])));

ButtonStyle petPrimaryStyle() => FilledButton.styleFrom(
  backgroundColor: petTeal, foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
);
