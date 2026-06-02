import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../domain/entities/medication_entity.dart';
import '../controllers/medication_controller.dart';

class MedicationDetailPage extends ConsumerWidget {
  final String medicationId;

  const MedicationDetailPage({super.key, required this.medicationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationListProvider);

    final medication = medications
        .where((item) => item.id == medicationId)
        .firstOrNull;

    if (medication == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medicamento')),
        body: const Center(child: Text('No se encontró el medicamento')),
      );
    }

    final doseText =
        '${_formatNumber(medication.doseAmount)} ${_doseUnitLabel(medication.doseUnit)}';

    return Scaffold(
      appBar: AppBar(title: Text(medication.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _medicationIcon(medication.type),
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      medication.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medication.isActive
                          ? 'Tratamiento activo'
                          : 'Tratamiento desactivado',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            _InfoCard(
              title: 'Dosis',
              children: [
                _InfoRow(
                  icon: Icons.medication,
                  label: 'Tipo',
                  value: _medicationTypeLabel(medication.type),
                ),
                _InfoRow(
                  icon: Icons.format_list_numbered,
                  label: 'Cantidad',
                  value: doseText,
                ),
              ],
            ),
            _InfoCard(
              title: 'Horarios',
              children: medication.times.map((time) {
                return _InfoRow(
                  icon: Icons.schedule,
                  label: 'Toma',
                  value: time,
                );
              }).toList(),
            ),
            _InfoCard(
              title: 'Tratamiento',
              children: [
                _InfoRow(
                  icon: Icons.today,
                  label: 'Inicio',
                  value: _formatDate(medication.startDate),
                ),
                _InfoRow(
                  icon: Icons.date_range,
                  label: 'Duración',
                  value: medication.treatmentDays == null
                      ? 'No especificada'
                      : '${medication.treatmentDays} día(s)',
                ),
              ],
            ),
            _InfoCard(
              title: 'Stock',
              children: [
                _InfoRow(
                  icon: Icons.inventory_2,
                  label: 'Disponible',
                  value: _formatNumber(medication.currentStock),
                ),
                _InfoRow(
                  icon: Icons.remove_circle_outline,
                  label: 'Por toma',
                  value: _formatNumber(medication.stockPerDose),
                ),
                _InfoRow(
                  icon: Icons.warning_amber,
                  label: 'Alerta',
                  value:
                      'Cuando queden ${_formatNumber(medication.minimumStockAlert)}',
                ),
              ],
            ),
            if (medication.instructions != null)
              _InfoCard(
                title: 'Indicaciones',
                children: [
                  _InfoRow(
                    icon: Icons.notes,
                    label: 'Nota',
                    value: medication.instructions!,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: medication.currentStock <= 0
                  ? null
                  : () async {
                      await ref
                          .read(medicationListProvider.notifier)
                          .markDoseAsTaken(medication.id);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Toma registrada y stock actualizado',
                            ),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.check_circle),
              label: const Text('Ya tomé'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: medication.isActive
                  ? () async {
                      await NotificationService.scheduleSnoozeReminder(
                        medicationName: medication.name,
                        doseText: doseText,
                        minutes: 10,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Recordatorio pospuesto por 10 minutos',
                            ),
                          ),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.snooze),
              label: const Text('Lo tomaré en 10 minutos'),
            ),
            if (medication.hasLowStock)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: const Text('Stock bajo'),
                    subtitle: const Text(
                      'Este medicamento está por acabarse. Considera reabastecerte.',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                context.push('/medications/edit/${medication.id}');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar medicamento'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(medicationListProvider.notifier)
                    .toggleMedicationStatus(medication.id);
              },
              icon: Icon(
                medication.isActive ? Icons.pause_circle : Icons.play_circle,
              ),
              label: Text(
                medication.isActive
                    ? 'Desactivar tratamiento'
                    : 'Activar tratamiento',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                ref
                    .read(medicationListProvider.notifier)
                    .deleteMedication(medication.id);

                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
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

String _medicationTypeLabel(MedicationType type) {
  switch (type) {
    case MedicationType.pill:
      return 'Pastilla';
    case MedicationType.capsule:
      return 'Cápsula';
    case MedicationType.syrup:
      return 'Jarabe';
    case MedicationType.drops:
      return 'Gotas';
    case MedicationType.injection:
      return 'Inyección';
    case MedicationType.cream:
      return 'Crema';
    case MedicationType.other:
      return 'Otro';
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day/$month/$year';
}
