import 'dart:io';
import 'package:hospital_room_management/ui/cli_utils.dart' as ui;
import '../data/history_repository.dart';

import '../domain/services/room_management_service.dart';
import '../domain/models/department.dart';
import '../domain/models/room.dart';
import '../domain/models/bed.dart';
import '../domain/models/staff.dart';
import '../domain/models/patient.dart';
import '../domain/models/enums.dart';

class MainMenu {
  final RoomManagementService service;
  final HistoryRepository historyRepo;

  MainMenu(this.service, this.historyRepo);

  Future<void> start() async {
    while (true) {
      ui.clearScreen();
      _banner();
      stdout.writeln('[1] Insert');
      stdout.writeln('[2] Assignment');
      stdout.writeln('[3] Release Bed');
      stdout.writeln('[4] Mark Room');
      stdout.writeln('[5] View');
      stdout.writeln('[6] View JSON Data');
      stdout.writeln('[7] History');
      stdout.writeln('[0] Exit');
      stdout.writeln('------------------------------------------');
      final choice = _askInt('Choose an option');
      switch (choice) {
        case 1:
          await _menuInsert();
          break;
        case 2:
          await _menuAssignment();
          break;
        case 3:
          await _releaseBed();
          break;
        case 4:
          await _menuMaintenance();
          break;
        case 5:
          await _menuView();
          break;
        case 6:
          await _viewJsonData();
          break;
        case 7:
          await _viewHistory();
          break;
        case 0:
          stdout.writeln(ui.green('Goodbye!'));
          return;
        default:
          _error('Invalid option');
          _pause();
          break;
      }
    }
  }

  Future<void> _menuInsert() async {
    while (true) {
      ui.clearScreen();
      _section('Insert');
      stdout.writeln('[1] Add Department');
      stdout.writeln('[2] Add Room');
      stdout.writeln('[3] Add Staff');
      stdout.writeln('[0] Back');
      final c = _askInt('Choose');
      switch (c) {
        case 1:
          await _addDepartment();
          break;
        case 2:
          await _addRoom();
          break;
        case 3:
          await _addStaff();
          break;
        case 0:
          return;
        default:
          _error('Invalid option');
          _pause();
      }
    }
  }

  Future<void> _menuAssignment() async {
    while (true) {
      ui.clearScreen();
      _section('Assignment');
      stdout.writeln('[1] Assign Staff to Room');
      stdout.writeln('[2] Assign Patient to Bed');
      stdout.writeln('[0] Back');
      final c = _askInt('Choose');
      switch (c) {
        case 1:
          await _assignStaffToRoom();
          break;
        case 2:
          await _assignPatientToBed();
          break;
        case 0:
          return;
        default:
          _error('Invalid option');
          _pause();
      }
    }
  }

  Future<void> _menuMaintenance() async {
    while (true) {
      ui.clearScreen();
      _section('Mark Room');
      stdout.writeln('[1] Mark Room Under Maintenance');
      stdout.writeln('[2] Mark Room Cleaned');
      stdout.writeln('[3] Mark Room Closed');
      stdout.writeln('[4] Mark Room Available');
      stdout.writeln('[5] View All Rooms (Color-coded)');
      stdout.writeln('[0] Back');
      final c = _askInt('Choose');
      switch (c) {
        case 1:
          await _markRoomUnderMaintenance();
          break;
        case 2:
          await _markRoomClean();
          break;
        case 3:
          await _markRoomClosed();
          break;
        case 4:
          await _markRoomAvailable();
          break;
        case 5:
          _viewAllRoomsColor();
          _pause();
          break;
        case 0:
          return;
        default:
          _error('Invalid option');
          _pause();
      }
    }
  }

  Future<void> _menuView() async {
    while (true) {
      ui.clearScreen();
      _section('View');
      stdout.writeln('[1] View Available Rooms');
      stdout.writeln('[2] View Occupied Beds');
      stdout.writeln('[3] View All Rooms (color-coded)');
      stdout.writeln('[4] Search Department by ID');
      stdout.writeln('[0] Back');
      final c = _askInt('Choose');
      switch (c) {
        case 1:
          _viewAvailableRooms();
          _pause();
          break;
        case 2:
          _viewOccupiedBeds();
          _pause();
          break;
        case 3:
          _viewAllRoomsColor();
          _pause();
          break;
        case 4:
          _viewDepartmentById();
          _pause();
          break;
        case 0:
          return;
        default:
          _error('Invalid option');
          _pause();
      }
    }
  }

