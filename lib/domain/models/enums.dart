enum StaffRole { nurse, doctor, janitor, maintenance, cleaner, technician }
enum RoomType { icu, surgery, maternity, isolation, general }
enum RoomStatus { available, occupied, maintenance, cleaning, closed }
enum BedStatus { available, occupied, reserved, cleaning }

T? _byNameOrNull<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  return values.firstWhere(
    (e) => e.name.toLowerCase() == name.toLowerCase(),
    orElse: () => values.first,
  );
}

String enumToString(Enum e) => e.name;

StaffRole staffRoleFrom(String s) =>
    _byNameOrNull(StaffRole.values, s) ?? StaffRole.nurse;
RoomType roomTypeFrom(String s) =>
    _byNameOrNull(RoomType.values, s) ?? RoomType.general;
RoomStatus roomStatusFrom(String s) =>
    _byNameOrNull(RoomStatus.values, s) ?? RoomStatus.available;
BedStatus bedStatusFrom(String s) =>
    _byNameOrNull(BedStatus.values, s) ?? BedStatus.available;
