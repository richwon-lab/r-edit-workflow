import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';

// 도안 모델에서 실제로 공유하는 JSON 구조 검사와 경계 직렬화다.
// 패키지 공개 진입점에서는 노출하지 않는다.
/// 내부 도안 JSON 도우미다. 문자열 키 객체만 허용하고 다른 값/null은 루트 $의 타입 오류로 거부한다. 공개 export가 아니다.
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

/// 내부 도우미다. 키 부재만 missingField로 거부하며 명시적 null의 타입 판정은 호출자가 수행한다.
Object? requireDesignField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    throw DesignValidationException(
      DesignValidationIssue(code: DesignErrorCode.missingField, fieldPath: key),
    );
  }
  return object[key];
}

/// 내부 도우미다. 필수 키와 String 타입을 검사하고 보정하지 않는다. 빈 문자열 의미는 각 업무 생성자가 검사한다.
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

/// 내부 도우미다. allowed 밖의 키를 unexpectedField로 거부한다. 값 검증이나 순서 보장은 하지 않는다.
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

/// 내부 도우미다. List 타입만 검사하고 항목 검사는 호출자가 수행한다. 실패는 지정된 상대 fieldPath에 연결한다.
List<Object?> readDesignList(Object? json, String fieldPath) {
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

/// 내부 경계 복원 도우미다. 원래 기하 코드/진단을 보존하고 도안 필드 경로를 연결한다.
ClosedBoundary readBoundary(Object? json, String fieldPath) {
  try {
    return ClosedBoundary.fromJson(json);
  } on GeometryValidationException catch (error) {
    throw error.prefixed(fieldPath);
  }
}

/// 내부 필드 변환 도우미다. 경계 정본을 새 JSON으로 내보내고 단위·업무 역할을 중복 저장하지 않는다.
Map<String, Object?> writeBoundary(ClosedBoundary boundary) =>
    boundary.toJson();
