import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/text_input_examples.dart'
    show inputError, specifiedTextInputJson, textInputThroughJsonString;

void main() {
  group('TextAreaInput 수정 후 일관성과 불변성', () {
    test('전달한 목록과 공개 목록에서 모델을 바꿀 수 없다', () {
      final lines = ['PUMP ', 'A'];
      final spec = SpecifiedLineBreak(lines);
      final input = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP A',
        lineBreak: spec,
      );
      lines[0] = 'OTHER';
      lines.clear();
      expect(spec.lines, ['PUMP ', 'A']);
      expect(() => spec.lines.add('!'), throwsUnsupportedError);
      expect(() => spec.lines[0] = 'OTHER', throwsUnsupportedError);
      expect(textInputThroughJsonString(input).sourceText, 'PUMP A');
    });

    test('JSON 입출력 목록 변경도 모델에 영향을 주지 않는다', () {
      final lines = <Object?>['PU', 'MP'];
      final input = TextAreaInput.fromJson(specifiedTextInputJson(lines));
      lines[0] = 'OTHER';
      final json = input.toJson();
      final outputSpec = json['lineBreak'] as Map<String, Object?>;
      (outputSpec['lines'] as List<String>).clear();
      json['sourceText'] = 'OTHER';
      expect((input.lineBreak as SpecifiedLineBreak).lines, ['PU', 'MP']);
      expect(textInputThroughJsonString(input).sourceText, 'PUMP');
    });

    test('문구와 지정 줄을 함께 검증하고 원래 값을 보존한다', () {
      final original = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      );
      expect(
        () => TextAreaInput(
          areaId: original.areaId,
          sourceText: 'VALVE',
          lineBreak: original.lineBreak,
        ),
        inputError(
          TextInputErrorCode.specifiedLinesMismatchSourceText,
          'lineBreak.lines',
        ),
      );
      final replacement = TextAreaInput(
        areaId: original.areaId,
        sourceText: 'VALVE',
        lineBreak: SpecifiedLineBreak(['VAL', 'VE']),
      );
      expect(original.sourceText, 'PUMP');
      expect((original.lineBreak as SpecifiedLineBreak).lines, ['PUMP']);
      expect(textInputThroughJsonString(replacement).sourceText, 'VALVE');
    });

    test('원문과 지정 줄을 함께 수정하면 유효한 새 값이 되고 기존 값은 유지된다', () {
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
    });

    test('원문만 바꾸어 지정 줄과 어긋나는 수정을 거부한다', () {
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      );
      expect(
        () => old.copyWith(sourceText: 'VALVE'),
        inputError(
          TextInputErrorCode.specifiedLinesMismatchSourceText,
          'lineBreak.lines',
        ),
      );
    });

    test('이전 지정 줄을 명시해도 새 원문과 어긋나면 거부한다', () {
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      );
      expect(
        () => old.copyWith(
          sourceText: 'VALVE',
          lineBreak: SpecifiedLineBreak(['PUMP']),
        ),
        inputError(
          TextInputErrorCode.specifiedLinesMismatchSourceText,
          'lineBreak.lines',
        ),
      );
    });

    test('지정 줄만 중첩 수정해 원문과 어긋나면 거부한다', () {
      final spec = SpecifiedLineBreak(['PU', 'MP']);
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: spec,
      );
      expect(
        () => old.copyWith(lineBreak: spec.copyWith(lines: ['VALVE'])),
        inputError(
          TextInputErrorCode.specifiedLinesMismatchSourceText,
          'lineBreak.lines',
        ),
      );
    });

    test('지정 줄의 중첩 수정과 원문을 함께 교체하면 기존 줄 값은 유지된다', () {
      final spec = SpecifiedLineBreak(['PU', 'MP']);
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: spec,
      );
      final changed = old.copyWith(
        sourceText: 'VALVE',
        lineBreak: spec.copyWith(lines: ['VAL', 'VE']),
      );
      expect(changed.sourceText, 'VALVE');
      expect(spec.lines, ['PU', 'MP']);
    });

    test('areaId를 빈 값으로 수정하면 거부한다', () {
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: const AutomaticLineBreak(),
      );
      expect(
        () => old.copyWith(areaId: ''),
        inputError(TextInputErrorCode.emptyAreaId, 'areaId'),
      );
    });

    test('sourceText를 빈 값으로 수정하면 거부한다', () {
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: const AutomaticLineBreak(),
      );
      expect(
        () => old.copyWith(sourceText: ''),
        inputError(TextInputErrorCode.emptySourceText, 'sourceText'),
      );
    });

    test('sourceText를 LF 포함 값으로 수정하면 거부한다', () {
      final old = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: const AutomaticLineBreak(),
      );
      expect(
        () => old.copyWith(sourceText: 'PUMP\n'),
        inputError(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
      );
    });
  });
}