  Future<void> _addDepartment() async {
    _section('Add Department');
    while (true) {
      final id = _askStr('Department ID');
      // Check for duplicate ID
      if (_findDepartmentById(id) != null) {
        _error('Department ID already exists. Please enter a different ID.');
        continue; // ask again
      }
      final name = _askStr('Name');
      final desc = _askStr('Description');
      final dept = Department(departmentID: id, name: name, description: desc);
      service.addDepartment(dept);
      await service.save();
      _ok('Department added successfully.');
      break;
    }
    _pause();
  }

  Future<void> _addRoom() async {
    _section('Add Room');
    final deptId = _askStr('Department ID to attach');
    final dept = _findDepartmentById(deptId);
    if (dept == null) {
      _error('Department not found.');
      _pause();
      return;
    }

    while (true) {
      final roomID = _askStr('Room ID');
      if (_findRoomById(roomID) != null) {
        _error('Room ID already exists. Please enter a different ID.');
        continue;
      }

      final roomNumber = _askStr('Room Number');
      final floorLevel = _askStr('Floor Level');
      final type = _askRoomType();
      final capacity = _askInt('Capacity');
      final beds = List<Bed>.generate(
        capacity,
        (i) => Bed(
          bedID: 'B${DateTime.now().millisecondsSinceEpoch}-$i',
          bedNumber: '${i + 1}',
        ),
      );
      final room = Room(
        roomID: roomID,
        roomNumber: roomNumber,
        floorLevel: floorLevel,
        type: type,
        status: RoomStatus.available,
        capacity: capacity,
        beds: beds,
      );

      try {
        service.addRoom(room, departmentID: deptId);
        await service.save();
        _ok('Room added successfully.');
        break;
      } catch (e) {
        _error('Error adding room: ${e.toString()}');
      }
    }
    _pause();
  }

  Future<void> _addStaff() async {
    _section('Add Staff');
    final deptId = _askStr('Department ID to attach');
    final dept = _findDepartmentById(deptId);
    if (dept == null) {
      _error('Department not found.');
      _pause();
      return;
    }

    while (true) {
      final staffID = _askStr('Staff ID');
      if (_findStaffById(staffID) != null) {
        _error('Staff ID already exists. Please enter a different ID.');
        continue;
      }

      final name = _askStr('Name');
      final role = _askStaffRole();
      final phone = _askStr('Phone Number');
      final staff =
          Staff(staffID: staffID, name: name, role: role, phoneNumber: phone);
      try {
        service.addStaff(staff, departmentID: deptId);
        await service.save();
        _ok('Staff added successfully.');
        break;
      } catch (e) {
        _error('Error adding staff: ${e.toString()}');
      }
    }
    _pause();
  }

  Future<void> _assignStaffToRoom() async {
    _section('Assign Staff to Room');
    final staffID = _askStr('Staff ID');
    final roomID = _askStr('Room ID');
    final staff = _findStaffById(staffID);
    final room = _findRoomById(roomID);
    if (staff == null) {
      _error('Staff not found');
      _pause();
      return;
    }
    if (room == null) {
      _error('Room not found');
      _pause();
      return;
    }
    service.assignStaffToRoom(staff, room);
    await service.save();
    _ok('Staff assigned to room');
    _pause();
  }

