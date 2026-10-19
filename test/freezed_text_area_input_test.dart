import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Matcher failure(TextInputErrorCode code, String fieldPath) => throwsA(
  isA<TextInputValidationException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.fieldPath, 'fieldPath', fieldPath),
);

void main() {
  test('새 JSON 문자열을 정확히 왕복하고 지정 한 줄을 유지한다', () {
    const automatic =
        '{"areaId":"a","sourceText":"PUMP","lineBreak":{"mode":"automatic"}}';
    const specified =
        '{"areaId":"a","sourceText":"PUMP","lineBreak":{"mode":"specified","lines":["PUMP"]}}';
    for (final encoded in [automatic, specified]) {
      final value = TextAreaInput.fromJson(jsonDecode(encoded));
      expect(jsonEncode(value.toJson()), encoded);
    }
    expect(
      TextAreaInput.fromJson(jsonDecode(specified)).lineBreak,
      isA<SpecifiedLineBreak>().having((value) => value.lines, 'lines', [
        'PUMP',
      ]),
    );
  });

  test('단독 줄 입력 복원도 구조와 업무 조건을 구분한다', () {
    expect(
      LineBreakInput.fromJson({'mode': 'automatic'}),
      const AutomaticLineBreak(),
    );
    expect(
      LineBreakInput.fromJson({
        'mode': 'specified',
        'lines': ['PUMP'],
      }),
      SpecifiedLineBreak(['PUMP']),
    );
    expect(
      () => LineBreakInput.fromJson({'mode': 'specified', 'lines': []}),
      failure(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
    );
    expect(
      () => LineBreakInput.fromJson({
        'mode': 'specified',
        'lines': [1],
      }),
      failure(TextInputErrorCode.invalidType, 'lineBreak.lines[0]'),
    );
    for (final mode in ['auto', 'manual']) {
      expect(
        () => LineBreakInput.fromJson({'mode': mode}),
        failure(TextInputErrorCode.unknownLineBreakMode, 'lineBreak.mode'),
      );
    }
  });

  test('생성된 동시 수정은 원문과 줄을 함께 검증한다', () {
    final old = TextAreaInput(
      areaId: 'a',
      sourceText: 'PUMP',
      lineBreak: SpecifiedLineBreak(['PUMP']),
    );
    final next = old.copyWith(
      sourceText: 'VALVE',
      lineBreak: SpecifiedLineBreak(['VAL', 'VE']),
    );
    expect(next.sourceText, 'VALVE');
    expect((next.lineBreak as SpecifiedLineBreak).lines, ['VAL', 'VE']);
    expect(old.sourceText, 'PUMP');
    expect(
      () => old.copyWith(sourceText: 'VALVE'),
      failure(
        TextInputErrorCode.specifiedLinesMismatchSourceText,
        'lineBreak.lines',
      ),
    );
    expect(
      () => old.copyWith(
        sourceText: 'VALVE',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      ),
      failure(
        TextInputErrorCode.specifiedLinesMismatchSourceText,
        'lineBreak.lines',
      ),
    );
  });

  test('구체 타입의 중첩 수정도 부모 검증을 우회하지 않는다', () {
    final spec = SpecifiedLineBreak(['PU', 'MP']);
    final old = TextAreaInput(areaId: 'a', sourceText: 'PUMP', lineBreak: spec);
    expect(
      () => old.copyWith(lineBreak: spec.copyWith(lines: ['VALVE'])),
      failure(
        TextInputErrorCode.specifiedLinesMismatchSourceText,
        'lineBreak.lines',
      ),
    );
    final changed = old.copyWith(
      sourceText: 'VALVE',
      lineBreak: spec.copyWith(lines: ['VAL', 'VE']),
    );
    expect(changed.sourceText, 'VALVE');
    expect(spec.lines, ['PU', 'MP']);
  });

  test('생성된 줄 수정은 입력 목록을 방어 복사한다', () {
    final original = SpecifiedLineBreak(['PUMP']);
    final lines = ['VAL', 'VE'];
    final changed = original.copyWith(lines: lines);
    lines.clear();
    expect(changed.lines, ['VAL', 'VE']);
    expect(original.lines, ['PUMP']);
    expect(() => changed.lines.clear(), throwsUnsupportedError);
  });

  test('생성된 수정에서도 미지원 입력과 ID 오류를 구분한다', () {
    final old = TextAreaInput(
      areaId: 'a',
      sourceText: 'PUMP',
      lineBreak: const AutomaticLineBreak(),
    );
    expect(
      () => old.copyWith(areaId: ''),
      failure(TextInputErrorCode.emptyAreaId, 'areaId'),
    );
    expect(
      () => old.copyWith(sourceText: ''),
      failure(TextInputErrorCode.emptySourceText, 'sourceText'),
    );
    expect(
      () => old.copyWith(sourceText: 'PUMP\n'),
      failure(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
    );
    final manual = SpecifiedLineBreak(['PUMP']);
    expect(
      () => manual.copyWith(lines: []),
      failure(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
    );
    expect(
      () => manual.copyWith(lines: ['']),
      failure(TextInputErrorCode.emptySpecifiedLine, 'lineBreak.lines[0]'),
    );
    expect(
      () => manual.copyWith(lines: ['PUMP\r']),
      failure(
        TextInputErrorCode.specifiedLineContainsCrLf,
        'lineBreak.lines[0]',
      ),
    );
  });

  test('합 타입은 유지되고 방식 전환은 명시적이다', () {
    final old = TextAreaInput(
      areaId: 'a',
      sourceText: 'PUMP',
      lineBreak: const AutomaticLineBreak(),
    );
    final manual = old.copyWith(lineBreak: SpecifiedLineBreak(['PUMP']));
    final automatic = manual.copyWith(lineBreak: const AutomaticLineBreak());
    String classify(LineBreakInput spec) => switch (spec) {
      AutomaticLineBreak() => 'automatic',
      SpecifiedLineBreak(:final lines) => 'specified:${lines.length}',
    };
    expect(classify(old.lineBreak), 'automatic');
    expect(classify(manual.lineBreak), 'specified:1');
    expect(classify(automatic.lineBreak), 'automatic');
    expect(TextAreaInput.fromJson(manual.toJson()), manual);
    expect(manual, isNot(automatic));
  });

  test('알 수 없는 루트 필드는 명확한 경로로 거부한다', () {
    expect(
      () => TextAreaInput.fromJson({
        'areaId': 'a',
        'sourceText': 'PUMP',
        'lineBreak': {
          'mode': 'specified',
          'lines': ['PUMP'],
        },
        'extra': true,
      }),
      failure(TextInputErrorCode.unexpectedField, 'extra'),
    );
  });
}
