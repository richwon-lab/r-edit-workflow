import '../design/design_errors.dart';
import '../geometry/geometry_errors.dart';
import '../text_area_input.dart';
import 'product_design_errors.dart';

// 제품 구성의 값/JSON 경계에서 실제로 공유하는 검사다. 공개 export하지 않는다.
Never rejectProductValue(
  ProductDesignErrorCode code,
  String fieldPath, [
  ProductDesignIssueDetails? details,
]) => throw ProductDesignValidationException([
  ProductDesignIssue(code: code, fieldPath: fieldPath, details: details),
]);

void checkProductIdentifier(
  String value,
  String fieldPath,
  ProductDesignErrorCode code,
) {
  if (value.isEmpty) {
    rejectProductValue(code, fieldPath, ProductDesignIdentifierDetails(value));
  }
}

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

Object? requireProductField(Map<String, Object?> object, String key) {
  if (!object.containsKey(key)) {
    rejectProductValue(ProductDesignErrorCode.missingField, key);
  }
  return object[key];
}

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

void checkProductFields(Map<String, Object?> object, Set<String> allowed) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      rejectProductValue(ProductDesignErrorCode.unexpectedField, key);
    }
  }
}

List readProductList(Object? value, String path) {
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
  } on ProductDesignValidationException catch (error) {
    throw error.prefixed(path);
  } on ProductDesignNestedException catch (error) {
    throw error.prefixed(path);
  } on GeometryValidationException catch (error) {
    throw ProductDesignNestedException(
      fieldPath: _nestedPath(path, error.fieldPath),
      cause: error,
    );
  } on DesignValidationException catch (error) {
    throw ProductDesignNestedException(
      fieldPath: _nestedPath(path, error.fieldPath),
      cause: error,
    );
  } on TextInputValidationException catch (error) {
    throw ProductDesignNestedException(
      fieldPath: _nestedPath(path, error.fieldPath),
      cause: error,
    );
  }
}

String _nestedPath(String prefix, String path) =>
    path == r'$' ? prefix : '$prefix.$path';
