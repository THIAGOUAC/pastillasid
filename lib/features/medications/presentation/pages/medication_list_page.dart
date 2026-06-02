import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/medication_entity.dart';
import '../controllers/medication_controller.dart';

class MedicationListPage extends ConsumerWidget {
  const MedicationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Mis medicamentos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Registra tus tratamientos, dosis, horarios y stock disponible.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.add_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Agregar medicamento',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Registro manual de medicina, dosis y horarios',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/medications/new'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Escanear receta con IA',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                'Extraer datos desde una foto de receta o medicamento',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/scan'),
            ),
          ),
          const SizedBox(height: 12),
          if (medications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aún no registraste medicamentos',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer medicamento para comenzar a organizar tus tomas.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...medications.map(
              (medication) => _MedicationCard(medication: medication),
            ),
        ],
      ),
    );
  }
}

class _MedicationCard extends ConsumerWidget {
  final MedicationEntity medication;

  const _MedicationCard({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doseText =
        '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}';

    final stockText = _formatNumber(medication.currentStock);

    return Card(
      child: ListTile(
        onTap: () => context.push('/medications/${medication.id}'),
        leading: CircleAvatar(
          backgroundColor: medication.hasLowStock
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
          child: Icon(
            _medicationIcon(medication.type),
            color: medication.hasLowStock
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          medication.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '$doseText • ${medication.times.join(", ")}\nStock: $stockText',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            ref
                .read(medicationListProvider.notifier)
                .deleteMedication(medication.id);
          },
        ),
      ),
    );
  }
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

String _doseUnitLabel(DoseUnit unit) {
  switch (unit) {
    case DoseUnit.pill:
      return 'píldora(s)';
    case DoseUnit.capsule:
      return 'cápsula(s)';
    case DoseUnit.ml:
      return 'ml';
    case DoseUnit.tablespoon:
      return 'cucharada(s)';
    case DoseUnit.teaspoon:
      return 'cucharadita(s)';
    case DoseUnit.drops:
      return 'gota(s)';
    case DoseUnit.injection:
      return 'inyección(es)';
    case DoseUnit.application:
      return 'aplicación(es)';
    case DoseUnit.other:
      return 'unidad(es)';
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