  Future<void> _assignPatientToBed() async {
    _section('Assign Patient to Bed');

    // Build list of available beds
    final availableBeds = <Bed>[];
    for (final d in service.departments) {
      for (final r in d.rooms) {
        for (final b in r.beds) {
          if (b.status == BedStatus.available) availableBeds.add(b);
        }
      }
    }

    if (availableBeds.isEmpty) {
      _error('No available beds right now.');
      _pause();
      return;
    }

    // Show a short indexed list for quick selection
    stdout.writeln('Available beds:');
    for (var i = 0; i < availableBeds.length; i++) {
      final b = availableBeds[i];
      // try to find room/department for display
      String roomTag = '';
      outer:
      for (final d in service.departments) {
        for (final r in d.rooms) {
          if (r.beds.any((x) => x.bedID == b.bedID)) {
            roomTag = '${r.roomNumber} (Room ${r.roomID}) - Dept ${d.name}';
            break outer;
          }
        }
      }
      stdout.writeln('${i + 1}) ${b.bedNumber}  ${b.bedID}   $roomTag');
    }

    stdout.write(
        'Pick a bed number, or press Enter to auto-assign the first available: ');
    final input = stdin.readLineSync();

    Bed chosenBed;
    if (input == null || input.trim().isEmpty) {
      chosenBed = availableBeds.first;
    } else {
      final idx = int.tryParse(input.trim());
      if (idx == null || idx < 1 || idx > availableBeds.length) {
        _error('Invalid selection. Aborting.');
        _pause();
        return;
      }
      chosenBed = availableBeds[idx - 1];
    }

    final pid = _askStr('Patient ID');
    final first = _askStr('First Name');
    final last = _askStr('Last Name');
    final gender = _askStr('Gender');
    final dob = DateTime.tryParse(_askStr('Date of Birth (YYYY-MM-DD)')) ??
        DateTime(2000, 1, 1);
    final phone = _askStr('Phone Number');
    final patient = Patient(
        patientID: pid,
        firstName: first,
        lastName: last,
        gender: gender,
        dateOfBirth: dob,
        phoneNumber: phone);

    try {
      await service.assignPatientToBed(patient, chosenBed, DateTime.now());
      await service.save();
      _ok('Patient assigned to bed ${chosenBed.bedID}');
    } catch (e) {
      _error(e.toString());
    }
    _pause();
  }

  Future<void> _releaseBed() async {
    _section('Release Bed');

    // Build list of occupied beds
    final occupiedBeds = <Bed>[];
    for (final d in service.departments) {
      for (final r in d.rooms) {
        for (final b in r.beds) {
          if (b.status == BedStatus.occupied) occupiedBeds.add(b);
        }
      }
    }

    if (occupiedBeds.isEmpty) {
      _error('No occupied beds.');
      _pause();
      return;
    }

    // Show indexed list for selection
    stdout.writeln('Occupied beds:');
    for (var i = 0; i < occupiedBeds.length; i++) {
      final b = occupiedBeds[i];
      String roomTag = '';
      outer:
      for (final d in service.departments) {
        for (final r in d.rooms) {
          if (r.beds.any((x) => x.bedID == b.bedID)) {
            roomTag = '${r.roomNumber} (Room ${r.roomID}) - Dept ${d.name}';
            break outer;
          }
        }
      }
      stdout.writeln(
          '${i + 1}) ${b.bedNumber}  ${b.bedID}  ${_stateBadgeBed(b.status)}  Patient: ${b.currentPatient?.getFullName() ?? '-'}  $roomTag');
    }

    final sel = _askInt('Pick bed number to release');
    if (sel < 1 || sel > occupiedBeds.length) {
      _error('Invalid selection');
      _pause();
      return;
    }
    final chosen = occupiedBeds[sel - 1];

    await service.releaseBed(chosen, DateTime.now());
    await service.save();
    _ok('Bed released: ${chosen.bedID}');
    _pause();
  }

  Future<void> _markRoomUnderMaintenance() async {
    _section('Mark Room Under Maintenance');
    final roomID = _askStr('Room ID');
    final reason = _askStr('Reason');
    final staffId =
        _askStr('Staff ID (optional, for record)', allowEmpty: true);
    final room = _findRoomById(roomID);
    if (room == null) {
      _error('Room not found');
      _pause();
      return;
    }
    final staff = (staffId.trim().isEmpty) ? null : _findStaffById(staffId);
    service.markRoomUnderMaintenance(room, reason, staff);
    await service.save();
    _ok('Room set to maintenance');
    _pause();
  }

