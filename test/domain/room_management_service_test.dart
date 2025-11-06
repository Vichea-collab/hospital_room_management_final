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
}
