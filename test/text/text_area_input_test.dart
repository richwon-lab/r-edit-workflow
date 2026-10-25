import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/text_input_examples.dart'
    show textInputThroughJsonString, inputError;

void main() {
  group('TextAreaInput의 원문과 명시적 줄바꿈', () {
    final examples = <String, List<String>>{
      ' PUMP  A-1 ': [' PUMP ', ' A-1 '],
      'Ø Φ × ± ℃ # / A-b': ['Ø Φ × ± ℃', ' # / A-b'],
      '리치원 명판': ['리치원 ', '명판'],
      '가\u1100\u1161 e\u0301 é': ['가', '\u1100\u1161 ', 'e\u0301 é'],
      '👩‍🔧😀🇰🇷': ['👩‍🔧', '😀', '🇰🇷'],
      'AA AA  AA': ['AA ', 'AA  ', 'AA'],
      '   ': [' ', '  '],
      '\t PUMP\t': ['\t ', 'PUMP\t'],
    };
    for (final entry in examples.entries) {
      for (final (mode, spec) in <(String, LineBreakInput)>[
        ('자동', const AutomaticLineBreak()),
        ('직접 지정 한 줄', SpecifiedLineBreak([entry.key])),
        ('직접 지정 여러 줄', SpecifiedLineBreak(entry.value)),
      ]) {
        test('$mode 원문=${jsonEncode(entry.key)}의 공백·Unicode·지정 줄을 보존한다', () {
          final original = TextAreaInput(
            areaId: ' stable-area-id ',
            sourceText: entry.key,
            lineBreak: spec,
          );
          final restored = textInputThroughJsonString(original);
          expect(restored.areaId, ' stable-area-id ');
          expect(restored.sourceText, entry.key);
          expect(restored.toJson(), {
            'areaId': ' stable-area-id ',
            'sourceText': entry.key,
            'lineBreak': switch (spec) {
              AutomaticLineBreak() => {'mode': 'automatic'},
              SpecifiedLineBreak(:final lines) => {
                'mode': 'specified',
                'lines': lines,
              },
            },
          });
          expect(restored, original);
          expect(restored.hashCode, original.hashCode);
          switch (spec) {
            case AutomaticLineBreak():
              expect(restored.lineBreak, isA<AutomaticLineBreak>());
              expect(restored.toJson()['lineBreak'], {'mode': 'automatic'});
            case SpecifiedLineBreak(:final lines):
              expect(restored.lineBreak, isA<SpecifiedLineBreak>());
              expect((restored.lineBreak as SpecifiedLineBreak).lines, lines);
              expect(restored.toJson()['lineBreak'], {
                'mode': 'specified',
                'lines': lines,
              });
          }
        });
      }
    }

    test('비슷하게 보이는 Unicode도 같은 원문으로 바꾸지 않는다', () {
      final composed = TextAreaInput(
        areaId: 'a',
        sourceText: 'é',
        lineBreak: const AutomaticLineBreak(),
      );
      final decomposed = TextAreaInput(
        areaId: 'a',
        sourceText: 'e\u0301',
        lineBreak: const AutomaticLineBreak(),
      );
      expect(textInputThroughJsonString(composed).sourceText, 'é');
      expect(textInputThroughJsonString(decomposed).sourceText, 'e\u0301');
      expect(composed, isNot(decomposed));
    });

    test('같은 원문도 자동과 직접 지정 한 줄을 구분한다', () {
      final automatic = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: const AutomaticLineBreak(),
      );
      final manual = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: SpecifiedLineBreak(['PUMP']),
      );
      expect({
        textInputThroughJsonString(automatic),
        textInputThroughJsonString(manual),
      }, hasLength(2));
    });

    test('반복 원문도 줄 구성과 순서를 잃지 않는다', () {
      final input = TextAreaInput(
        areaId: 'a',
        sourceText: 'ABABAB',
        lineBreak: SpecifiedLineBreak(['A', 'BAB', 'AB']),
      );
      expect(
        (textInputThroughJsonString(input).lineBreak as SpecifiedLineBreak)
            .lines,
        ['A', 'BAB', 'AB'],
      );
      expect(
        () => TextAreaInput(
          areaId: 'a',
          sourceText: 'ABABAB',
          lineBreak: SpecifiedLineBreak(['BAB', 'A', 'AB']),
        ),
        inputError(
          TextInputErrorCode.specifiedLinesMismatchSourceText,
          'lineBreak.lines',
        ),
      );
    });
  });
}
