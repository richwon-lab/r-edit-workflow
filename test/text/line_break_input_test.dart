import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/text_input_examples.dart' show inputError;

void main() {
  group('LineBreakInput의 방식 전환과 지정 줄', () {
    test('지정 줄 수정은 입력 목록을 방어 복사한다', () {
      final original = SpecifiedLineBreak(['PUMP']);
      final lines = ['VAL', 'VE'];
      final changed = original.copyWith(lines: lines);
      lines.clear();
      expect(changed.lines, ['VAL', 'VE']);
      expect(original.lines, ['PUMP']);
      expect(() => changed.lines.clear(), throwsUnsupportedError);
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

    test('지정 목록을 비우는 수정을 거부한다', () {
      final manual = SpecifiedLineBreak(['PUMP']);
      expect(
        () => manual.copyWith(lines: []),
        inputError(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
      );
    });

    test('빈 지정 줄을 넣는 수정을 거부한다', () {
      final manual = SpecifiedLineBreak(['PUMP']);
      expect(
        () => manual.copyWith(lines: ['']),
        inputError(TextInputErrorCode.emptySpecifiedLine, 'lineBreak.lines[0]'),
      );
    });

    test('CR 포함 지정 줄을 넣는 수정을 거부한다', () {
      final manual = SpecifiedLineBreak(['PUMP']);
      expect(
        () => manual.copyWith(lines: ['PUMP\r']),
        inputError(
          TextInputErrorCode.specifiedLineContainsCrLf,
          'lineBreak.lines[0]',
        ),
      );
    });

    test('자동 JSON은 자동 타입으로 복원한다', () {
      expect(
        LineBreakInput.fromJson({'mode': 'automatic'}),
        const AutomaticLineBreak(),
      );
    });

    test('지정 한 줄 JSON은 지정 타입으로 복원한다', () {
      expect(
        LineBreakInput.fromJson({
          'mode': 'specified',
          'lines': ['PUMP'],
        }),
        SpecifiedLineBreak(['PUMP']),
      );
    });

    test('빈 지정 목록 JSON을 거부한다', () {
      expect(
        () => LineBreakInput.fromJson({
          'mode': 'specified',
          'lines': <Object?>[],
        }),
        inputError(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
      );
    });

    test('지정 줄 JSON의 숫자 요소를 거부한다', () {
      expect(
        () => LineBreakInput.fromJson({
          'mode': 'specified',
          'lines': [1],
        }),
        inputError(TextInputErrorCode.invalidType, 'lineBreak.lines[0]'),
      );
    });

    for (final mode in ['auto', 'manual']) {
      test('mode=$mode를 자동 방식으로 대체하지 않는다', () {
        expect(
          () => LineBreakInput.fromJson({'mode': mode}),
          inputError(TextInputErrorCode.unknownLineBreakMode, 'lineBreak.mode'),
        );
      });
    }
  });
}
