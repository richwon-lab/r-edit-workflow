import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

// 이 기하 JSON 계약의 구조 검사다. 실제 업무 값은 생성자가 검사한다.
/// 내부 기하 JSON 도우미다. 문자열 키 객체가 아니면 루트 $의 invalidType과 기대/실제 타입을 제공한다.
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

/// 내부 도우미다. 키 부재만 missingField로 거부한다. null 여부·수치 의미는 다음 검사에서 구분한다.
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

/// 내부 태그 읽기다. 필수 String을 검사하되 알려진 단위/종류인지는 호출자가 판단한다.
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

/// 내부 수치 구조 검사다. 정수/소수 num을 허용하며 유한성·양수 조건은 실제 값 생성자가 검사한다.
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

/// 내부 도우미다. 허용되지 않은 키를 해당 객체 상대 경로의 unexpectedField로 거부한다.
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

/// 내부 값 검사다. NaN/무한대를 nonFiniteNumber와 입력 수치 진단으로 거부한다.
/// 길이인지 무차원인지는 호출 필드/도안 문맥이 정하며 양수 여부는 이 함수가 검사하지 않는다.
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
