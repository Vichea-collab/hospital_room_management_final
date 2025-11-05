import 'staff.dart';
import 'room.dart';

class MaintenanceRecord {
  final String recordID;
  final Room room;
  final Staff? staff; 
  final String reason;
  final DateTime date;

  MaintenanceRecord({
    required this.recordID,
    required this.room,
    this.staff, 
    required this.reason,
    required this.date,
  });

  @override
  String toString() =>
      "Maintenance[$recordID] room=${room.roomID}, staff=${staff?.staffID ?? '-'}, reason=$reason, date=$date";

  Map<String, dynamic> toJson() => {
        'recordID': recordID,
        'roomID': room.roomID,
        'staffID': staff?.staffID ?? '', 
        'reason': reason,
        'date': date.toIso8601String(),
      };
}
