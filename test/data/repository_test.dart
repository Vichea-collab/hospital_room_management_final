import 'dart:io';

import 'package:test/test.dart';
import 'package:hospital_room_management/data/json_repository.dart';
import 'package:hospital_room_management/domain/models/bed.dart';
import 'package:hospital_room_management/domain/models/department.dart';
import 'package:hospital_room_management/domain/models/enums.dart';
import 'package:hospital_room_management/domain/models/room.dart';
import 'package:hospital_room_management/domain/models/staff.dart';

void main() {
  late Directory tempDir;
  late JsonRepository repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('json_repository_test');
    repository = JsonRepository('${tempDir.path}/departments.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loadDepartments returns empty list when file missing', () async {
    final result = await repository.loadDepartments();
    expect(result, isEmpty);
  });

  test('loadDepartments throws when file contains invalid json', () async {
    final dataFile = File('${tempDir.path}/departments.json');
    await dataFile.writeAsString('');

    await expectLater(
      repository.loadDepartments(),
      throwsA(isA<FormatException>()),
    );
  });

  test('saveDepartments persists rooms, beds, and staff details', () async {
    final department = Department(
      departmentID: 'D1',
      name: 'ICU',
      description: 'Intensive care unit',
    );

    final bed = Bed(bedID: 'B1', bedNumber: '1');

    final room = Room(
      roomID: 'R1',
      roomNumber: '101',
      floorLevel: '1',
      type: RoomType.icu,
      status: RoomStatus.available,
      capacity: 1,
      beds: [bed],
    );

    final staff = Staff(
      staffID: 'S1',
      name: 'Nurse Tep',
      role: StaffRole.nurse,
      phoneNumber: '012345678',
    );

    department.addRoom(room);
    department.addStaff(staff);

    await repository.saveDepartments([department]);

    final loaded = await repository.loadDepartments();
    expect(loaded, hasLength(1));

    final loadedDept = loaded.single;
    expect(loadedDept.departmentID, equals('D1'));
    expect(loadedDept.getRooms(), hasLength(1));
    expect(loadedDept.getStaff(), hasLength(1));

    final loadedRoom = loadedDept.getRooms().single;
    expect(loadedRoom.roomNumber, equals('101'));
    expect(loadedRoom.getDepartment(), isNotNull);
    expect(loadedRoom.beds, hasLength(1));
    expect(loadedRoom.beds.single.bedNumber, equals('1'));

    final loadedStaff = loadedDept.getStaff().single;
    expect(loadedStaff.staffID, equals('S1'));
    expect(loadedStaff.role, equals(StaffRole.nurse));
  });
}
