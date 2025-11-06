// AI generated
import 'dart:io';

import 'package:test/test.dart';
import 'package:hospital_room_management/data/history_repository.dart';
import 'package:hospital_room_management/data/json_repository.dart';
import 'package:hospital_room_management/domain/models/bed.dart';
import 'package:hospital_room_management/domain/models/department.dart';
import 'package:hospital_room_management/domain/models/enums.dart';
import 'package:hospital_room_management/domain/models/patient.dart';
import 'package:hospital_room_management/domain/models/room.dart';
import 'package:hospital_room_management/domain/models/staff.dart';
import 'package:hospital_room_management/domain/services/room_management_service.dart';

void main() {
  late Directory tempDir;
  late JsonRepository repo;
  late HistoryRepository historyRepo;
  late RoomManagementService service;
  late Department department;
  late Room room;
  late Bed bed;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('room_service_test');
    repo = JsonRepository('${tempDir.path}/data.json');
    historyRepo = HistoryRepository('${tempDir.path}/history.json');
    service = RoomManagementService(repo, historyRepo);

    department = Department(
      departmentID: 'D1',
      name: 'ICU',
      description: 'Intensive Care',
    );

    bed = Bed(bedID: 'B1', bedNumber: '1');

    room = Room(
      roomID: 'R1',
      roomNumber: '101',
      floorLevel: '1',
      type: RoomType.icu,
      status: RoomStatus.available,
      capacity: 1,
      beds: [bed],
    );

    service.addDepartment(department);
    service.addRoom(room, departmentID: department.departmentID);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('assigning patient updates bed, assignments, and history log', () async {
    final patient = Patient(
      patientID: 'P1',
      firstName: 'Sokha',
      lastName: 'Chan',
      gender: 'F',
      dateOfBirth: DateTime(2000, 1, 1),
      phoneNumber: '012345678',
    );

    final admissionTime = DateTime.utc(2024, 1, 1, 8);
    final assignment =
        await service.assignPatientToBed(patient, bed, admissionTime);

    expect(bed.isOccupied(), isTrue);
    expect(assignment.active, isTrue);
    expect(service.assignments, hasLength(1));
    expect(service.assignments.first.bed.bedID, equals(bed.bedID));

    final history = await historyRepo.loadHistory();
    expect(history, hasLength(1));
    final entry = history.first;
    expect(entry['patientId'], equals(patient.patientID));
    expect(entry['roomNumber'], equals(room.roomNumber));
    expect(entry['departmentName'], equals(department.name));
    expect(entry['status'], equals('ACTIVE'));
    expect(entry['admissionDate'], equals(admissionTime.toIso8601String()));
    expect(entry['releaseDate'], isEmpty);

    final releaseTime = admissionTime.add(const Duration(hours: 6));
    await service.releaseBed(bed, releaseTime);

    expect(bed.isOccupied(), isFalse);
    expect(service.assignments.single.active, isFalse);
    expect(service.assignments.single.endDate, equals(releaseTime));

    final updatedHistory = await historyRepo.loadHistory();
    final updatedEntry = updatedHistory.single;
    expect(updatedEntry['status'], equals('COMPLETED'));
    expect(updatedEntry['releaseDate'], equals(releaseTime.toIso8601String()));
  });

  test('marking maintenance toggles room/beds status and records tracking',
      () async {
    final staff = Staff(
      staffID: 'S1',
      name: 'Maintenance Team',
      role: StaffRole.maintenance,
      phoneNumber: '098765432',
    );

    service.assignStaffToRoom(staff, room);
    service.markRoomUnderMaintenance(room, 'Leak detected', staff);

    expect(room.status, equals(RoomStatus.maintenance));
    expect(room.beds.single.status, equals(BedStatus.closed));
    expect(room.maintenanceReason, equals('Leak detected'));
    expect(room.maintenanceStaffId, equals(staff.staffID));
    expect(room.maintenanceLoggedAt, isNotNull);
    expect(service.maintenance, hasLength(1));

    service.markRoomAvailable(room);

    expect(room.status, equals(RoomStatus.available));
    expect(room.beds.single.status, equals(BedStatus.available));
    expect(service.maintenance, isEmpty);
    expect(room.maintenanceReason, isNull);
    expect(room.maintenanceStaffId, isNull);
    expect(room.maintenanceLoggedAt, isNull);
  });

  test('removeDepartment enforces empty departments before deletion', () async {
    expect(
      () => service.removeDepartment(department.departmentID),
      throwsA(isA<StateError>()),
    );

    final removedRoom = service.removeRoom(room.roomID);
    expect(removedRoom, isTrue);

    final removedDept = service.removeDepartment(department.departmentID);
    expect(removedDept, isTrue);
    expect(service.departments, isEmpty);
  });

  test('removeRoom clears maintenance records and assignments', () async {
    final patient = Patient(
      patientID: 'P2',
      firstName: 'Dara',
      lastName: 'Lee',
      gender: 'M',
      dateOfBirth: DateTime(1995, 5, 5),
      phoneNumber: '010000000',
    );

    final start = DateTime.utc(2024, 2, 1, 9);
    await service.assignPatientToBed(patient, bed, start);
    await service.releaseBed(bed, start.add(const Duration(hours: 8)));

    service.markRoomUnderMaintenance(room, 'Deep clean', null);

    final removed = service.removeRoom(room.roomID);
    expect(removed, isTrue);
    expect(department.rooms, isEmpty);
    expect(service.assignments, isEmpty);
    expect(service.maintenance, isEmpty);
  });

  test('removeRoom throws when beds are still occupied', () async {
    final patient = Patient(
      patientID: 'P3',
      firstName: 'Vanna',
      lastName: 'Im',
      gender: 'F',
      dateOfBirth: DateTime(1990, 3, 2),
      phoneNumber: '087777777',
    );

    await service.assignPatientToBed(patient, bed, DateTime.now());

    expect(
      () => service.removeRoom(room.roomID),
      throwsA(isA<StateError>()),
    );
  });

  test('removeStaff detaches staff from department and rooms', () {
    final staff = Staff(
      staffID: 'S2',
      name: 'Nurse Kim',
      role: StaffRole.nurse,
      phoneNumber: '099999999',
    );

    service.addStaff(staff, departmentID: department.departmentID);
    service.assignStaffToRoom(staff, room);

    final removed = service.removeStaff(staff.staffID);
    expect(removed, isTrue);
    expect(department.staff, isEmpty);
    expect(room.assignedStaff, isEmpty);
  });

  test('updateDepartment applies new name and description', () {
    final updated = service.updateDepartment(
      department.departmentID,
      name: 'Updated ICU',
      description: 'Updated description',
    );

    expect(updated, isTrue);
    expect(department.name, equals('Updated ICU'));
    expect(department.description, equals('Updated description'));
  });

  test('updateRoom applies room metadata changes', () {
    final updated = service.updateRoom(
      room.roomID,
      roomNumber: '202',
      floorLevel: '2',
      type: RoomType.general,
    );

    expect(updated, isTrue);
    expect(room.roomNumber, equals('202'));
    expect(room.floorLevel, equals('2'));
    expect(room.type, equals(RoomType.general));
  });

  test('updateStaff applies staff info changes', () {
    final staff = Staff(
      staffID: 'S3',
      name: 'Doctor Heng',
      role: StaffRole.doctor,
      phoneNumber: '088888888',
    );
    service.addStaff(staff, departmentID: department.departmentID);

    final updated = service.updateStaff(
      staff.staffID,
      name: 'Doctor Heng Updated',
      role: StaffRole.technician,
      phoneNumber: '081111111',
    );

    expect(updated, isTrue);
    expect(staff.name, equals('Doctor Heng Updated'));
    expect(staff.role, equals(StaffRole.technician));
    expect(staff.phoneNumber, equals('081111111'));
  });
}
