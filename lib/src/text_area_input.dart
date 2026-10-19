import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_area_input.freezed.dart';
part 'text_area_input.g.dart';

/// 영역 입력 생성·복원이 거부된 원인이다.
enum TextInputErrorCode {
  missingField,
  invalidType,
  unknownMode,
  unexpectedField,
  emptyAreaId,
  emptySourceText,
  emptyManualLines,
  emptyManualLine,
  sourceContainsCrLf,
  manualLineContainsCrLf,
  manualTextMismatch,
}

/// 안정된 오류 코드와 JSON 필드 경로를 가진 검증 실패다.
///
/// [path]는 필드 또는 지정 줄 목록 위치이며 문자 오프셋이 아니다.
final class TextInputException implements Exception {
  const TextInputException(this.code, this.path);

  final TextInputErrorCode code;
  final String path;

  @override
  String toString() => 'TextInputException(${code.name}, $path)';
}

/// 배치 크기·위치와 구분되는 명시적 줄바꿈 입력이다.
sealed class LineBreakSpec {
  const LineBreakSpec();

  /// 방식·타입·필수 값은 기존 오류 계약으로 검사한다.
  factory LineBreakSpec.fromJson(Object? json) {
    final object = _object(json, 'lineBreak');
    final mode = _stringField(object, 'mode', 'lineBreak.mode');
    switch (mode) {
      case 'auto':
        _checkFields(object, const {'mode'}, 'lineBreak');
        return const AutoLineBreak();
      case 'manual':
        final value = _required(object, 'lines', 'lineBreak.lines');
        if (value is! List) {
          throw const TextInputException(
            TextInputErrorCode.invalidType,
            'lineBreak.lines',
          );
        }
        for (var i = 0; i < value.length; i++) {
          if (value[i] is! String) {
            throw TextInputException(
              TextInputErrorCode.invalidType,
              'lineBreak.lines[$i]',
            );
          }
        }
        _checkFields(object, const {'mode', 'lines'}, 'lineBreak');
        return _$ManualLineBreakFromJson(object);
      default:
        throw const TextInputException(
          TextInputErrorCode.unknownMode,
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
final class AutoLineBreak extends LineBreakSpec with _$AutoLineBreak {
  const AutoLineBreak();

  @override
  Map<String, Object?> toJson() => {'mode': 'auto'};
}

/// 한 줄도 명시적인 직접 지정으로 유지한다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class ManualLineBreak extends LineBreakSpec with _$ManualLineBreak {
  ManualLineBreak(List<String> lines) : lines = List.unmodifiable(lines) {
    if (this.lines.isEmpty) {
      throw const TextInputException(
        TextInputErrorCode.emptyManualLines,
        'lineBreak.lines',
      );
    }
    for (var i = 0; i < this.lines.length; i++) {
      if (this.lines[i].isEmpty) {
        throw TextInputException(
          TextInputErrorCode.emptyManualLine,
          'lineBreak.lines[$i]',
        );
      }
      if (_containsCrLf(this.lines[i])) {
        throw TextInputException(
          TextInputErrorCode.manualLineContainsCrLf,
          'lineBreak.lines[$i]',
        );
      }
    }
  }

  @JsonKey(toJson: _linesToJson)
  final List<String> lines;

  @override
  Map<String, Object?> toJson() => {
    'mode': 'manual',
    ..._$ManualLineBreakToJson(this),
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
    if (lineBreak case ManualLineBreak(:final lines)
        when lines.join() != sourceText) {
      throw const TextInputException(
        TextInputErrorCode.manualTextMismatch,
        'lineBreak.lines',
      );
    }
  }

  /// JSON 문자열 문법과 구분해 디코딩된 입력 조각을 검증한다.
  factory TextAreaInput.fromJson(Object? json) {
    final object = _object(json, r'$');
    _validateAreaId(_stringField(object, 'areaId', 'areaId'));
    _validateSourceText(_stringField(object, 'sourceText', 'sourceText'));
    LineBreakSpec.fromJson(_required(object, 'lineBreak', 'lineBreak'));
    _checkFields(object, const {'areaId', 'sourceText', 'lineBreak'}, '');
    return _$TextAreaInputFromJson(object);
  }

  final String areaId;
  final String sourceText;
  @JsonKey(fromJson: _lineBreakFromJson, toJson: _lineBreakToJson)
  final LineBreakSpec lineBreak;

  Map<String, Object?> toJson() => _$TextAreaInputToJson(this);
}

// sealed 타입 분기와 출력 목록 분리만 변환 경계에 남긴다.
LineBreakSpec _lineBreakFromJson(Object? json) => LineBreakSpec.fromJson(json);
Map<String, Object?> _lineBreakToJson(LineBreakSpec value) => value.toJson();
List<String> _linesToJson(List<String> lines) => lines.toList();

bool _containsCrLf(String text) => text.contains('\r') || text.contains('\n');

void _validateAreaId(String areaId) {
  if (areaId.isEmpty) {
    throw const TextInputException(TextInputErrorCode.emptyAreaId, 'areaId');
  }
}

void _validateSourceText(String sourceText) {
  if (sourceText.isEmpty) {
    throw const TextInputException(
      TextInputErrorCode.emptySourceText,
      'sourceText',
    );
  }
  if (_containsCrLf(sourceText)) {
    throw const TextInputException(
      TextInputErrorCode.sourceContainsCrLf,
      'sourceText',
    );
  }
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw TextInputException(TextInputErrorCode.invalidType, path);
  }
  return value;
}

Object? _required(Map<String, Object?> object, String key, String path) {
  if (!object.containsKey(key)) {
    throw TextInputException(TextInputErrorCode.missingField, path);
  }
  return object[key];
}

String _stringField(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! String) {
    throw TextInputException(TextInputErrorCode.invalidType, path);
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
      throw TextInputException(
        TextInputErrorCode.unexpectedField,
        prefix.isEmpty ? key : '$prefix.$key',
      );
    }
  }
}
