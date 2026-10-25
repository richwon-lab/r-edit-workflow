import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/text_input_examples.dart'
    show automaticTextInputJson, inputError, specifiedTextInputJson;

void main() {
  group('TextAreaInput과 SpecifiedLineBreak의 지원 제한', () {
    test('빈 areaId 생성을 보정하지 않고 거부한다', () {
      expect(
        () => TextAreaInput(
          areaId: '',
          sourceText: 'PUMP',
          lineBreak: const AutomaticLineBreak(),
        ),
        inputError(TextInputErrorCode.emptyAreaId, 'areaId'),
      );
    });

    test('빈 areaId JSON 복원을 보정하지 않고 거부한다', () {
      expect(
        () =>
            TextAreaInput.fromJson({...automaticTextInputJson(), 'areaId': ''}),
        inputError(TextInputErrorCode.emptyAreaId, 'areaId'),
      );
    });

    test('빈 sourceText 생성을 보정하지 않고 거부한다', () {
      expect(
        () => TextAreaInput(
          areaId: 'a',
          sourceText: '',
          lineBreak: const AutomaticLineBreak(),
        ),
        inputError(TextInputErrorCode.emptySourceText, 'sourceText'),
      );
    });

    test('빈 sourceText JSON 복원을 보정하지 않고 거부한다', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticTextInputJson(),
          'sourceText': '',
        }),
        inputError(TextInputErrorCode.emptySourceText, 'sourceText'),
      );
    });

    test('빈 지정 줄 목록 생성을 원인별로 거부한다', () {
      expect(
        () => SpecifiedLineBreak([]),
        inputError(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
      );
    });

    test('빈 지정 줄 목록 JSON 복원을 원인별로 거부한다', () {
      expect(
        () => TextAreaInput.fromJson(specifiedTextInputJson([])),
        inputError(TextInputErrorCode.emptySpecifiedLines, 'lineBreak.lines'),
      );
    });

    test('인덱스 1의 빈 지정 줄 생성을 원인별로 거부한다', () {
      expect(
        () => SpecifiedLineBreak(['PU', '', 'MP']),
        inputError(TextInputErrorCode.emptySpecifiedLine, 'lineBreak.lines[1]'),
      );
    });

    test('인덱스 1의 빈 지정 줄 JSON 복원을 원인별로 거부한다', () {
      expect(
        () => TextAreaInput.fromJson(specifiedTextInputJson(['PU', '', 'MP'])),
        inputError(TextInputErrorCode.emptySpecifiedLine, 'lineBreak.lines[1]'),
      );
    });

    for (final ending in ['\r', '\n', '\r\n']) {
      test('원문 생성에서 CR/LF=${jsonEncode(ending)}를 명시적으로 거부한다', () {
        expect(
          () => TextAreaInput(
            areaId: 'a',
            sourceText: 'PU${ending}MP',
            lineBreak: const AutomaticLineBreak(),
          ),
          inputError(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
        );
      });
      test('원문 JSON 복원에서 CR/LF=${jsonEncode(ending)}를 명시적으로 거부한다', () {
        expect(
          () => TextAreaInput.fromJson({
            ...automaticTextInputJson(),
            'sourceText': 'PU${ending}MP',
          }),
          inputError(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
        );
      });
      test('지정 줄 생성에서 CR/LF=${jsonEncode(ending)}를 명시적으로 거부한다', () {
        expect(
          () => SpecifiedLineBreak(['PU', '${ending}MP']),
          inputError(
            TextInputErrorCode.specifiedLineContainsCrLf,
            'lineBreak.lines[1]',
          ),
        );
      });
      test('지정 줄 JSON 복원에서 CR/LF=${jsonEncode(ending)}를 명시적으로 거부한다', () {
        expect(
          () => TextAreaInput.fromJson(
            specifiedTextInputJson(['PU', '${ending}MP']),
          ),
          inputError(
            TextInputErrorCode.specifiedLineContainsCrLf,
            'lineBreak.lines[1]',
          ),
        );
      });
    }

    for (final lines in <List<String>>[
      ['pump'],
      ['PUMP '],
      ['P', 'UM'],
      ['MP', 'PU'],
      ['PU', ' MP'],
    ]) {
      test('원문과 줄 목록의 차이를 보정하지 않는다: $lines', () {
        expect(
          () => TextAreaInput.fromJson(specifiedTextInputJson(lines)),
          inputError(
            TextInputErrorCode.specifiedLinesMismatchSourceText,
            'lineBreak.lines',
          ),
        );
      });
    }
  });
}
