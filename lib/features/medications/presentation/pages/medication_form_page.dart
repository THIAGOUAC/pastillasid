import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/medication_entity.dart';
import '../controllers/medication_controller.dart';

class MedicationFormPage extends ConsumerStatefulWidget {
  final String? medicationId;
  final Map<String, dynamic>? initialData;

  const MedicationFormPage({super.key, this.medicationId, this.initialData});

  @override
  ConsumerState<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends ConsumerState<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _doseAmountController = TextEditingController();
  final _treatmentDaysController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _stockPerDoseController = TextEditingController();
  final _minimumStockAlertController = TextEditingController();
  final _instructionsController = TextEditingController();

  MedicationType _selectedType = MedicationType.pill;
  DoseUnit _selectedUnit = DoseUnit.pill;

  final List<TimeOfDay> _selectedTimes = [];

  bool _loadedMedicationData = false;

  bool get _isEditing => widget.medicationId != null;

  bool get _hasInitialData => widget.initialData != null && !_isEditing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_loadedMedicationData && _isEditing) {
      _loadMedicationData();
      _loadedMedicationData = true;
      return;
    }

    if (!_loadedMedicationData && _hasInitialData) {
      _loadInitialDataFromAI();
      _loadedMedicationData = true;
      return;
    }
  }

  void _loadMedicationData() {
    final medications = ref.read(medicationListProvider);

    final medication = medications
        .where((item) => item.id == widget.medicationId)
        .firstOrNull;

    if (medication == null) return;

    _nameController.text = medication.name;
    _doseAmountController.text = _formatNumber(medication.doseAmount);
    _treatmentDaysController.text = medication.treatmentDays?.toString() ?? '';
    _currentStockController.text = _formatNumber(medication.currentStock);
    _stockPerDoseController.text = _formatNumber(medication.stockPerDose);
    _minimumStockAlertController.text = _formatNumber(
      medication.minimumStockAlert,
    );
    _instructionsController.text = medication.instructions ?? '';

    _selectedType = medication.type;
    _selectedUnit = medication.doseUnit;

    _selectedTimes
      ..clear()
      ..addAll(
        medication.times.map(_timeOfDayFromString).whereType<TimeOfDay>(),
      );
  }

  void _loadInitialDataFromAI() {
    final data = widget.initialData;

    if (data == null) return;

    final name = _readString(data, 'nombre_medicamento');
    final type = _readString(data, 'tipo');
    final doseAmount = _readDynamicAsString(data, 'dosis_cantidad');
    final doseUnit = _readString(data, 'dosis_unidad');
    final duration = _readDynamicAsString(data, 'duracion_tratamiento');
    final instructions = _readString(data, 'indicaciones');
    final warnings = _readString(data, 'advertencias');

    if (name != null && name.trim().isNotEmpty) {
      _nameController.text = name.trim();
    }

    if (doseAmount != null && doseAmount.trim().isNotEmpty) {
      final extractedNumber = _extractNumber(doseAmount);
      if (extractedNumber != null) {
        _doseAmountController.text = _formatNumber(extractedNumber);
      }
    }

    final extractedDays = _extractInteger(duration);
    if (extractedDays != null && extractedDays > 0) {
      _treatmentDaysController.text = extractedDays.toString();
    }

    _selectedType = _medicationTypeFromAI(type);
    _selectedUnit = _doseUnitFromAI(doseUnit);

    final horarios = data['horarios_sugeridos'];
    if (horarios is List) {
      _selectedTimes
        ..clear()
        ..addAll(
          horarios
              .whereType<String>()
              .map(_timeOfDayFromString)
              .whereType<TimeOfDay>(),
        );
    }

    final notes = [
      if (instructions != null && instructions.trim().isNotEmpty)
        instructions.trim(),
      if (warnings != null && warnings.trim().isNotEmpty)
        'Advertencia: ${warnings.trim()}',
    ];

    if (notes.isNotEmpty) {
      _instructionsController.text = notes.join('\n');
    }

    final stockActual = _readDynamicAsString(data, 'stock_actual');
    final stockNum = _extractNumber(stockActual ?? '');
    _currentStockController.text = stockNum != null
        ? _formatNumber(stockNum)
        : '1';
    _stockPerDoseController.text = _doseAmountController.text.trim().isEmpty
        ? '1'
        : _doseAmountController.text.trim();
    _minimumStockAlertController.text = '1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseAmountController.dispose();
    _treatmentDaysController.dispose();
    _currentStockController.dispose();
    _stockPerDoseController.dispose();
    _minimumStockAlertController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Selecciona la hora de toma',
      cancelText: 'Cancelar',
      confirmText: 'Agregar',
    );

    if (selectedTime == null) return;

    final alreadyExists = _selectedTimes.any(
      (time) =>
          time.hour == selectedTime.hour && time.minute == selectedTime.minute,
    );

    if (alreadyExists) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese horario ya fue agregado')),
      );
      return;
    }

    setState(() {
      _selectedTimes.add(selectedTime);
      _selectedTimes.sort((a, b) {
        final aMinutes = a.hour * 60 + a.minute;
        final bMinutes = b.hour * 60 + b.minute;
        return aMinutes.compareTo(bMinutes);
      });
    });
  }

  void _removeTime(TimeOfDay timeToRemove) {
    setState(() {
      _selectedTimes.removeWhere(
        (time) =>
            time.hour == timeToRemove.hour &&
            time.minute == timeToRemove.minute,
      );
    });
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un horario de toma')),
      );
      return;
    }

    final times = _selectedTimes.map(_formatTimeForStorage).toList();
    final treatmentDays = int.tryParse(_treatmentDaysController.text.trim());

    final medications = ref.read(medicationListProvider);

    final existingMedication = _isEditing
        ? medications
              .where((item) => item.id == widget.medicationId)
              .firstOrNull
        : null;

    final medication = MedicationEntity(
      id:
          existingMedication?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _selectedType,
      doseAmount: double.parse(_doseAmountController.text.trim()),
      doseUnit: _selectedUnit,
      times: times,
      startDate: existingMedication?.startDate ?? DateTime.now(),
      endDate: existingMedication?.endDate,
      treatmentDays: treatmentDays,
      currentStock: double.parse(_currentStockController.text.trim()),
      stockPerDose: double.parse(_stockPerDoseController.text.trim()),
      minimumStockAlert: double.parse(_minimumStockAlertController.text.trim()),
      instructions: _instructionsController.text.trim().isEmpty
          ? null
          : _instructionsController.text.trim(),
      isActive: existingMedication?.isActive ?? true,
    );

    if (_isEditing) {
      await ref
          .read(medicationListProvider.notifier)
          .updateMedication(medication);
    } else {
      await ref.read(medicationListProvider.notifier).addMedication(medication);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Medicamento actualizado' : 'Medicamento registrado',
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Editar medicamento' : 'Agregar medicamento';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _isEditing
                    ? 'Modifica los datos del medicamento'
                    : _hasInitialData
                    ? 'Revisa los datos extraídos por IA'
                    : 'Datos del medicamento',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (_hasInitialData) ...[
                const SizedBox(height: 8),
                Text(
                  'La IA puede equivocarse. Revisa y completa los datos antes de guardar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del medicamento',
                  hintText: 'Ejemplo: Paracetamol',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del medicamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const _SectionLabel(title: 'Tipo de medicamento'),
              _MedicationTypeSelector(
                selectedType: _selectedType,
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doseAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad por toma',
                  hintText: 'Ejemplo: 1',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              const _SectionLabel(title: 'Unidad de dosis'),
              _DoseUnitSelector(
                selectedUnit: _selectedUnit,
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Horarios de toma',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega una o más horas al día en las que se debe tomar el medicamento.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add_alarm),
                label: const Text('Agregar horario'),
              ),
              const SizedBox(height: 12),
              if (_selectedTimes.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Todavía no agregaste horarios.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedTimes.map((time) {
                    return InputChip(
                      label: Text(_formatTimeForStorage(time)),
                      avatar: const Icon(Icons.schedule),
                      onDeleted: () => _removeTime(time),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _treatmentDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración del tratamiento en días',
                  hintText: 'Ejemplo: 7',
                  prefixIcon: Icon(Icons.date_range),
                ),
                validator: _requiredInteger,
              ),
              const SizedBox(height: 20),
              Text(
                'Stock y reabastecimiento',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad disponible',
                  hintText: 'Ejemplo: 20',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockPerDoseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad usada por toma',
                  hintText: 'Ejemplo: 1',
                  prefixIcon: Icon(Icons.remove_circle_outline),
                ),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimumStockAlertController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Alerta cuando queden',
                  hintText: 'Ejemplo: 5',
                  prefixIcon: Icon(Icons.warning_amber),
                ),
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Indicaciones opcionales',
                  hintText: 'Ejemplo: tomar después de comer',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveMedication,
                icon: const Icon(Icons.save),
                label: Text(
                  _isEditing ? 'Guardar cambios' : 'Guardar medicamento',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }

    final number = double.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Ingresa un número válido';
    }

    return null;
  }

  String? _requiredInteger(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }

    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) {
      return 'Ingresa un número válido';
    }

    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _MedicationTypeSelector extends StatelessWidget {
  final MedicationType selectedType;
  final ValueChanged<MedicationType> onChanged;

  const _MedicationTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = MedicationType.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((type) {
        final selected = selectedType == type;

        return ChoiceChip(
          label: Text(_medicationTypeLabel(type)),
          selected: selected,
          onSelected: (_) => onChanged(type),
        );
      }).toList(),
    );
  }
}

