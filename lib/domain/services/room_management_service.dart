// AI generated
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
    final dept = _departments.firstWhere((d) => d.departmentID == departmentID,
        orElse: () => throw StateError('Department not found'));
    dept.addRoom(room);
  }

  void addStaff(Staff staff, {String? departmentID}) {
    if (departmentID == null) return;
    final dept = _departments.firstWhere((d) => d.departmentID == departmentID,
        orElse: () => throw StateError('Department not found'));
    dept.addStaff(staff);
  }

  void assignStaffToRoom(Staff staff, Room room) {
    room.assignStaff(staff);
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

    // Record admission in history
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

    // Record release in history if there was a patient
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

  void markRoomUnderMaintenance(Room room, String reason, Staff? by) {
    room.status = RoomStatus.maintenance;
    if (by != null) {
      _maintenance.add(MaintenanceRecord(
        recordID: 'M-${DateTime.now().millisecondsSinceEpoch}',
        room: room,
        staff: by,
        reason: reason,
        date: DateTime.now(),
      ));
    }
  }

  void markRoomCleaned(Room room, DateTime date) {
    room.status = RoomStatus.cleaning;
    room.markCleaned();
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

  List<Department> get departments => List.unmodifiable(_departments);
  List<RoomAssignment> get assignments => List.unmodifiable(_assignments);
  List<MaintenanceRecord> get maintenance => List.unmodifiable(_maintenance);
}
