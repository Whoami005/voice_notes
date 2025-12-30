import 'package:uuid/uuid.dart';

class UuidManager {
  const UuidManager._();

  static const Uuid _uuid = Uuid();

  static String v1() => _uuid.v1();

  static bool isUUID(String value) => Uuid.isValidUUID(fromString: value);
}
