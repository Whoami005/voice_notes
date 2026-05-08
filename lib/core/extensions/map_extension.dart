extension JsonMapRead on Map<String, dynamic> {
  String string(String key) => _read(this, key, _asString);

  String stringOrEmpty(String key) {
    final Object? value = this[key];
    if (value == null) return '';

    return _asString(key, value);
  }

  String? stringOrNull(String key) => _readOrNull(this, key, _asString);

  int integer(String key) => _read(this, key, _asInt);

  int? integerOrNull(String key) => _readOrNull(this, key, _asInt);

  double decimal(String key) => _read(this, key, _asDouble);

  double? decimalOrNull(String key) => _readOrNull(this, key, _asDouble);

  num number(String key) => _read(this, key, _asNumber);

  num? numberOrNull(String key) => _readOrNull(this, key, _asNumber);

  bool boolean(String key) => _read(this, key, _asBool);

  bool? booleanOrNull(String key) => _readOrNull(this, key, _asBool);

  List<Object?> list(String key) {
    final Object? value = this[key];
    if (value == null) return const [];

    return _asList(key, value);
  }

  List<Object?>? listOrNull(String key) => _readOrNull(this, key, _asList);

  List<String> strings(String key) {
    final items = list(key);

    return List<String>.generate(
      items.length,
      (index) => _asString('$key[$index]', items[index]),
      growable: false,
    );
  }

  List<String>? stringsOrNull(String key) {
    final items = listOrNull(key);
    if (items == null) return null;

    return List<String>.generate(
      items.length,
      (index) => _asString('$key[$index]', items[index]),
      growable: false,
    );
  }

  List<int> integers(String key) {
    final items = list(key);

    return List<int>.generate(
      items.length,
      (index) => _asInt('$key[$index]', items[index]),
      growable: false,
    );
  }

  List<int>? integersOrNull(String key) {
    final items = listOrNull(key);
    if (items == null) return null;

    return List<int>.generate(
      items.length,
      (index) => _asInt('$key[$index]', items[index]),
      growable: false,
    );
  }

  T object<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    return fromJson(_read(this, key, _asMap));
  }

  T? objectOrNull<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final map = _readOrNull(this, key, _asMap);
    if (map == null) return null;

    return fromJson(map);
  }

  List<T> objects<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    final items = list(key);

    return List<T>.generate(
      items.length,
      (index) => fromJson(_asMap('$key[$index]', items[index])),
      growable: false,
    );
  }
}

extension LooseJsonMapRead on Map<String, dynamic> {
  String looseString(String key) => _read(this, key, _asLooseString);

  String? looseStringOrNull(String key) =>
      _readOrNull(this, key, _asLooseString);

  int looseInteger(String key) => _read(this, key, _asLooseInt);

  int? looseIntegerOrNull(String key) => _readOrNull(this, key, _asLooseInt);

  double looseDecimal(String key) => _read(this, key, _asLooseDouble);

  double? looseDecimalOrNull(String key) =>
      _readOrNull(this, key, _asLooseDouble);

  num looseNumber(String key) => _read(this, key, _asLooseNumber);

  num? looseNumberOrNull(String key) => _readOrNull(this, key, _asLooseNumber);

  bool looseBoolean(String key) => _read(this, key, _asLooseBool);

  bool? looseBooleanOrNull(String key) => _readOrNull(this, key, _asLooseBool);
}

T _read<T>(
  Map<String, dynamic> json,
  String key,
  T Function(String key, Object? value) parse,
) {
  return parse(key, _required(json, key));
}

T? _readOrNull<T>(
  Map<String, dynamic> json,
  String key,
  T Function(String key, Object? value) parse,
) {
  final Object? value = json[key];
  if (value == null) return null;

  return parse(key, value);
}

Object _required(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    throw FormatException("Missing or null required JSON value '$key'");
  }

  return value;
}

String _asString(String key, Object? value) {
  if (value is String) return value;

  return _throwType(key, 'String', value);
}

String _asLooseString(String key, Object? value) {
  if (value is String || value is num || value is bool) {
    return value.toString();
  }

  return _throwType(key, 'String, num, or bool', value);
}

int _asInt(String key, Object? value) {
  if (value is int) return value;

  return _throwType(key, 'int', value);
}

int _asLooseInt(String key, Object? value) {
  if (value is int) return value;
  if (value is double) return _intFromDouble(key, value);
  if (value is String) return _intFromString(key, value);

  return _throwType(key, 'int or integral string', value);
}

double _asDouble(String key, Object? value) {
  if (value is num && value.isFinite) return value.toDouble();

  return _throwType(key, 'finite num', value);
}

double _asLooseDouble(String key, Object? value) {
  if (value is num && value.isFinite) return value.toDouble();

  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null && parsed.isFinite) return parsed;
  }

  return _throwType(key, 'finite num or numeric string', value);
}

num _asNumber(String key, Object? value) {
  if (value is num && value.isFinite) return value;

  return _throwType(key, 'finite num', value);
}

num _asLooseNumber(String key, Object? value) {
  if (value is num && value.isFinite) return value;

  if (value is String) return _numberFromString(key, value);

  return _throwType(key, 'finite num or numeric string', value);
}

bool _asBool(String key, Object? value) {
  if (value is bool) return value;

  return _throwType(key, 'bool', value);
}

bool _asLooseBool(String key, Object? value) {
  if (value is bool) return value;

  if (value is int) {
    if (value == 1) return true;
    if (value == 0) return false;
  }

  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => _throwType(key, 'bool, 1/0, or boolean string', value),
    };
  }

  return _throwType(key, 'bool, 1/0, or boolean string', value);
}

int _intFromDouble(String key, double value) {
  if (value.isFinite) return value.toInt();

  return _throwType(key, 'integral number', value);
}

int _intFromString(String key, String value) {
  final number = _numberFromString(key, value);
  if (number is int) return number;
  if (number is double) return _intFromDouble(key, number);

  return _throwType(key, 'integral string', value);
}

num _numberFromString(String key, String value) {
  final trimmed = value.trim();
  final parsedInt = int.tryParse(trimmed);
  if (parsedInt != null) return parsedInt;

  final parsedDouble = double.tryParse(trimmed);
  if (parsedDouble != null && parsedDouble.isFinite) {
    return parsedDouble;
  }

  return _throwType(key, 'numeric string', value);
}

List<Object?> _asList(String key, Object? value) {
  if (value is List<Object?>) return value;

  return _throwType(key, 'JSON list', value);
}

Map<String, dynamic> _asMap(String key, Object? value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map<Object?, Object?>) {
    return Map<String, dynamic>.from(value);
  }

  return _throwType(key, 'JSON object', value);
}

Never _throwType(String key, String expected, Object? value) {
  throw FormatException(
    "Invalid JSON value '$key': expected $expected, got ${_typeOf(value)}",
  );
}

String _typeOf(Object? value) {
  return value == null ? 'null' : value.runtimeType.toString();
}
