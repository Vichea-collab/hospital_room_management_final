class Patient {
  final String patientID;
  final String firstName;
  final String lastName;
  final String gender;
  final DateTime dateOfBirth;
  final String phoneNumber;

  Patient({
    required this.patientID,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dateOfBirth,
    required this.phoneNumber,
  });

  String getFullName() => "$firstName $lastName";

  Map<String, dynamic> toJson() => {
        'patientID': patientID,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'phoneNumber': phoneNumber,
      };

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
        patientID: json['patientID'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        gender: json['gender'],
        dateOfBirth: DateTime.parse(json['dateOfBirth']),
        phoneNumber: json['phoneNumber'],
      );
}
