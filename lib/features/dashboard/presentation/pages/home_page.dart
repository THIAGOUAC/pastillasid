import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../medications/domain/entities/medication_entity.dart';
import '../../../medications/presentation/controllers/medication_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);

    final activeMedications = medications
        .where((item) => item.isActive)
        .toList();

    final lowStockMedications = medications.where((item) {
      return item.hasLowStock;
    }).toList();

    final totalTakesToday = activeMedications.fold<int>(
      0,
      (total, medication) => total + medication.times.length,
    );

    final nextTake = _findNextTake(activeMedications);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Hola 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Este es el resumen de tus medicamentos.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.alarm,
            title: 'Próxima toma',
            subtitle: nextTake == null
                ? 'No hay más tomas programadas para hoy'
                : '${nextTake.medicationName} a las ${nextTake.time}',
          ),
          _SummaryCard(
            icon: Icons.today,
            title: 'Tomas de hoy',
            subtitle: '$totalTakesToday toma(s) programada(s)',
          ),
          _SummaryCard(
            icon: Icons.warning_amber,
            title: 'Stock bajo',
            subtitle: lowStockMedications.isEmpty
                ? 'No tienes medicamentos con stock bajo'
                : '${lowStockMedications.length} medicamento(s) necesitan reabastecimiento',
            isAlert: lowStockMedications.isNotEmpty,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Medicamentos activos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          if (activeMedications.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Todavía no tienes tratamientos activos.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...activeMedications.map((medication) {
              return Card(
                child: ListTile(
                  leading: Icon(
                    _medicationIcon(medication.type),
                    color: medication.hasLowStock
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    medication.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${medication.times.length} toma(s) al día • Stock: ${_formatNumber(medication.currentStock)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: medication.hasLowStock
                      ? Icon(
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                        )
                      : const Icon(Icons.check_circle_outline),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isAlert;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _NextTake {
  final String medicationName;
  final String time;

  const _NextTake({required this.medicationName, required this.time});
}

_NextTake? _findNextTake(List<MedicationEntity> medications) {
  final now = TimeOfDay.now();
  final nowMinutes = now.hour * 60 + now.minute;

  _NextTake? nextTake;
  int? nextMinutes;

  for (final medication in medications) {
    for (final time in medication.times) {
      final parts = time.split(':');

      if (parts.length != 2) continue;

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) continue;

      final medicationMinutes = hour * 60 + minute;

      if (medicationMinutes >= nowMinutes) {
        if (nextMinutes == null || medicationMinutes < nextMinutes) {
          nextMinutes = medicationMinutes;
          nextTake = _NextTake(medicationName: medication.name, time: time);
        }
      }
    }
  }

  return nextTake;
}

IconData _medicationIcon(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return Icons.medication;
    case MedicationType.capsule:
      return Icons.medication_liquid;
    case MedicationType.syrup:
      return Icons.local_drink;
    case MedicationType.drops:
      return Icons.water_drop;
    case MedicationType.injection:
      return Icons.vaccines;
    case MedicationType.cream:
      return Icons.spa;
    case MedicationType.other:
      return Icons.medical_services;
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
