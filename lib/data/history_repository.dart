import 'dart:convert';
import 'dart:io';

class HistoryRepository {
  final String filePath;

  HistoryRepository(this.filePath);

  Future<List<Map<String, dynamic>>> loadHistory() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // Create initial structure if file doesn't exist
        await file.writeAsString(jsonEncode({'patientHistory': []}));
        return [];
      }

      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        // Handle empty file by initializing with empty structure
        await file.writeAsString(jsonEncode({'patientHistory': []}));
        return [];
      }

      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final patientHistory = data['patientHistory'] as List?;

      if (patientHistory == null) {
        // Handle missing patientHistory field
        return [];
      }

      return List<Map<String, dynamic>>.from(patientHistory);
    } catch (e) {
      // If there's any error, recreate the file with proper structure
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
      // Handle save errors
      rethrow;
    }
  }

  Future<void> addHistoryRecord(Map<String, dynamic> record) async {
    try {
      final history = await loadHistory();
      history.add(record);
      await saveHistory(history);
    } catch (e) {
      // Handle add record errors
      rethrow;
    }
  }
}
