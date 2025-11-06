import '../models/department.dart';
import '../models/room.dart';
import '../models/bed.dart';
import '../models/patient.dart';
import '../models/staff.dart';
import '../models/room_assignment.dart';
import '../models/maintenance_record.dart';
import '../models/enums.dart';
import '../../data/json_repository.dart';
import '../../data/history_repository.dart';

class RoomManagementService {
  final JsonRepository _repo;
  final HistoryRepository _historyRepo;
  final List<Department> _departments = [];
  final List<RoomAssignment> _assignments = [];
  final List<MaintenanceRecord> _maintenance = [];

  RoomManagementService(this._repo, this._historyRepo);

  Future<void> load() async {
    _departments
      ..clear()
      ..addAll(await _repo.loadDepartments());
  }

  Future<void> save() async {
    await _repo.saveDepartments(_departments);
  }

  void addDepartment(Department dept) {
    if (_departments.any((d) => d.departmentID == dept.departmentID)) return;
    _departments.add(dept);
  }

  void addRoom(Room room, {required String departmentID}) {
    final dept = _departments.firstWhere(
      (d) => d.departmentID == departmentID,
      orElse: () => throw StateError('Department not found'),
    );
    dept.addRoom(room);
  }

  void addStaff(Staff staff, {String? departmentID}) {
    if (departmentID == null) return;
    final dept = _departments.firstWhere(
      (d) => d.departmentID == departmentID,
      orElse: () => throw StateError('Department not found'),
    );
    dept.addStaff(staff);
  }

  void assignStaffToRoom(Staff staff, Room room) {
    room.assignStaff(staff);
  }

  bool removeDepartment(String departmentID) {
    final index = _departments.indexWhere(
      (dept) => dept.departmentID == departmentID,
    );
    if (index == -1) return false;
    final dept = _departments[index];
    if (dept.rooms.isNotEmpty || dept.staff.isNotEmpty) {
      throw StateError('Department still has rooms or staff assigned');
    }
    _departments.removeAt(index);
    return true;
  }

  bool removeRoom(String roomID) {
    for (final dept in _departments) {
      final index = dept.rooms.indexWhere((room) => room.roomID == roomID);
      if (index == -1) continue;
      final room = dept.rooms[index];
      final hasOccupiedBed =
          room.beds.any((bed) => bed.status == BedStatus.occupied);
      if (hasOccupiedBed) {
        throw StateError('Room still has occupied beds');
      }
      dept.rooms.removeAt(index);
      final roomBedIds = room.beds.map((bed) => bed.bedID).toSet();
      _assignments.removeWhere(
        (assignment) => roomBedIds.contains(assignment.bed.bedID),
      );
      _maintenance.removeWhere((m) => m.room.roomID == room.roomID);
      return true;
    }
    return false;
  }

  bool removeStaff(String staffID) {
    for (final dept in _departments) {
      final index = dept.staff.indexWhere((staff) => staff.staffID == staffID);
      if (index == -1) continue;
      final staff = dept.staff[index];
      for (final room in dept.rooms) {
        room.assignedStaff
            .removeWhere((assigned) => assigned.staffID == staff.staffID);
      }
      dept.staff.removeAt(index);
      return true;
    }
    return false;
  }

  bool updateDepartment(
    String departmentID, {
    String? name,
    String? description,
  }) {
    for (final dept in _departments) {
      if (dept.departmentID != departmentID) continue;
      var updated = false;
      if (name != null) {
        dept.name = name;
        updated = true;
      }
      if (description != null) {
        dept.description = description;
        updated = true;
      }
      return updated;
    }
    return false;
  }

  bool updateRoom(
    String roomID, {
    String? roomNumber,
    String? floorLevel,
    RoomType? type,
    int? capacity,
  }) {
    for (final dept in _departments) {
      for (final room in dept.rooms) {
        if (room.roomID != roomID) continue;
        var updated = false;
        if (roomNumber != null) {
          room.roomNumber = roomNumber;
          updated = true;
        }
        if (floorLevel != null) {
          room.floorLevel = floorLevel;
          updated = true;
        }
        if (type != null) {
          room.type = type;
          updated = true;
        }
        if (capacity != null && capacity != room.capacity) {
          if (capacity < 0) {
            throw StateError('Capacity must be zero or greater');
          }
          final currentBeds = room.beds.length;
          if (capacity < currentBeds) {
            final bedsToRemove = currentBeds - capacity;
            if (bedsToRemove > 0) {
              final removableBeds = room.beds.reversed
                  .where((bed) => bed.status != BedStatus.occupied)
                  .take(bedsToRemove)
                  .toList();
              if (removableBeds.length < bedsToRemove) {
                throw StateError('Cannot reduce capacity while beds are occupied');
              }
              for (final bed in removableBeds) {
                room.beds.remove(bed);
                _assignments
                    .removeWhere((assignment) => assignment.bed.bedID == bed.bedID);
              }
            }
            room.capacity = capacity;
            updated = true;
          } else if (capacity > currentBeds) {
            final bedsToAdd = capacity - currentBeds;
            final startIndex = currentBeds;
            final timestamp = DateTime.now().microsecondsSinceEpoch;
            for (var i = 0; i < bedsToAdd; i++) {
              final bed = Bed(
                bedID: 'B$timestamp-$i',
                bedNumber: '${startIndex + i + 1}',
              );
              room.beds.add(bed);
            }
            room.capacity = capacity;
            updated = true;
          } else {
            room.capacity = capacity;
            updated = true;
          }
        }
        return updated;
      }
    }
    return false;
  }

