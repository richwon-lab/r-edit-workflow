import 'package:r_edit_workflow/src/design/design_errors.dart';
import 'package:r_edit_workflow/src/geometry/geometry_errors.dart';
import 'package:r_edit_workflow/src/product/product_design_errors.dart';
import 'package:r_edit_workflow/src/text_input_errors.dart';

// 제품 구성의 값/JSON 경계에서 실제로 공유하는 검사다. 공개 export하지 않는다.
/// 내부 도우미다. 단독 제품 값 실패 하나를 issue 목록 예외로 전달한다. 복수 참조 검사를 대신하지 않는다.
Never rejectProductValue(
  ProductDesignErrorCode code,
  String fieldPath, [
  ProductDesignIssueDetails? details,
]) => throw ProductDesignValidationException([
  ProductDesignIssue(code: code, fieldPath: fieldPath, details: details),
]);

/// 내부 ID/버전 검사다. 빈 문자열만 거부하고 원래 값을 상세에 보존한다. 소유 범위의 유일성은 상위 구성 책임이다.
void checkProductIdentifier(
  String value,
  String fieldPath,
  ProductDesignErrorCode code,
) {
  if (value.isEmpty) {
    rejectProductValue(code, fieldPath, ProductDesignIdentifierDetails(value));
  }
}

/// 내부 제품 JSON 도우미다. 문자열 키 객체만 허용하고 다른 값/null은 루트 $의 타입 오류로 거부한다.
Map<String, Object?> readProductObject(Object? json) {
  if (json is! Map<String, Object?>) {
    rejectProductValue(
      ProductDesignErrorCode.invalidType,
      r'$',
      ProductDesignTypeDetails(
        expectedType: 'object',
        actualType: json.runtimeType.toString(),
      ),
    );
  }
  return json;
}

/// 내부 도우미다. 키 부재와 명시적 null을 구분한다. 반환 null의 허용 여부는 필드별 타입 검사 책임이다.
Object? requireProductField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    rejectProductValue(ProductDesignErrorCode.missingField, key);
  }
  return object[key];
}

/// 내부 구조 검사다. optional이면 생략/null을 허용하고 그 밖에는 필수 String을 요구한다.
/// 빈 문자열은 실제 ID/버전 생성자에서 검사하며 latest 같은 값을 보충하지 않는다.
void checkProductString(
  Map<String, Object?> object,
  String key, {
  bool optional = false,
}) {
  final value = optional ? object[key] : requireProductField(object, key);
  if (optional && value == null) return;
  if (value is! String) {
    rejectProductValue(
      ProductDesignErrorCode.invalidType,
      key,
      ProductDesignTypeDetails(
        expectedType: 'String',
        actualType: value.runtimeType.toString(),
      ),
    );
  }
}

/// 내부 도우미다. 허용 목록 밖의 키를 상대 경로의 unexpectedField로 전달하고 조용히 버리지 않는다.
void checkProductFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      rejectProductValue(ProductDesignErrorCode.unexpectedField, key);
    }
  }
}

/// 내부 도우미다. List 여부만 검사하고 항목 복원은 호출자가 수행한다. 타입 차이는 지정된 상대 path로 전달한다.
List<Object?> readProductList(Object? value, String path) {
  if (value is! List) {
    rejectProductValue(
      ProductDesignErrorCode.invalidType,
      path,
      ProductDesignTypeDetails(
        expectedType: 'List',
        actualType: value.runtimeType.toString(),
      ),
    );
  }
  return value;
}

/// 제품 구성의 중첩 복원에서 상위 위치와 원인 객체를 보존한다.
T readProductChild<T>(Object? json, T Function(Object?) parse, String path) {
  try {
    return parse(json);
  } on ProductDesignValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed(path, stackTrace: stackTrace),
      stackTrace,
    );
  } on ProductDesignNestedException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      error.prefixed(path, stackTrace: stackTrace),
      stackTrace,
    );
  } on GeometryValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      ProductDesignNestedException(
        fieldPath: _nestedPath(path, error.fieldPath),
        cause: error,
        causeStackTrace: stackTrace,
      ),
      stackTrace,
    );
  } on DesignValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      ProductDesignNestedException(
        fieldPath: _nestedPath(path, error.fieldPath),
        cause: error,
        causeStackTrace: stackTrace,
      ),
      stackTrace,
    );
  } on TextInputValidationException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      ProductDesignNestedException(
        fieldPath: _nestedPath(path, error.fieldPath),
        cause: error,
        causeStackTrace: stackTrace,
      ),
      stackTrace,
    );
  }
}

String _nestedPath(String prefix, String path) =>
    path == r'$' ? prefix : '$prefix.$path';