class _DoseUnitSelector extends StatelessWidget {
  final DoseUnit selectedUnit;
  final ValueChanged<DoseUnit> onChanged;

  const _DoseUnitSelector({
    required this.selectedUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = DoseUnit.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((unit) {
        final selected = selectedUnit == unit;

        return ChoiceChip(
          label: Text(_doseUnitLabel(unit)),
          selected: selected,
          onSelected: (_) => onChanged(unit),
        );
      }).toList(),
    );
  }
}

String? _readString(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String? _readDynamicAsString(Map<String, dynamic> data, String key) {
  final value = data[key];

  if (value == null) return null;
  return value.toString();
}

double? _extractNumber(String? value) {
  if (value == null) return null;

  final match = RegExp(r'(\d+([.,]\d+)?)').firstMatch(value);

  if (match == null) return null;

  final text = match.group(0)?.replaceAll(',', '.');

  if (text == null) return null;

  return double.tryParse(text);
}

int? _extractInteger(String? value) {
  if (value == null) return null;

  final match = RegExp(r'(\d+)').firstMatch(value);

  if (match == null) return null;

  final text = match.group(0);

  if (text == null) return null;

  return int.tryParse(text);
}

MedicationType _medicationTypeFromAI(String? value) {
  final text = value?.toLowerCase().trim();

  switch (text) {
    case 'pastilla':
    case 'tableta':
    case 'comprimido':
      return MedicationType.pill;
    case 'capsula':
    case 'cápsula':
      return MedicationType.capsule;
    case 'jarabe':
    case 'suspension':
    case 'suspensión':
      return MedicationType.syrup;
    case 'gotas':
      return MedicationType.drops;
    case 'inyeccion':
    case 'inyección':
      return MedicationType.injection;
    case 'crema':
      return MedicationType.cream;
    default:
      return MedicationType.other;
  }
}

DoseUnit _doseUnitFromAI(String? value) {
  final text = value?.toLowerCase().trim();

  switch (text) {
    case 'pildora':
    case 'píldora':
    case 'pastilla':
    case 'tableta':
    case 'comprimido':
      return DoseUnit.pill;
    case 'capsula':
    case 'cápsula':
      return DoseUnit.capsule;
    case 'ml':
    case 'mililitro':
    case 'mililitros':
      return DoseUnit.ml;
    case 'cucharada':
      return DoseUnit.tablespoon;
    case 'cucharadita':
      return DoseUnit.teaspoon;
    case 'gotas':
      return DoseUnit.drops;
    case 'inyeccion':
    case 'inyección':
      return DoseUnit.injection;
    case 'aplicacion':
    case 'aplicación':
    case 'inhalacion':
    case 'inhalación':
      return DoseUnit.application;
    default:
      return DoseUnit.other;
  }
}

String _formatTimeForStorage(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? _timeOfDayFromString(String value) {
  final parts = value.split(':');

  if (parts.length != 2) return null;

  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);

  if (hour == null || minute == null) return null;

  return TimeOfDay(hour: hour, minute: minute);
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
      return 'Píldora';
    case DoseUnit.capsule:
      return 'Cápsula';
    case DoseUnit.ml:
      return 'ml';
    case DoseUnit.tablespoon:
      return 'Cucharada';
    case DoseUnit.teaspoon:
      return 'Cucharadita';
    case DoseUnit.drops:
      return 'Gotas';
    case DoseUnit.injection:
      return 'Inyección';
    case DoseUnit.application:
      return 'Aplicación';
    case DoseUnit.other:
      return 'Otro';
  }
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(2);
}