  bool updateStaff(
    String staffID, {
    String? name,
    StaffRole? role,
    String? phoneNumber,
  }) {
    for (final dept in _departments) {
      for (final staff in dept.staff) {
        if (staff.staffID != staffID) continue;
        var updated = false;
        if (name != null) {
          staff.name = name;
          updated = true;
        }
        if (role != null) {
          staff.role = role;
          updated = true;
        }
        if (phoneNumber != null) {
          staff.phoneNumber = phoneNumber;
          updated = true;
        }
        return updated;
      }
    }
    return false;
  }

  Future<RoomAssignment> assignPatientToBed(
      Patient patient, Bed bed, DateTime start) async {
    if (bed.status != BedStatus.available) {
      throw StateError('Bed not available');
    }

    bed.assignPatient(patient, start);
    final ra = RoomAssignment(
      assignmentID: 'A-${DateTime.now().millisecondsSinceEpoch}',
      patient: patient,
      bed: bed,
      startDate: start,
      active: true,
    );
    _assignments.add(ra);

    await _recordAdmission(patient, bed, start);
    return ra;
  }

  Future<void> releaseBed(Bed bed, DateTime end) async {
    final patient = bed.currentPatient;
    final active =
        _assignments.where((a) => a.bed.bedID == bed.bedID && a.active);

    bed.release(end);
    for (final a in active) {
      a.endAssignment(end);
    }

    if (patient != null) {
      await _recordRelease(patient, bed, end);
    }
  }

  Future<void> _recordAdmission(
      Patient patient, Bed bed, DateTime admissionDate) async {
    final room = _findRoomByBed(bed);
    final dept = _findDepartmentByBed(bed);
    if (room == null || dept == null) return;

    final historyRecord = {
      'historyId': 'H-${DateTime.now().millisecondsSinceEpoch}',
      'patientId': patient.patientID,
      'patientName': patient.getFullName(),
      'roomNumber': room.roomNumber,
      'bedNumber': bed.bedNumber,
      'departmentName': dept.name,
      'admissionDate': admissionDate.toIso8601String(),
      'releaseDate': '',
      'assignedStaffId':
          room.assignedStaff.isNotEmpty ? room.assignedStaff.first.staffID : '',
      'notes': 'Admitted to ${dept.name} department',
      'status': 'ACTIVE'
    };

    await _historyRepo.addHistoryRecord(historyRecord);
  }

  Future<void> _recordRelease(
    Patient patient, Bed bed, DateTime releaseDate) async {
    final history = await _historyRepo.loadHistory();
    final activeRecord = history.firstWhere(
      (record) =>
          record['patientId'] == patient.patientID &&
          record['status'] == 'ACTIVE',
      orElse: () => <String, dynamic>{},
    );

    if (activeRecord.isNotEmpty) {
      activeRecord['releaseDate'] = releaseDate.toIso8601String();
      activeRecord['status'] = 'COMPLETED';
      await _historyRepo.saveHistory(history);
    }
  }

  void markRoomUnderMaintenance(Room room, String reason, Staff? by) {
    room.status = RoomStatus.maintenance;
    for (final bed in room.beds) {
      if (bed.status != BedStatus.occupied) {
        bed.status = BedStatus.closed;
      }
    }

    final now = DateTime.now();
    room.maintenanceReason = reason;
    room.maintenanceStaffId = by?.staffID;
    room.maintenanceLoggedAt = now;

    _maintenance.add(MaintenanceRecord(
      recordID: 'M-${now.millisecondsSinceEpoch}',
      room: room,
      staff: by,
      reason: reason,
      date: now,
    ));
  }

  void markRoomClean(Room room, DateTime date) {
    room.status = RoomStatus.cleaning;
    for (final bed in room.beds) {
      if (bed.status != BedStatus.occupied) {
        bed.status = BedStatus.cleaning;
      }
    }
  }

  void markRoomClosed(Room room) {
    room.status = RoomStatus.closed;
    for (final bed in room.beds) {
      if (bed.status != BedStatus.occupied) {
        bed.status = BedStatus.closed;
      }
    }
  }

  void markRoomAvailable(Room room) {
    room.status = RoomStatus.available;
    for (final bed in room.beds) {
      if (bed.status == BedStatus.cleaning || bed.status == BedStatus.closed) {
        bed.status = BedStatus.available;
      }
    }
    _maintenance.removeWhere((m) => m.room.roomID == room.roomID);
    room.maintenanceReason = null;
    room.maintenanceStaffId = null;
    room.maintenanceLoggedAt = null;
  }

  List<Room> getAvailableRooms() => _departments
      .expand((d) => d.rooms)
      .where((r) => r.isAvailable())
      .toList();

  List<Bed> getOccupiedBeds() => _departments
      .expand((d) => d.rooms)
      .expand((r) => r.beds)
      .where((b) => b.status == BedStatus.occupied)
      .toList();

  Department? _findDepartmentByBed(Bed bed) {
    for (final dept in _departments) {
      for (final room in dept.rooms) {
        if (room.beds.any((b) => b.bedID == bed.bedID)) {
          return dept;
        }
      }
    }
    return null;
  }

  Room? _findRoomByBed(Bed bed) {
    for (final dept in _departments) {
      for (final room in dept.rooms) {
        if (room.beds.any((b) => b.bedID == bed.bedID)) {
          return room;
        }
      }
    }
    return null;
  }

  List<Department> get departments => List.unmodifiable(_departments);
  List<RoomAssignment> get assignments => List.unmodifiable(_assignments);
  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);
}
