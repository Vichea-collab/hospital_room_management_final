// AI generated
import 'package:test/test.dart';
import 'package:hospital_room_management/data/json_repository.dart';
import 'package:hospital_room_management/domain/models/department.dart';

void main() {
  test('save & load departments roundtrip', () async {
    final repo = JsonRepository('test/test_repo.json');
    final original = [
      Department(departmentID: 'D1', name: 'ICU', description: 'desc')
    ];
    await repo.saveDepartments(original);
    final loaded = await repo.loadDepartments();
    expect(loaded.first.departmentID, equals('D1'));
  });
}
