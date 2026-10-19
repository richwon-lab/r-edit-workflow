import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_area_input.freezed.dart';
part 'text_area_input.g.dart';

/// 영역 입력 생성·복원이 거부된 원인이다.
enum TextInputErrorCode {
  missingField,
  invalidType,
  unknownLineBreakMode,
  unexpectedField,
  emptyAreaId,
  emptySourceText,
  emptySpecifiedLines,
  emptySpecifiedLine,
  sourceContainsCrLf,
  specifiedLineContainsCrLf,
  specifiedLinesMismatchSourceText,
}

/// 오류 코드와 JSON 필드 경로를 가진 검증 실패다.
///
/// [fieldPath]는 필드 또는 지정 줄 목록 위치이며 문자 오프셋이 아니다.
final class TextInputValidationException implements Exception {
  const TextInputValidationException(this.code, this.fieldPath);

  final TextInputErrorCode code;
  final String fieldPath;

  @override
  String toString() => 'TextInputValidationException(${code.name}, $fieldPath)';
}

/// 배치 크기·위치와 구분되는 명시적 줄바꿈 입력이다.
sealed class LineBreakInput {
  const LineBreakInput();

  /// JSON 구조를 검사한 뒤 구체 값의 생성자에서 업무 조건을 검사한다.
  factory LineBreakInput.fromJson(Object? json) {
    final object = _object(json, 'lineBreak');
    final mode = _stringField(object, 'mode', 'lineBreak.mode');
    switch (mode) {
      case 'automatic':
        _checkFields(object, const {'mode'}, 'lineBreak');
        return const AutomaticLineBreak();
      case 'specified':
        final value = _required(object, 'lines', 'lineBreak.lines');
        if (value is! List) {
          throw const TextInputValidationException(
            TextInputErrorCode.invalidType,
            'lineBreak.lines',
          );
        }
        for (var i = 0; i < value.length; i++) {
          if (value[i] is! String) {
            throw TextInputValidationException(
              TextInputErrorCode.invalidType,
              'lineBreak.lines[$i]',
            );
          }
        }
        _checkFields(object, const {'mode', 'lines'}, 'lineBreak');
        return _$SpecifiedLineBreakFromJson(object);
      default:
        throw const TextInputValidationException(
          TextInputErrorCode.unknownLineBreakMode,
          'lineBreak.mode',
        );
    }
  }

  /// 외부 변경이 모델에 영향을 주지 않는 JSON 값을 반환한다.
  Map<String, Object?> toJson();
}

/// 자동 계산에서 줄 경계를 선택하는 입력 방식이다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class AutomaticLineBreak extends LineBreakInput
    with _$AutomaticLineBreak {
  const AutomaticLineBreak();

  @override
  Map<String, Object?> toJson() => {'mode': 'automatic'};
}

/// 한 줄도 명시적인 직접 지정으로 유지한다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class SpecifiedLineBreak extends LineBreakInput
    with _$SpecifiedLineBreak {
  SpecifiedLineBreak(List<String> lines) : lines = List.unmodifiable(lines) {
    if (this.lines.isEmpty) {
      throw const TextInputValidationException(
        TextInputErrorCode.emptySpecifiedLines,
        'lineBreak.lines',
      );
    }
    for (var i = 0; i < this.lines.length; i++) {
      if (this.lines[i].isEmpty) {
        throw TextInputValidationException(
          TextInputErrorCode.emptySpecifiedLine,
          'lineBreak.lines[$i]',
        );
      }
      if (_containsCrLf(this.lines[i])) {
        throw TextInputValidationException(
          TextInputErrorCode.specifiedLineContainsCrLf,
          'lineBreak.lines[$i]',
        );
      }
    }
  }

  @JsonKey(toJson: _linesToJson)
  final List<String> lines;

  @override
  Map<String, Object?> toJson() => {
    'mode': 'specified',
    ..._$SpecifiedLineBreakToJson(this),
  };
}

/// 영역 원문과 줄 입력을 함께 검증하는 불변 값이다.
/// 검증 성공은 배치·제작 가능 판정이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class TextAreaInput with _$TextAreaInput {
  TextAreaInput({
    required this.areaId,
    required this.sourceText,
    required this.lineBreak,
  }) {
    _validateAreaId(areaId);
    _validateSourceText(sourceText);
    if (lineBreak case SpecifiedLineBreak(:final lines)
        when lines.join() != sourceText) {
      throw const TextInputValidationException(
        TextInputErrorCode.specifiedLinesMismatchSourceText,
        'lineBreak.lines',
      );
    }
  }

  /// JSON 문자열 문법과 구분해 디코딩된 입력 조각을 검증한다.
  factory TextAreaInput.fromJson(Object? json) {
    final object = _object(json, r'$');
    _stringField(object, 'areaId', 'areaId');
    _stringField(object, 'sourceText', 'sourceText');
    _required(object, 'lineBreak', 'lineBreak');
    _checkFields(object, const {'areaId', 'sourceText', 'lineBreak'}, '');
    return _$TextAreaInputFromJson(object);
  }

  final String areaId;
  final String sourceText;
  @JsonKey(fromJson: _lineBreakFromJson, toJson: _lineBreakToJson)
  final LineBreakInput lineBreak;

  Map<String, Object?> toJson() => _$TextAreaInputToJson(this);
}

// sealed 타입 분기와 출력 목록 분리만 변환 경계에 남긴다.
LineBreakInput _lineBreakFromJson(Object? json) =>
    LineBreakInput.fromJson(json);
Map<String, Object?> _lineBreakToJson(LineBreakInput value) => value.toJson();
List<String> _linesToJson(List<String> lines) => lines.toList();

bool _containsCrLf(String text) => text.contains('\r') || text.contains('\n');

void _validateAreaId(String areaId) {
  if (areaId.isEmpty) {
    throw const TextInputValidationException(
      TextInputErrorCode.emptyAreaId,
      'areaId',
    );
  }
}

void _validateSourceText(String sourceText) {
  if (sourceText.isEmpty) {
    throw const TextInputValidationException(
      TextInputErrorCode.emptySourceText,
      'sourceText',
    );
  }
  if (_containsCrLf(sourceText)) {
    throw const TextInputValidationException(
      TextInputErrorCode.sourceContainsCrLf,
      'sourceText',
    );
  }
}

Map<String, Object?> _object(Object? value, String fieldPath) {
  if (value is! Map<String, Object?>) {
    throw TextInputValidationException(
      TextInputErrorCode.invalidType,
      fieldPath,
    );
  }
  return value;
}

Object? _required(Map<String, Object?> object, String key, String fieldPath) {
  if (!object.containsKey(key)) {
    throw TextInputValidationException(
      TextInputErrorCode.missingField,
      fieldPath,
    );
  }
  return object[key];
}

String _stringField(Map<String, Object?> object, String key, String fieldPath) {
  final value = _required(object, key, fieldPath);
  if (value is! String) {
    throw TextInputValidationException(
      TextInputErrorCode.invalidType,
      fieldPath,
    );
  }
  return value;
}

void _checkFields(
  Map<String, Object?> object,
  Set<String> allowed,
  String prefix,
) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw TextInputValidationException(
        TextInputErrorCode.unexpectedField,
        prefix.isEmpty ? key : '$prefix.$key',
      );
    }
  }
}
