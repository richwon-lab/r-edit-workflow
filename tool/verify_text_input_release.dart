import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert를 끈 실행 파일에서 생성·수정·JSON의 검증을 확인한다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }());
  if (assertions) throw StateError('assert 비활성 실행이 필요합니다');
  final lines = [' PUMP ', ' e\u0301👩‍🔧 '];
  final manual = ManualLineBreak(lines);
  final input = TextAreaInput(
    areaId: 'a',
    sourceText: lines.join(),
    lineBreak: manual,
  );
  lines.clear();
  final restored = TextAreaInput.fromJson(
    jsonDecode(jsonEncode(input.toJson())),
  );
  if (restored != input || restored.lineBreak is! ManualLineBreak) {
    throw StateError('원문/직접 지정 왕복 실패');
  }
  final nextLines = ['VAL', 'VE'];
  final next = input.copyWith(
    sourceText: 'VALVE',
    lineBreak: manual.copyWith(lines: nextLines),
  );
  nextLines.clear();
  if (next.sourceText != 'VALVE' ||
      (next.lineBreak as ManualLineBreak).lines.join() != 'VALVE' ||
      input.sourceText != ' PUMP  e\u0301👩‍🔧 ') {
    throw StateError('교체/목록 방어 실패');
  }
  final failures = <(void Function(), TextInputErrorCode, String)>[
    (
      () => TextAreaInput(
        areaId: '',
        sourceText: 'PUMP',
        lineBreak: const AutoLineBreak(),
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
      TextInputErrorCode.manualTextMismatch,
      'lineBreak.lines',
    ),
    (
      () => input.copyWith(lineBreak: manual.copyWith(lines: ['VALVE'])),
      TextInputErrorCode.manualTextMismatch,
      'lineBreak.lines',
    ),
    (
      () => input.copyWith(
        sourceText: 'VALVE',
        lineBreak: ManualLineBreak(['PUMP']),
      ),
      TextInputErrorCode.manualTextMismatch,
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
      TextInputErrorCode.emptyManualLines,
      'lineBreak.lines',
    ),
    (
      () => manual.copyWith(lines: ['']),
      TextInputErrorCode.emptyManualLine,
      'lineBreak.lines[0]',
    ),
    (
      () => manual.copyWith(lines: ['PUMP\r']),
      TextInputErrorCode.manualLineContainsCrLf,
      'lineBreak.lines[0]',
    ),
    (
      () => TextAreaInput.fromJson({
        'areaId': 'a',
        'sourceText': 'PUMP',
        'lineBreak': {
          'mode': 'manual',
          'lines': ['pump'],
        },
      }),
      TextInputErrorCode.manualTextMismatch,
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
  ];
  for (final (run, code, path) in failures) {
    var rejected = false;
    try {
      run();
    } on TextInputException catch (error) {
      rejected = error.code == code && error.path == path;
    }
    if (!rejected) throw StateError('업무 검증/오류 계약 우회: $code $path');
  }
  print('AOT: assert 비활성, 원문·왕복·교체·목록 방어 및 오류 ${failures.length}건 통과');
}
