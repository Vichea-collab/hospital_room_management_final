import 'enums.dart';
import 'bed.dart';
import 'staff.dart';
import 'department.dart';

class Room {
  final String roomID;
  String roomNumber;
  String floorLevel;
  RoomType type;
  RoomStatus status;
  int capacity;
  final List<Bed> beds;
  final List<Staff> assignedStaff;
  Department? _department;

  Room({
    required this.roomID,
    required this.roomNumber,
    required this.floorLevel,
    required this.type,
    required this.status,
    required this.capacity,
    List<Bed>? beds,
    List<Staff>? assignedStaff,
    Department? department,
  })  : beds = beds ?? [],
        assignedStaff = assignedStaff ?? [],
        _department = department;

  bool isAvailable() =>
      status == RoomStatus.available &&
      beds.any((b) => b.status == BedStatus.available);

  List<Bed> getAvailableBeds() =>
      beds.where((b) => b.status == BedStatus.available).toList();

  void assignStaff(Staff staff) {
    if (!assignedStaff.any((s) => s.staffID == staff.staffID)) {
      assignedStaff.add(staff);
    }
  }

  void markCleaned() {
    status = RoomStatus.available;
  }

  Department? getDepartment() => _department;
  void setDepartment(Department dept) => _department = dept;

  Map<String, dynamic> toJson() => {
        'roomID': roomID,
        'roomNumber': roomNumber,
        'floorLevel': floorLevel,
        'type': type.name,
        'status': status.name,
        'capacity': capacity,
        'beds': beds.map((b) => b.toJson()).toList(),
        'assignedStaff': assignedStaff.map((s) => s.toJson()).toList(),
        'departmentID': _department?.departmentID,
      };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        roomID: json['roomID'],
        roomNumber: json['roomNumber'],
        floorLevel: json['floorLevel'],
        type: roomTypeFrom(json['type']),
        status: roomStatusFrom(json['status']),
        capacity: (json['capacity'] ?? 0) as int,
        beds: (json['beds'] as List? ?? []).map((e) => Bed.fromJson(e)).toList(),
        assignedStaff: (json['assignedStaff'] as List? ?? [])
            .map((e) => Staff.fromJson(e))
            .toList(),
      );
}
