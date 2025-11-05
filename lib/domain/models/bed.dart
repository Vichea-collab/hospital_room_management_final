import 'patient.dart';
import 'enums.dart';

class Bed {
  final String bedID;
  String bedNumber;
  BedStatus status;
  Patient? currentPatient;
  DateTime? enterDate;
  DateTime? outDate;

  Bed({
    required this.bedID,
    required this.bedNumber,
    this.status = BedStatus.available,
    this.currentPatient,
    this.enterDate,
    this.outDate,
  });

  void assignPatient(Patient patient, DateTime start) {
    currentPatient = patient;
    status = BedStatus.occupied;
    enterDate = start;
    outDate = null;
  }

  void release(DateTime end) {
    status = BedStatus.available;
    outDate = end;
    currentPatient = null;
  }

  bool isOccupied() => status == BedStatus.occupied;

  Map<String, dynamic> toJson() => {
        'bedID': bedID,
        'bedNumber': bedNumber,
        'status': status.name,
        'currentPatient': currentPatient?.toJson(),
        'enterDate': enterDate?.toIso8601String(),
        'outDate': outDate?.toIso8601String(),
      };

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
        bedID: json['bedID'],
        bedNumber: json['bedNumber'],
        status: bedStatusFrom(json['status'] ?? 'available'),
        currentPatient: json['currentPatient'] == null
            ? null
            : Patient.fromJson(json['currentPatient']),
        enterDate:
            json['enterDate'] != null ? DateTime.parse(json['enterDate']) : null,
        outDate:
            json['outDate'] != null ? DateTime.parse(json['outDate']) : null,
      );
}
