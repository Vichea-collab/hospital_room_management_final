import 'dart:convert';
import 'dart:io';
import '../domain/models/department.dart';

class JsonRepository {
  final String filePath;

  JsonRepository(this.filePath);

  Future<void> saveDepartments(List<Department> departments) async {
    final data = departments.map((d) => d.toJson()).toList();
    final jsonString = jsonEncode({'departments': data});
    final file = File(filePath);
    await file.writeAsString(jsonString);
  }

  Future<List<Department>> loadDepartments() async {
    final file = File(filePath);
    if (!await file.exists()) return [];
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final list = (data['departments'] as List? ?? []);
    return list.map((e) => Department.fromJson(e)).toList();
  }
}
