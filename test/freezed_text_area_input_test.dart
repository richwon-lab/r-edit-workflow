import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Matcher failure(TextInputErrorCode code, String path) => throwsA(
  isA<TextInputException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.path, 'path', path),
);

void main() {
  test('생성된 동시 수정은 원문과 줄을 함께 검증한다', () {
    final old = TextAreaInput(
      areaId: 'a',
      sourceText: 'PUMP',
      lineBreak: ManualLineBreak(['PUMP']),
    );
    final next = old.copyWith(
      sourceText: 'VALVE',
      lineBreak: ManualLineBreak(['VAL', 'VE']),
    );
    expect(next.sourceText, 'VALVE');
    expect((next.lineBreak as ManualLineBreak).lines, ['VAL', 'VE']);
    expect(old.sourceText, 'PUMP');
    expect(
      () => old.copyWith(sourceText: 'VALVE'),
      failure(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
    );
    expect(
      () => old.copyWith(
        sourceText: 'VALVE',
        lineBreak: ManualLineBreak(['PUMP']),
      ),
      failure(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
    );
  });

  test('구체 타입의 중첩 수정도 부모 검증을 우회하지 않는다', () {
    final spec = ManualLineBreak(['PU', 'MP']);
    final old = TextAreaInput(areaId: 'a', sourceText: 'PUMP', lineBreak: spec);
    expect(
      () => old.copyWith(lineBreak: spec.copyWith(lines: ['VALVE'])),
      failure(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
    );
    final changed = old.copyWith(
      sourceText: 'VALVE',
      lineBreak: spec.copyWith(lines: ['VAL', 'VE']),
    );
    expect(changed.sourceText, 'VALVE');
    expect(spec.lines, ['PU', 'MP']);
  });

  test('생성된 줄 수정은 입력 목록을 방어 복사한다', () {
    final original = ManualLineBreak(['PUMP']);
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
      lineBreak: const AutoLineBreak(),
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
    final manual = ManualLineBreak(['PUMP']);
    expect(
      () => manual.copyWith(lines: []),
      failure(TextInputErrorCode.emptyManualLines, 'lineBreak.lines'),
    );
    expect(
      () => manual.copyWith(lines: ['']),
      failure(TextInputErrorCode.emptyManualLine, 'lineBreak.lines[0]'),
    );
    expect(
      () => manual.copyWith(lines: ['PUMP\r']),
      failure(TextInputErrorCode.manualLineContainsCrLf, 'lineBreak.lines[0]'),
    );
  });

  test('합 타입은 유지되고 방식 전환은 명시적이다', () {
    final old = TextAreaInput(
      areaId: 'a',
      sourceText: 'PUMP',
      lineBreak: const AutoLineBreak(),
    );
    final manual = old.copyWith(lineBreak: ManualLineBreak(['PUMP']));
    final automatic = manual.copyWith(lineBreak: const AutoLineBreak());
    String classify(LineBreakSpec spec) => switch (spec) {
      AutoLineBreak() => 'auto',
      ManualLineBreak(:final lines) => 'manual:${lines.length}',
    };
    expect(classify(old.lineBreak), 'auto');
    expect(classify(manual.lineBreak), 'manual:1');
    expect(classify(automatic.lineBreak), 'auto');
    expect(TextAreaInput.fromJson(manual.toJson()), manual);
    expect(manual, isNot(automatic));
  });

  test('필드 연결과 원문 불일치가 동시에 있으면 기존 오류 순서를 유지한다', () {
    expect(
      () => TextAreaInput.fromJson({
        'areaId': 'a',
        'sourceText': 'PUMP',
        'lineBreak': {
          'mode': 'manual',
          'lines': ['OTHER'],
        },
        'extra': true,
      }),
      failure(TextInputErrorCode.unexpectedField, 'extra'),
    );
  });
}
