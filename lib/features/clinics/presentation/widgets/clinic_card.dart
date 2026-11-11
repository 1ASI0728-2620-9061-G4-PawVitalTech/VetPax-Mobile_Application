import 'package:flutter/material.dart';
import 'package:vetpax_frontend/core/ui/vetpax_ui.dart';
import '../../domain/entities/clinic.dart';

class ClinicCard extends StatelessWidget {
  final Clinic clinic;
  final VoidCallback onTap;
  const ClinicCard({super.key, required this.clinic, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        surfaceTintColor: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: kSoftBlue, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.local_hospital_outlined, color: kBrandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(clinic.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16, color: kTextDark)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined, size: 15, color: kMuted),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(clinic.address.isEmpty ? 'Sin dirección registrada' : clinic.address,
                            style: const TextStyle(color: kMuted, fontSize: 13))),
                  ]),
                  if (clinic.phone != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.phone_outlined, size: 15, color: kMuted),
                      const SizedBox(width: 4),
                      Text(clinic.phone!, style: const TextStyle(color: kMuted, fontSize: 13)),
                    ]),
                  ],
                ]),
              ),
              const Icon(Icons.chevron_right, color: kMuted),
            ]),
          ),
        ),
      );
}
