import 'package:equatable/equatable.dart';

enum IntakeStatus {
  taken,
  skipped,
}

class IntakeRecordEntity extends Equatable {
  final String id;
  final String medicationId;
  final String medicationName;
  final String doseText;
  final DateTime takenAt;
  final IntakeStatus status;

  const IntakeRecordEntity({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.doseText,
    required this.takenAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicationId': medicationId,
      'medicationName': medicationName,
      'doseText': doseText,
      'takenAt': takenAt.toIso8601String(),
      'status': status.name,
    };
  }

  factory IntakeRecordEntity.fromMap(Map<String, dynamic> map) {
    return IntakeRecordEntity(
      id: map['id'] as String? ?? '',
      medicationId: map['medicationId'] as String? ?? '',
      medicationName: map['medicationName'] as String? ?? '',
      doseText: map['doseText'] as String? ?? '',
      takenAt: _dateFromString(map['takenAt']) ?? DateTime.now(),
      status: _statusFromString(map['status'] as String?),
    );
  }

  @override
  List<Object?> get props => [
        id,
        medicationId,
        medicationName,
        doseText,
        takenAt,
        status,
      ];
}

IntakeStatus _statusFromString(String? value) {
  return IntakeStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => IntakeStatus.taken,
  );
}

DateTime? _dateFromString(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}