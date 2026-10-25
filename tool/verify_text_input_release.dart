// AOT 검사 결과를 표준 출력하고 의도한 불변성 예외를 확인한다.
// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert를 끈 실행 파일에서 생성·수정·JSON의 검증을 확인한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }(), 'AOT 실행 모드 확인');
  if (assertions) throw StateError('assert 비활성 실행이 필요합니다');
  final lines = [' PUMP ', ' e\u0301👩‍🔧 '];
  final manual = SpecifiedLineBreak(lines);
  final input = TextAreaInput(
    areaId: 'a',
    sourceText: lines.join(),
    lineBreak: manual,
  );
  lines.clear();
  final restored = TextAreaInput.fromJson(
    jsonDecode(jsonEncode(input.toJson())),
  );
  if (restored != input || restored.lineBreak is! SpecifiedLineBreak) {
    throw StateError('원문/직접 지정 왕복 실패');
  }
  final nextLines = ['VAL', 'VE'];
  final next = input.copyWith(
    sourceText: 'VALVE',
    lineBreak: manual.copyWith(lines: nextLines),
  );
  nextLines.clear();
  if (next.sourceText != 'VALVE' ||
      (next.lineBreak as SpecifiedLineBreak).lines.join() != 'VALVE' ||
      input.sourceText != ' PUMP  e\u0301👩‍🔧 ') {
    throw StateError('교체/목록 방어 실패');
  }
  final output = input.toJson();
  ((output['lineBreak'] as Map<String, Object?>)['lines'] as List<String>)
      .clear();
  output['sourceText'] = 'OTHER';
  if ((input.lineBreak as SpecifiedLineBreak).lines.join() !=
      input.sourceText) {
    throw StateError('반환 JSON 변경으로 모델이 바뀜');
  }
  const automaticJson =
      '{"areaId":"a","sourceText":"PUMP","lineBreak":{"mode":"automatic"}}';
  const specifiedJson =
      '{"areaId":"a","sourceText":"PUMP","lineBreak":{"mode":"specified","lines":["PUMP"]}}';
  for (final encoded in [automaticJson, specifiedJson]) {
    if (jsonEncode(TextAreaInput.fromJson(jsonDecode(encoded)).toJson()) !=
        encoded) {
      throw StateError('새 JSON 문자열 왕복 실패');
    }
  }
  if (TextAreaInput.fromJson(jsonDecode(specifiedJson)).lineBreak
      is! SpecifiedLineBreak) {
    throw StateError('직접 지정 한 줄 유실');
  }
  final failures = <(void Function(), TextInputErrorCode, String)>[
    (
      () => TextAreaInput(
        areaId: '',
        sourceText: 'PUMP',
        lineBreak: const AutomaticLineBreak(),
      ),
      TextInputErrorCode.emptyAreaId,
      'areaId',
    ),
    (
      () => input.copyWith(areaId: ''),
      TextInputErrorCode.emptyAreaId,
      'areaId',
    ),
    (
      () => input.copyWith(sourceText: 'VALVE'),
      TextInputErrorCode.specifiedLinesMismatchSourceText,
      'lineBreak.lines',
    ),
    (
      () => input.copyWith(lineBreak: manual.copyWith(lines: ['VALVE'])),
      TextInputErrorCode.specifiedLinesMismatchSourceText,
      'lineBreak.lines',
    ),
    (
      () => input.copyWith(
        sourceText: 'VALVE',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      ),
      TextInputErrorCode.specifiedLinesMismatchSourceText,
      'lineBreak.lines',
    ),
    (
      () => input.copyWith(sourceText: ''),
      TextInputErrorCode.emptySourceText,
      'sourceText',
    ),
    (
      () => input.copyWith(sourceText: 'PUMP\n'),
      TextInputErrorCode.sourceContainsCrLf,
      'sourceText',
    ),
    (
      () => manual.copyWith(lines: []),
      TextInputErrorCode.emptySpecifiedLines,
      'lineBreak.lines',
    ),
    (
      () => manual.copyWith(lines: ['']),
      TextInputErrorCode.emptySpecifiedLine,
      'lineBreak.lines[0]',
    ),
    (
      () => manual.copyWith(lines: ['PUMP\r']),
      TextInputErrorCode.specifiedLineContainsCrLf,
      'lineBreak.lines[0]',
    ),
    (
      () => TextAreaInput.fromJson({
        'areaId': 'a',
        'sourceText': 'PUMP',
        'lineBreak': {
          'mode': 'specified',
          'lines': ['pump'],
        },
      }),
      TextInputErrorCode.specifiedLinesMismatchSourceText,
      'lineBreak.lines',
    ),
    (
      () => TextAreaInput.fromJson({
        'areaId': 'a',
        'sourceText': 'PUMP',
        'lineBreak': <String, Object?>{},
      }),
      TextInputErrorCode.missingField,
      'lineBreak.mode',
    ),
    for (final mode in ['auto', 'manual'])
      (
        () => TextAreaInput.fromJson({
          'areaId': 'a',
          'sourceText': 'PUMP',
          'lineBreak': {'mode': mode},
        }),
        TextInputErrorCode.unknownLineBreakMode,
        'lineBreak.mode',
      ),
  ];
  for (final (run, code, fieldPath) in failures) {
    var rejected = false;
    try {
      run();
    } on TextInputValidationException catch (error) {
      rejected = error.code == code && error.fieldPath == fieldPath;
    }
    if (!rejected) throw StateError('업무 검증/오류 계약 우회: $code $fieldPath');
  }
  print('AOT: assert 비활성, 원문·왕복·교체·목록 방어 및 오류 ${failures.length}건 통과');
}
