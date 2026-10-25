import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/text_input_examples.dart'
    show automaticTextInputJson, specifiedTextInputJson, inputError;

void main() {
  group('TextAreaInput의 JSON 경계', () {
    for (final field in ['areaId', 'sourceText', 'lineBreak']) {
      test('필수 누락: $field', () {
        final json = automaticTextInputJson()..remove(field);
        expect(
          () => TextAreaInput.fromJson(json),
          inputError(TextInputErrorCode.missingField, field),
        );
      });
      for (final value in <Object?>[null, 1, true, []]) {
        test('타입 오류: $field = $value', () {
          final json = automaticTextInputJson()..[field] = value;
          expect(
            () => TextAreaInput.fromJson(json),
            inputError(TextInputErrorCode.invalidType, field),
          );
        });
      }
    }

    for (final value in <Object?>[
      null,
      [],
      'text',
      1,
      {1: 'value'},
    ]) {
      test('최상위는 문자열 키 객체여야 한다: $value', () {
        expect(
          () => TextAreaInput.fromJson(value),
          inputError(TextInputErrorCode.invalidType, r'$'),
        );
      });
    }

    test('방식 누락을 자동으로 바꾸지 않는다', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticTextInputJson(),
          'lineBreak': <String, Object?>{},
        }),
        inputError(TextInputErrorCode.missingField, 'lineBreak.mode'),
      );
    });

    for (final value in <Object?>[null, 1, [], {}]) {
      test('방식의 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson({
            ...automaticTextInputJson(),
            'lineBreak': {'mode': value},
          }),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.mode'),
        );
      });
    }

    for (final mode in ['', 'AUTO', 'manual ', 'unknown', 'auto', 'manual']) {
      test('모르는 방식: $mode', () {
        expect(
          () => TextAreaInput.fromJson({
            ...automaticTextInputJson(),
            'lineBreak': {'mode': mode},
          }),
          inputError(TextInputErrorCode.unknownLineBreakMode, 'lineBreak.mode'),
        );
      });
    }

    test('직접 지정 줄 목록 누락', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticTextInputJson(),
          'lineBreak': {'mode': 'specified'},
        }),
        inputError(TextInputErrorCode.missingField, 'lineBreak.lines'),
      );
    });

    for (final value in <Object?>[null, 'PUMP', 1, {}]) {
      test('줄 목록 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson(specifiedTextInputJson(value)),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.lines'),
        );
      });
    }

    for (final value in <Object?>[null, 1, true, []]) {
      test('줄 요소 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson(specifiedTextInputJson(['PU', value])),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.lines[1]'),
        );
      });
    }

    test('루트의 알 수 없는 필드를 경로와 함께 거부한다', () {
      expect(
        () => TextAreaInput.fromJson({...automaticTextInputJson(), 'extra': 1}),
        inputError(TextInputErrorCode.unexpectedField, 'extra'),
      );
    });

    test('자동 방식에 지정 줄이 있으면 버리지 않고 거부한다', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticTextInputJson(),
          'lineBreak': {
            'mode': 'automatic',
            'lines': ['PUMP'],
          },
        }),
        inputError(TextInputErrorCode.unexpectedField, 'lineBreak.lines'),
      );
    });

    test('지정 방식의 알 수 없는 필드를 경로와 함께 거부한다', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticTextInputJson(),
          'lineBreak': {
            'mode': 'specified',
            'lines': ['PUMP'],
            'extra': 1,
          },
        }),
        inputError(TextInputErrorCode.unexpectedField, 'lineBreak.extra'),
      );
    });

    for (final mode in ['automatic', 'specified']) {
      test('mode=$mode JSON 문자열은 키 순서와 무관하게 고정된 구조를 보존한다', () {
        final expected = <String, Object?>{
          'areaId': 'a',
          'sourceText': 'PUMP',
          'lineBreak': {
            'mode': mode,
            if (mode == 'specified') 'lines': ['PUMP'],
          },
        };
        final encoded = jsonEncode({
          'lineBreak': expected['lineBreak'],
          'sourceText': 'PUMP',
          'areaId': 'a',
        });
        final value = TextAreaInput.fromJson(jsonDecode(encoded));
        expect(value.toJson(), expected);
        expect(jsonDecode(jsonEncode(value.toJson())), expected);
        if (mode == 'specified') {
          expect(
            value.lineBreak,
            isA<SpecifiedLineBreak>().having((s) => s.lines, 'lines', ['PUMP']),
          );
        }
      });
    }

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
        inputError(TextInputErrorCode.unexpectedField, 'extra'),
      );
    });
  });
}
