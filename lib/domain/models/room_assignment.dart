import 'patient.dart';
import 'bed.dart';

class RoomAssignment {
  final String assignmentID;
  Patient patient;
  Bed bed;
  DateTime startDate;
  DateTime? endDate;
  bool active;

  RoomAssignment({
    required this.assignmentID,
    required this.patient,
    required this.bed,
    required this.startDate,
    this.endDate,
    this.active = true,
  });

  void endAssignment(DateTime end) {
    endDate = end;
    active = false;
  }

  void transferToBed(Bed newBed) {
    bed = newBed;
  }

  Map<String, dynamic> toJson() => {
        'assignmentID': assignmentID,
        'patient': patient.toJson(),
        'bed': bed.toJson(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'active': active,
      };

  factory RoomAssignment.fromJson(Map<String, dynamic> json) => RoomAssignment(
        assignmentID: json['assignmentID'],
        patient: Patient.fromJson(json['patient']),
        bed: Bed.fromJson(json['bed']),
        startDate: DateTime.parse(json['startDate']),
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        active: json['active'] ?? true,
      );
}