  Future<void> _markRoomClean() async {
    _section('Mark Room Cleaned');
    final roomID = _askStr('Room ID');
    final room = _findRoomById(roomID);
    if (room == null) {
      _error('Room not found');
      _pause();
      return;
    }

    // Check if room is in a state that can be cleaned
    if (room.status == RoomStatus.occupied) {
      _error('Cannot clean room while it is occupied');
      _pause();
      return;
    }

    // Mark room for cleaning
    service.markRoomClean(room, DateTime.now());
    await service.save();

    stdout.writeln('\nRoom Status Update:');
    stdout.writeln('- Room Status: ${_stateBadgeRoom(room.status)}');
    stdout.writeln(
        '- Beds under cleaning: ${room.beds.where((b) => b.status == BedStatus.cleaning).length}');
    stdout.writeln(
        '- Occupied beds (unchanged): ${room.beds.where((b) => b.status == BedStatus.occupied).length}');
    stdout.writeln(
        '\n${ui.yellow('Note:')} Once cleaning is complete, use "Mark Room Available" to restore service.');

    _ok('Room marked for cleaning');
    _pause();
  }

  Future<void> _markRoomAvailable() async {
    _section('Mark Room Available');
    final roomID = _askStr('Room ID');
    final room = _findRoomById(roomID);
    if (room == null) {
      _error('Room not found');
      _pause();
      return;
    }
    service.markRoomAvailable(room);
    await service.save();
    _ok('Room marked as available');
    _pause();
  }

  Future<void> _markRoomClosed() async {
    _section('Mark Room Closed');
    final roomID = _askStr('Room ID');
    final room = _findRoomById(roomID);
    if (room == null) {
      _error('Room not found');
      _pause();
      return;
    }
    service.markRoomClosed(room);
    await service.save();
    _ok('Room marked as closed');
    _pause();
  }

  void _viewAvailableRooms() {
    _section('Available Rooms');
    final rooms = service.getAvailableRooms();
    if (rooms.isEmpty) {
      stdout.writeln(ui.yellow('No available rooms.'));
      return;
    }
    for (final r in rooms) {
      stdout.writeln(
          '${_roomTag(r)}  ${ui.green('Available beds: ' + r.getAvailableBeds().length.toString())}');
    }
  }

  void _viewOccupiedBeds() {
    _section('Occupied Beds');
    final beds = service.getOccupiedBeds();
    if (beds.isEmpty) {
      stdout.writeln(ui.yellow('No occupied beds.'));
      return;
    }
    for (final b in beds) {
      stdout
          .writeln('Bed ${b.bedID}/${b.bedNumber}  ${_stateBadgeBed(b.status)}'
              '  Patient: ${b.currentPatient?.getFullName() ?? '-'}');
    }
  }

  void _viewAllRoomsColor() {
    _section('All Rooms (color-coded)');
    for (final d in service.departments) {
      stdout.writeln(ui.blue('Department ${d.departmentID} - ${d.name}'));
      for (final r in d.rooms) {
        // If every bed is occupied, mark the room as occupied so the view reflects state
        if (r.beds.isNotEmpty &&
            r.beds.every((b) => b.status == BedStatus.occupied)) {
          r.status = RoomStatus.occupied;
        }
        stdout.writeln('  ${_roomTag(r)}  ${_stateBadgeRoom(r.status)}');
        for (final b in r.beds) {
          stdout.writeln(
              '    └─ Bed ${b.bedID}/${b.bedNumber}  ${_stateBadgeBed(b.status)}');
        }
      }
      stdout.writeln('');
    }
  }

  void _banner() {
    stdout.writeln('==========================================');
    stdout.writeln('   Hospital Room Management System');
    stdout.writeln('==========================================');
  }

  void _section(String title) {
    stdout.writeln('==========================================');
    ui.printHeader(title);
    stdout.writeln('------------------------------------------');
  }

  void _ok(String msg) => stdout.writeln(ui.green(msg));
  void _error(String msg) => stdout.writeln(ui.red(msg));

  void _pause() {
    stdout.writeln('');
    stdout.write(ui.yellow('Press Enter to continue... '));
    stdin.readLineSync();
  }

  int _askInt(String label) {
    final s = _askStr(label);
    final v = int.tryParse(s);
    if (v == null) return -1;
    return v;
  }

