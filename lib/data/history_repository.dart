import 'dart:convert';
import 'dart:io';

class HistoryRepository {
  final String filePath;

  HistoryRepository(this.filePath);

  Future<List<Map<String, dynamic>>> loadHistory() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        await file.writeAsString(jsonEncode({'patientHistory': []}));
        return [];
      }

      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        await file.writeAsString(jsonEncode({'patientHistory': []}));
        return [];
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final patientHistory = data['patientHistory'] as List?;

      if (patientHistory == null) {
        return [];
      }

      return List<Map<String, dynamic>>.from(patientHistory);
    } catch (e) {
      final file = File(filePath);
      await file.writeAsString(jsonEncode({'patientHistory': []}));
      return [];
    }
  }

  Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    try {
      final jsonString = jsonEncode({'patientHistory': history});
      final file = File(filePath);
      await file.writeAsString(jsonString);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addHistoryRecord(Map<String, dynamic> record) async {
    try {
      final history = await loadHistory();
      history.add(record);
      await saveHistory(history);
    } catch (e) {
      rethrow;
    }
  }
}
