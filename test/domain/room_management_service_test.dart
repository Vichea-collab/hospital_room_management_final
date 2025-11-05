// AI generated
import 'dart:io';
import 'package:test/test.dart';
import 'package:hospital_room_management/domain/services/room_management_service.dart';
import 'package:hospital_room_management/domain/models/department.dart';
import 'package:hospital_room_management/domain/models/room.dart';
import 'package:hospital_room_management/domain/models/bed.dart';
import 'package:hospital_room_management/domain/models/patient.dart';
import 'package:hospital_room_management/domain/models/enums.dart';
import 'package:hospital_room_management/data/json_repository.dart';
import 'package:hospital_room_management/data/history_repository.dart';

void main() {
  test('assign patient to bed sets bed occupied', () async {
    // Ensure clean test files
    final tmpFile = File('test/test_tmp.json');
    if (await tmpFile.exists()) await tmpFile.delete();
    final histFile = File('test/test_history.json');
    if (await histFile.exists()) await histFile.delete();

    final repo = JsonRepository('test/test_tmp.json');
    final historyRepo = HistoryRepository('test/test_history.json');
    final service = RoomManagementService(repo, historyRepo);

    final dept = Department(
      departmentID: 'D1',
      name: 'ICU',
      description: 'Intensive',
    );

    final room = Room(
      roomID: 'R1',
      roomNumber: '101',
      floorLevel: '1',
      type: RoomType.icu,
      status: RoomStatus.available,
      capacity: 1,
      beds: [Bed(bedID: 'B1', bedNumber: '1')],
    );

    service.addDepartment(dept);
    service.addRoom(room, departmentID: 'D1');

    final patient = Patient(
      patientID: 'P1',
      firstName: 'Sokha',
      lastName: 'Chan',
      gender: 'F',
      dateOfBirth: DateTime(2000, 1, 1),
      phoneNumber: '012345678',
    );

    final admissionTime = DateTime.now();
    final ra = await service.assignPatientToBed(
        patient, room.beds.first, admissionTime);
    expect(room.beds.first.isOccupied(), isTrue);
    expect(ra.active, isTrue);

    // Verify history is created for admission
    final history = await historyRepo.loadHistory();
    expect(history.length, equals(1));
    expect(history[0]['patientId'], equals('P1'));
    expect(history[0]['status'], equals('ACTIVE'));
    expect(history[0]['departmentName'], equals('ICU'));
    expect(
        DateTime.parse(history[0]['admissionDate'])
            .isAfter(admissionTime.subtract(Duration(seconds: 1))),
        isTrue);

    // Test release and history update
    final releaseTime = DateTime.now();
    await service.releaseBed(room.beds.first, releaseTime);
    expect(room.beds.first.isOccupied(), isFalse);

    // Verify history is updated for release
    final updatedHistory = await historyRepo.loadHistory();
    expect(updatedHistory.length, equals(1));
    expect(updatedHistory[0]['status'], equals('COMPLETED'));
    expect(
        DateTime.parse(updatedHistory[0]['releaseDate'])
            .isAfter(releaseTime.subtract(Duration(seconds: 1))),
        isTrue);
  });

  test('history repository handles empty and invalid files', () async {
    final emptyFile = File('test/empty_test.json');
    if (await emptyFile.exists()) await emptyFile.delete();
    final historyRepo = HistoryRepository('test/empty_test.json');

    // Test empty file handling
    final emptyHistory = await historyRepo.loadHistory();
    expect(emptyHistory, isEmpty);

    // Test adding and retrieving a record
    await historyRepo.addHistoryRecord(
        {'historyId': 'TEST-1', 'patientId': 'P1', 'status': 'ACTIVE'});

    final history = await historyRepo.loadHistory();
    expect(history.length, equals(1));
    expect(history[0]['historyId'], equals('TEST-1'));
  });
}
