import 'package:equatable/equatable.dart';

enum MedicationType { pill, capsule, syrup, drops, injection, cream, other }

enum DoseUnit {
  pill,
  capsule,
  ml,
  tablespoon,
  teaspoon,
  drops,
  injection,
  application,
  other,
}

class MedicationEntity extends Equatable {
  final String id;
  final String name;
  final MedicationType type;
  final double doseAmount;
  final DoseUnit doseUnit;
  final List<String> times;
  final DateTime startDate;
  final DateTime? endDate;
  final int? treatmentDays;
  final double currentStock;
  final double stockPerDose;
  final double minimumStockAlert;
  final String? instructions;
  final bool isActive;

  const MedicationEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.doseAmount,
    required this.doseUnit,
    required this.times,
    required this.startDate,
    this.endDate,
    this.treatmentDays,
    required this.currentStock,
    required this.stockPerDose,
    required this.minimumStockAlert,
    this.instructions,
    this.isActive = true,
  });

  bool get hasLowStock => currentStock <= minimumStockAlert;

  bool get hasSchedule => times.isNotEmpty;

  bool get hasTreatmentEnd => endDate != null || treatmentDays != null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'doseAmount': doseAmount,
      'doseUnit': doseUnit.name,
      'times': times,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'treatmentDays': treatmentDays,
      'currentStock': currentStock,
      'stockPerDose': stockPerDose,
      'minimumStockAlert': minimumStockAlert,
      'instructions': instructions,
      'isActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory MedicationEntity.fromMap(Map<String, dynamic> map) {
    return MedicationEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: _medicationTypeFromString(map['type'] as String?),
      doseAmount: _toDouble(map['doseAmount']),
      doseUnit: _doseUnitFromString(map['doseUnit'] as String?),
      times: List<String>.from(map['times'] as List? ?? const []),
      startDate: _dateFromString(map['startDate']) ?? DateTime.now(),
      endDate: _dateFromString(map['endDate']),
      treatmentDays: _toInt(map['treatmentDays']),
      currentStock: _toDouble(map['currentStock']),
      stockPerDose: _toDouble(map['stockPerDose']),
      minimumStockAlert: _toDouble(map['minimumStockAlert']),
      instructions: map['instructions'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  MedicationEntity copyWith({
    String? id,
    String? name,
    MedicationType? type,
    double? doseAmount,
    DoseUnit? doseUnit,
    List<String>? times,
    DateTime? startDate,
    DateTime? endDate,
    int? treatmentDays,
    double? currentStock,
    double? stockPerDose,
    double? minimumStockAlert,
    String? instructions,
    bool? isActive,
  }) {
    return MedicationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      times: times ?? this.times,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      treatmentDays: treatmentDays ?? this.treatmentDays,
      currentStock: currentStock ?? this.currentStock,
      stockPerDose: stockPerDose ?? this.stockPerDose,
      minimumStockAlert: minimumStockAlert ?? this.minimumStockAlert,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    doseAmount,
    doseUnit,
    times,
    startDate,
    endDate,
    treatmentDays,
    currentStock,
    stockPerDose,
    minimumStockAlert,
    instructions,
    isActive,
  ];
}

MedicationType _medicationTypeFromString(String? value) {
  return MedicationType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => MedicationType.other,
  );
}

DoseUnit _doseUnitFromString(String? value) {
  return DoseUnit.values.firstWhere(
    (unit) => unit.name == value,
    orElse: () => DoseUnit.other,
  );
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _dateFromString(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
