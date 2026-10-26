import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:r_edit_workflow/src/text_input_errors.dart';

part 'text_area_input.freezed.dart';
part 'text_area_input.g.dart';

/// 배치 크기·위치와 구분되는 명시적 줄바꿈 입력이다.
sealed class LineBreakInput {
  /// 자동/직접 지정 합 타입의 기반 생성자다. 줄바꿈 방식은 항상 구체 타입으로 명시한다.
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
  /// 줄 경계를 자동 계산하도록 요청한다. 실제 계산 결과·패턴 등록·제작 가능 판정은 생성하지 않는다.
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
  /// 목록을 방어 복사하고 빈 목록·빈 항목·CR/LF를 문구 오류로 거부한다.
  /// 원문과의 일치는 원문을 함께 가진 TextAreaInput에서 검사한다.
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

  /// 원문을 순서대로 분할한 수정 불가 문자열 목록이다. 한 항목도 직접 지정 상태를 유지한다.
  /// 공백·Unicode를 그대로 보존하고 항목 인덱스는 문자 위치 단위가 아니다.
  @JsonKey(toJson: _linesToJson)
  final List<String> lines;

  @override
  Map<String, Object?> toJson() => {
    'mode': 'specified',
    ..._$SpecifiedLineBreakToJson(this),
  };
}

/// 영역 원문과 줄 입력을 함께 검증하는 불변 값이다.
/// 원문 공백·기호·대소문자·Unicode 표현은 보정하지 않는다. 직접 지정은 한 줄도 그 방식으로 유지한다.
/// 빈 원문·빈 줄·CR/LF는 현재 지원 제한이다. 검증 성공은 배치·제작·저장 가능 판정이 아니다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
@JsonSerializable()
final class TextAreaInput with _$TextAreaInput {
  /// 영역 ID·원문·줄 입력을 하나의 유효한 값으로 검사한다. 실패 코드는 TextInputErrorCode를 따른다.
  /// 지정 줄 연결이 원문과 다르면 거부하며 copyWith도 이 생성자를 통해 일관성을 지킨다.
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
  /// 필수 누락·명시적 null/타입·미지원 mode·추가 키는 TextInputErrorCode로 구분한다.
  /// 원문/지정 줄의 업무 조건도 생성자와 같으며 첫 TextInputValidationException을 전달한다.
  factory TextAreaInput.fromJson(Object? json) {
    final object = _object(json, r'$');
    _stringField(object, 'areaId', 'areaId');
    _stringField(object, 'sourceText', 'sourceText');
    _required(object, 'lineBreak', 'lineBreak');
    _checkFields(object, const {'areaId', 'sourceText', 'lineBreak'}, '');
    return _$TextAreaInputFromJson(object);
  }

  /// 연결할 적용 도안 안의 영역 ID다. 빈 값만 거부하고 표시 이름/문구로 생성하지 않는다.
  /// 이 값 단독으로 영역 존재·중복을 검사하지 않으며 도안이 달라지면 같은 문자열도 같은 영역을 뜻하지 않는다.
  final String areaId;

  /// 공백·기호·대소문자·Unicode 표현을 보존하는 원문이다. trim·정규화를 하지 않는다.
  /// 현재 빈 문자열/CR/LF는 미지원이며 공백만 있는 문자열은 빈 원문으로 취급하지 않는다.
  final String sourceText;

  /// 자동 선택 요청 또는 직접 지정 줄 목록이다. 원문과 동시에 교체해야 하며 불일치한 중간 값은 생성하지 않는다.
  @JsonKey(fromJson: _lineBreakFromJson, toJson: _lineBreakToJson)
  final LineBreakInput lineBreak;

  /// 원문과 명시적 줄바꿈 방식을 독립 JSON으로 내보낸다. 반환 목록/Map 변경은 모델에 전파되지 않는다.
  /// 이 조각은 전체 작업 파일이나 임시 저장 형식이 아니다.
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