  String _askStr(String label, {bool allowEmpty = false}) {
    while (true) {
      stdout.write('$label: ');
      final s = stdin.readLineSync() ?? '';
      if (s.isEmpty && !allowEmpty) {
        _error('Value required');
        continue;
      }
      return s;
    }
  }

  RoomType _askRoomType() {
    stdout.writeln(
        'RoomType: 1) ICU  2) Surgery  3) Maternity  4) Isolation  5) General');
    final v = _askInt('Choose');
    switch (v) {
      case 1:
        return RoomType.icu;
      case 2:
        return RoomType.surgery;
      case 3:
        return RoomType.maternity;
      case 4:
        return RoomType.isolation;
      default:
        return RoomType.general;
    }
  }

  StaffRole _askStaffRole() {
    stdout.writeln(
        'StaffRole: 1) Nurse  2) Doctor  3) Janitor  4) Maintenance  5) Cleaner  6) Technician');
    final v = _askInt('Choose');
    switch (v) {
      case 1:
        return StaffRole.nurse;
      case 2:
        return StaffRole.doctor;
      case 3:
        return StaffRole.janitor;
      case 4:
        return StaffRole.maintenance;
      case 5:
        return StaffRole.cleaner;
      case 6:
        return StaffRole.technician;
      default:
        return StaffRole.nurse;
    }
  }

  Department? _findDepartmentById(String id) {
    for (final d in service.departments) {
      if (d.departmentID == id) return d;
    }
    return null;
  }

  void _viewDepartmentById() {
    _section('Search Department');
    final id = _askStr('Enter Department ID');

    final dept = _findDepartmentById(id);
    if (dept == null) {
      _error('Department not found');
      return;
    }

    stdout.writeln(ui.cyan('\nDepartment Details:'));
    stdout.writeln('ID: ${dept.departmentID}');
    stdout.writeln('Name: ${dept.name}');
    stdout.writeln('Description: ${dept.description}');

    // Show totals
    final totalRooms = dept.rooms.length;
    final totalBeds =
        dept.rooms.fold<int>(0, (sum, room) => sum + room.beds.length);
    final totalStaff = dept.staff.length;
    final occupiedBeds = dept.rooms
        .expand((room) => room.beds)
        .where((bed) => bed.isOccupied())
        .length;

    stdout.writeln(ui.green('\nSummary:'));
    stdout.writeln('Total Rooms: $totalRooms');
    stdout.writeln('Total Beds: $totalBeds');
    stdout.writeln('Occupied Beds: $occupiedBeds');
    stdout.writeln('Available Beds: ${totalBeds - occupiedBeds}');
    stdout.writeln('Total Staff: $totalStaff');

    // Show staff breakdown by role
    stdout.writeln(ui.yellow('\nStaff Breakdown:'));
    final staffByRole = <StaffRole, int>{};
    for (final staff in dept.staff) {
      staffByRole[staff.role] = (staffByRole[staff.role] ?? 0) + 1;
    }
    for (final role in staffByRole.entries) {
      stdout.writeln('${role.key.name}: ${role.value}');
    }

    // Show room status breakdown
    stdout.writeln(ui.magenta('\nRoom Status:'));
    final roomsByStatus = <RoomStatus, int>{};
    for (final room in dept.rooms) {
      roomsByStatus[room.status] = (roomsByStatus[room.status] ?? 0) + 1;
    }
    for (final status in roomsByStatus.entries) {
      stdout.writeln('${status.key.name}: ${status.value}');
    }
  }

  Room? _findRoomById(String id) {
    for (final d in service.departments) {
      for (final r in d.rooms) {
        if (r.roomID == id) return r;
      }
    }
    return null;
  }

  Staff? _findStaffById(String id) {
    for (final d in service.departments) {
      for (final s in d.staff) {
        if (s.staffID == id) return s;
      }
    }
    return null;
  }

// AI Generated
  String _stateBadgeRoom(RoomStatus s) {
    switch (s) {
      case RoomStatus.available:
        return ui.green('[Available]');
      case RoomStatus.occupied:
        return ui.red('[Occupied]');
      case RoomStatus.maintenance:
        return ui.yellow('[Maintenance]');
      case RoomStatus.cleaning:
        return ui.blue('[Cleaning]');
      case RoomStatus.closed:
        return '[Closed]';
    }
  }

