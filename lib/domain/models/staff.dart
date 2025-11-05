import 'enums.dart';

class Staff {
  final String staffID;
  String name;
  StaffRole role;
  String phoneNumber;

  Staff({
    required this.staffID,
    required this.name,
    required this.role,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'staffID': staffID,
        'name': name,
        'role': role.name,
        'phoneNumber': phoneNumber,
      };

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        staffID: json['staffID'],
        name: json['name'],
        role: staffRoleFrom(json['role']),
        phoneNumber: json['phoneNumber'],
      );
}
