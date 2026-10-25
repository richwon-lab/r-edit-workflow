import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

// 이 기하 JSON 계약의 구조 검사다. 실제 업무 값은 생성자가 검사한다.
Map<String, Object?> readGeometryObject(Object? json) {
  if (json is! Map<String, Object?>) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      r'$',
      GeometryDiagnostic(
        operation: 'readObject',
        details: GeometryTypeDetails(
          expectedType: 'object',
          actualType: json.runtimeType.toString(),
        ),
      ),
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
      GeometryDiagnostic(
        operation: 'readString',
        details: GeometryTypeDetails(
          expectedType: 'String',
          actualType: value.runtimeType.toString(),
        ),
      ),
    );
  }
  return value;
}

void checkGeometryNumber(Map<String, Object?> object, String key) {
  final value = requireGeometryField(object, key);
  if (value is! num) {
    throw GeometryValidationException(
      GeometryErrorCode.invalidType,
      key,
      GeometryDiagnostic(
        operation: 'readNumber',
        details: GeometryTypeDetails(
          expectedType: 'num',
          actualType: value.runtimeType.toString(),
        ),
      ),
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
      GeometryDiagnostic(
        operation: 'checkFinite',
        details: GeometryNumberDetails(value),
      ),
    );
  }
}
