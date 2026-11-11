import 'package:flutter/material.dart';

// Piezas visuales compartidas por las pantallas de Clínicas y Citas.
// Los colores coinciden con los de la barra de navegación de la app.
const Color kBrandBlue = Color(0xFF2563EB);
const Color kTextDark = Color(0xFF1F2937);
const Color kMuted = Color(0xFF6B7280);
const Color kSoftBlue = Color(0xFFEFF6FF);
const Color kOk = Color(0xFF059669);
const Color kDanger = Color(0xFFDC2626);

void showAppMessage(BuildContext context, String text, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? kDanger : null,
    ));
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: kDanger, size: 36),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ]),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(children: [
          Icon(icon, size: 44, color: kMuted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: kMuted)),
        ]),
      );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}