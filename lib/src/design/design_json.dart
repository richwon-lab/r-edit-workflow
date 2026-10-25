import '../geometry/closed_boundary.dart';
import '../geometry/geometry_errors.dart';
import 'design_errors.dart';

// 도안 모델에서 실제로 공유하는 JSON 구조 검사와 경계 직렬화다.
// 패키지 공개 진입점에서는 노출하지 않는다.
Map<String, Object?> readDesignObject(Object? json) {
  if (json is! Map<String, Object?>) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: r'$',
        details: DesignTypeDetails(
          expectedType: 'object',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  return json;
}

Object? requireDesignField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    throw DesignValidationException(
      DesignValidationIssue(code: DesignErrorCode.missingField, fieldPath: key),
    );
  }
  return object[key];
}

void readDesignString(Map<String, Object?> object, String key) {
  final value = requireDesignField(object, key);
  if (value is! String) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: key,
        details: DesignTypeDetails(
          expectedType: 'String',
          actualType: value.runtimeType.toString(),
        ),
      ),
    );
  }
}

void checkDesignFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw DesignValidationException(
        DesignValidationIssue(
          code: DesignErrorCode.unexpectedField,
          fieldPath: key,
        ),
      );
    }
  }
}

List readDesignList(Object? json, String fieldPath) {
  if (json is! List) {
    throw DesignValidationException(
      DesignValidationIssue(
        code: DesignErrorCode.invalidType,
        fieldPath: fieldPath,
        details: DesignTypeDetails(
          expectedType: 'List',
          actualType: json.runtimeType.toString(),
        ),
      ),
    );
  }
  return json;
}

ClosedBoundary readBoundary(Object? json, String fieldPath) {
  try {
    return ClosedBoundary.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed(fieldPath);
  }
}

Map<String, Object?> writeBoundary(ClosedBoundary boundary) =>
    boundary.toJson();