  String _stateBadgeBed(BedStatus s) {
    switch (s) {
      case BedStatus.available:
        return ui.green('[Available]');
      case BedStatus.occupied:
        return ui.red('[Occupied]');
      case BedStatus.reserved:
        return ui.yellow('[Reserved]');
      case BedStatus.cleaning:
        return ui.blue('[Cleaning]');
      case BedStatus.closed:
        return '[Closed]';
    }
  }

  String _roomTag(Room r) =>
      'Room ${r.roomID} (${r.roomNumber}) Floor ${r.floorLevel}  Type: ${r.type.name}';

  Future<void> _viewJsonData() async {
    _section('JSON Data Structure');

    for (final dept in service.departments) {
      // Department level
      stdout.writeln(ui.blue('Department: ${dept.departmentID}'));
      stdout.writeln('  Name: ${dept.name}');
      stdout.writeln('  Description: ${dept.description}');
      stdout.writeln('');

      // Rooms
      stdout.writeln(ui.yellow('  Rooms:'));
      for (final room in dept.rooms) {
        stdout.writeln('    Room ${room.roomID}:');
        stdout.writeln('      Number: ${room.roomNumber}');
        stdout.writeln('      Floor: ${room.floorLevel}');
        stdout.writeln('      Type: ${room.type.name}');
        stdout.writeln('      Status: ${room.status.name}');
        stdout.writeln('      Capacity: ${room.capacity}');

        // Beds
        stdout.writeln('      ${ui.cyan('Beds:')}');
        for (final bed in room.beds) {
          stdout.writeln('        - Bed ${bed.bedNumber} (${bed.bedID}):');
          stdout.writeln('          Status: ${bed.status.name}');
          if (bed.currentPatient != null) {
            final p = bed.currentPatient!;
            stdout.writeln('          Patient: ${p.getFullName()}');
            stdout.writeln('          Admitted: ${bed.enterDate?.toLocal()}');
          }
        }

        // Staff
        if (room.assignedStaff.isNotEmpty) {
          stdout.writeln('      ${ui.magenta('Assigned Staff:')}');
          for (final staff in room.assignedStaff) {
            stdout.writeln('        - ${staff.name} (${staff.role.name})');
          }
        }
        stdout.writeln('');
      }

      // Department Staff
      if (dept.staff.isNotEmpty) {
        stdout.writeln(ui.magenta('  Department Staff:'));
        for (final staff in dept.staff) {
          stdout.writeln('    - ${staff.name}');
          stdout.writeln('      Role: ${staff.role.name}');
          stdout.writeln('      ID: ${staff.staffID}');
          stdout.writeln('      Phone: ${staff.phoneNumber}');
        }
      }
      stdout.writeln('==========================================');
    }
    _pause();
  }

  Future<void> _viewHistory() async {
    ui.clearScreen();
    stdout.writeln(ui.cyan('=== Patient History ==='));

    try {
      final history = await historyRepo.loadHistory();

      if (history.isEmpty) {
        stdout.writeln(ui.yellow('No history records found.'));
        _pause();
        return;
      }

      for (var record in history) {
        stdout.writeln(ui.green('\nHistory ID: ${record['historyId']}'));
        stdout.writeln(
            'Patient: ${record['patientName']} (ID: ${record['patientId']})');
        stdout.writeln(
            'Room: ${record['roomNumber']}, Bed: ${record['bedNumber']}');
        stdout.writeln('Department: ${record['departmentName']}');
        stdout.writeln('Admission: ${record['admissionDate']}');
        stdout.writeln('Release: ${record['releaseDate']}');
        stdout.writeln('Status: ${record['status']}');
        if (record['notes']?.isNotEmpty ?? false) {
          stdout.writeln('Notes: ${record['notes']}');
        }
        stdout.writeln(ui.cyan('------------------------------------------'));
      }
    } catch (e) {
      _error('Error reading history: $e');
    }

    _pause();
  }
}
