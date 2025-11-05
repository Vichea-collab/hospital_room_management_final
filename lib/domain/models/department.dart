import 'room.dart';
import 'staff.dart';

class Department {
  final String departmentID;
  String name;
  String description;
  final List<Room> rooms;
  final List<Staff> staff;

  Department({
    required this.departmentID,
    required this.name,
    required this.description,
    List<Room>? rooms,
    List<Staff>? staff,
  })  : rooms = rooms ?? [],
        staff = staff ?? [];

  void addRoom(Room room) {
    if (!rooms.any((r) => r.roomID == room.roomID)) {
      rooms.add(room);
      room.setDepartment(this);
    }
  }

  void addStaff(Staff s) {
    if (!staff.any((x) => x.staffID == s.staffID)) {
      staff.add(s);
    }
  }

  List<Room> getRooms() => List.unmodifiable(rooms);
  List<Staff> getStaff() => List.unmodifiable(staff);

  Map<String, dynamic> toJson() => {
        'departmentID': departmentID,
        'name': name,
        'description': description,
        'rooms': rooms.map((r) => r.toJson()).toList(),
        'staff': staff.map((s) => s.toJson()).toList(),
      };

  factory Department.fromJson(Map<String, dynamic> json) {
    final dept = Department(
      departmentID: json['departmentID'],
      name: json['name'],
      description: json['description'],
      rooms: [],
      staff: (json['staff'] as List? ?? []).map((e) => Staff.fromJson(e)).toList(),
    );
    final roomList = (json['rooms'] as List? ?? [])
        .map((e) => Room.fromJson(e))
        .toList();
    for (final r in roomList) {
      dept.addRoom(r);
    }
    return dept;
  }
}
