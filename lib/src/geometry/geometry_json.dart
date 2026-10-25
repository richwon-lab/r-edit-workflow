import 'geometry_errors.dart';

// 이 기하 JSON 계약에서만 사용하는 구조 검사다. 업무 값은 생성자가 검사한다.
Map<String, Object?> readGeometryObject(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const GeometryValidationException(
      GeometryErrorCode.invalidType,
      r'$',
      GeometryDiagnostic(operation: 'readObject', expectedType: 'object'),
    );
  }
  return json;
}

Object? requireGeometryField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    throw GeometryValidationException(
      GeometryErrorCode.missingField,
      key,
      const GeometryDiagnostic(operation: 'requireField'),
    );
  }
  return object[key];
}

String readGeometryString(Map<String, Object?> object, String key) {
  final value = requireGeometryField(object, key);
  if (value is! String) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      key,
      const GeometryDiagnostic(operation: 'readString', expectedType: 'String'),
    );
  }
  return value;
}

void checkGeometryNumber(Map<String, Object?> object, String key) {
  if (requireGeometryField(object, key) is! num) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      key,
      const GeometryDiagnostic(operation: 'readNumber', expectedType: 'num'),
    );
  }
}

void checkGeometryFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw GeometryValidationException(
        GeometryErrorCode.unexpectedField,
        key,
        const GeometryDiagnostic(operation: 'checkFields'),
      );
    }
  }
}

void checkFiniteGeometryNumber(double value, String fieldPath) {
  if (!value.isFinite) {
    throw GeometryValidationException(
      GeometryErrorCode.nonFiniteNumber,
      fieldPath,
      GeometryDiagnostic(operation: 'checkFinite', value: value),
    );
  }
}
