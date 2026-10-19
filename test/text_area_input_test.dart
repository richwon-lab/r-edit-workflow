import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Matcher inputError(TextInputErrorCode code, String path) => throwsA(
  isA<TextInputException>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.path, 'path', path),
);

Map<String, Object?> automaticJson() => {
  'areaId': 'area-1',
  'sourceText': 'PUMP',
  'lineBreak': {'mode': 'auto'},
};

Map<String, Object?> manualJson(Object? lines) => {
  ...automaticJson(),
  'lineBreak': {'mode': 'manual', 'lines': lines},
};

TextAreaInput roundTrip(TextAreaInput input) =>
    TextAreaInput.fromJson(jsonDecode(jsonEncode(input.toJson())));

void main() {
  group('원문과 명시적 방식 왕복', () {
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
      test('자동·직접 한 줄·여러 줄 보존: ${entry.key}', () {
        for (final spec in <LineBreakSpec>[
          const AutoLineBreak(),
          ManualLineBreak([entry.key]),
          ManualLineBreak(entry.value),
        ]) {
          final original = TextAreaInput(
            areaId: ' stable-area-id ',
            sourceText: entry.key,
            lineBreak: spec,
          );
          final restored = roundTrip(original);
          expect(restored.areaId, ' stable-area-id ');
          expect(restored.sourceText, entry.key);
          expect(restored, original);
          expect(restored.hashCode, original.hashCode);
          switch (spec) {
            case AutoLineBreak():
              expect(restored.lineBreak, isA<AutoLineBreak>());
              expect(restored.toJson()['lineBreak'], {'mode': 'auto'});
            case ManualLineBreak(:final lines):
              expect(restored.lineBreak, isA<ManualLineBreak>());
              expect((restored.lineBreak as ManualLineBreak).lines, lines);
              expect(restored.toJson()['lineBreak'], {
                'mode': 'manual',
                'lines': lines,
              });
          }
        }
      });
    }

    test('비슷하게 보이는 Unicode도 같은 원문으로 바꾸지 않는다', () {
      final composed = TextAreaInput(
        areaId: 'a',
        sourceText: 'é',
        lineBreak: const AutoLineBreak(),
      );
      final decomposed = TextAreaInput(
        areaId: 'a',
        sourceText: 'e\u0301',
        lineBreak: const AutoLineBreak(),
      );
      expect(roundTrip(composed).sourceText, 'é');
      expect(roundTrip(decomposed).sourceText, 'e\u0301');
      expect(composed, isNot(decomposed));
    });

    test('같은 원문도 자동과 직접 지정 한 줄을 구분한다', () {
      final automatic = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: const AutoLineBreak(),
      );
      final manual = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: ManualLineBreak(['PUMP']),
      );
      expect({roundTrip(automatic), roundTrip(manual)}, hasLength(2));
    });

    test('반복 원문도 줄 구성과 순서를 잃지 않는다', () {
      final input = TextAreaInput(
        areaId: 'a',
        sourceText: 'ABABAB',
        lineBreak: ManualLineBreak(['A', 'BAB', 'AB']),
      );
      expect((roundTrip(input).lineBreak as ManualLineBreak).lines, [
        'A',
        'BAB',
        'AB',
      ]);
      expect(
        () => TextAreaInput(
          areaId: 'a',
          sourceText: 'ABABAB',
          lineBreak: ManualLineBreak(['BAB', 'A', 'AB']),
        ),
        inputError(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
      );
    });
  });

  group('불변성과 원자적 교체', () {
    test('전달한 목록과 공개 목록에서 모델을 바꿀 수 없다', () {
      final lines = ['PUMP ', 'A'];
      final spec = ManualLineBreak(lines);
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
      expect(roundTrip(input).sourceText, 'PUMP A');
    });

    test('JSON 입출력 목록 변경도 모델에 영향을 주지 않는다', () {
      final lines = <Object?>['PU', 'MP'];
      final input = TextAreaInput.fromJson(manualJson(lines));
      lines[0] = 'OTHER';
      final json = input.toJson();
      final outputSpec = json['lineBreak'] as Map<String, Object?>;
      (outputSpec['lines'] as List<String>).clear();
      json['sourceText'] = 'OTHER';
      expect((input.lineBreak as ManualLineBreak).lines, ['PU', 'MP']);
      expect(roundTrip(input).sourceText, 'PUMP');
    });

    test('문구와 지정 줄을 함께 검증하고 원래 값을 보존한다', () {
      final original = TextAreaInput(
        areaId: 'a',
        sourceText: 'PUMP',
        lineBreak: ManualLineBreak(['PUMP']),
      );
      expect(
        () => TextAreaInput(
          areaId: original.areaId,
          sourceText: 'VALVE',
          lineBreak: original.lineBreak,
        ),
        inputError(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
      );
      final replacement = TextAreaInput(
        areaId: original.areaId,
        sourceText: 'VALVE',
        lineBreak: ManualLineBreak(['VAL', 'VE']),
      );
      expect(original.sourceText, 'PUMP');
      expect((original.lineBreak as ManualLineBreak).lines, ['PUMP']);
      expect(roundTrip(replacement).sourceText, 'VALVE');
    });
  });

  group('JSON 경계 오류', () {
    for (final field in ['areaId', 'sourceText', 'lineBreak']) {
      test('필수 누락: $field', () {
        final json = automaticJson()..remove(field);
        expect(
          () => TextAreaInput.fromJson(json),
          inputError(TextInputErrorCode.missingField, field),
        );
      });
      for (final value in <Object?>[null, 1, true, []]) {
        test('타입 오류: $field = $value', () {
          final json = automaticJson()..[field] = value;
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
          ...automaticJson(),
          'lineBreak': <String, Object?>{},
        }),
        inputError(TextInputErrorCode.missingField, 'lineBreak.mode'),
      );
    });
    for (final value in <Object?>[null, 1, [], {}]) {
      test('방식의 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson({
            ...automaticJson(),
            'lineBreak': {'mode': value},
          }),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.mode'),
        );
      });
    }
    for (final mode in ['', 'AUTO', 'manual ', 'unknown']) {
      test('모르는 방식: $mode', () {
        expect(
          () => TextAreaInput.fromJson({
            ...automaticJson(),
            'lineBreak': {'mode': mode},
          }),
          inputError(TextInputErrorCode.unknownMode, 'lineBreak.mode'),
        );
      });
    }
    test('직접 지정 줄 목록 누락', () {
      expect(
        () => TextAreaInput.fromJson({
          ...automaticJson(),
          'lineBreak': {'mode': 'manual'},
        }),
        inputError(TextInputErrorCode.missingField, 'lineBreak.lines'),
      );
    });
    for (final value in <Object?>[null, 'PUMP', 1, {}]) {
      test('줄 목록 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson(manualJson(value)),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.lines'),
        );
      });
    }
    for (final value in <Object?>[null, 1, true, []]) {
      test('줄 요소 타입 오류: $value', () {
        expect(
          () => TextAreaInput.fromJson(manualJson(['PU', value])),
          inputError(TextInputErrorCode.invalidType, 'lineBreak.lines[1]'),
        );
      });
    }
    test('모르는 필드나 자동 방식의 지정 줄을 버리지 않는다', () {
      expect(
        () => TextAreaInput.fromJson({...automaticJson(), 'extra': 1}),
        inputError(TextInputErrorCode.unexpectedField, 'extra'),
      );
      expect(
        () => TextAreaInput.fromJson({
          ...automaticJson(),
          'lineBreak': {
            'mode': 'auto',
            'lines': ['PUMP'],
          },
        }),
        inputError(TextInputErrorCode.unexpectedField, 'lineBreak.lines'),
      );
      expect(
        () => TextAreaInput.fromJson({
          ...automaticJson(),
          'lineBreak': {
            'mode': 'manual',
            'lines': ['PUMP'],
            'extra': 1,
          },
        }),
        inputError(TextInputErrorCode.unexpectedField, 'lineBreak.extra'),
      );
    });
  });

  group('이번 지원 범위와 값 검증', () {
    test('빈 ID를 원문으로 보정하지 않는다', () {
      expect(
        () => TextAreaInput(
          areaId: '',
          sourceText: 'PUMP',
          lineBreak: const AutoLineBreak(),
        ),
        inputError(TextInputErrorCode.emptyAreaId, 'areaId'),
      );
      expect(
        () => TextAreaInput.fromJson({...automaticJson(), 'areaId': ''}),
        inputError(TextInputErrorCode.emptyAreaId, 'areaId'),
      );
    });
    test('빈 원문은 미지원 원인으로 반환한다', () {
      expect(
        () => TextAreaInput(
          areaId: 'a',
          sourceText: '',
          lineBreak: const AutoLineBreak(),
        ),
        inputError(TextInputErrorCode.emptySourceText, 'sourceText'),
      );
      expect(
        () => TextAreaInput.fromJson({...automaticJson(), 'sourceText': ''}),
        inputError(TextInputErrorCode.emptySourceText, 'sourceText'),
      );
    });
    test('빈 줄 목록과 빈 줄을 구분한다', () {
      expect(
        () => ManualLineBreak([]),
        inputError(TextInputErrorCode.emptyManualLines, 'lineBreak.lines'),
      );
      expect(
        () => TextAreaInput.fromJson(manualJson([])),
        inputError(TextInputErrorCode.emptyManualLines, 'lineBreak.lines'),
      );
      expect(
        () => ManualLineBreak(['PU', '', 'MP']),
        inputError(TextInputErrorCode.emptyManualLine, 'lineBreak.lines[1]'),
      );
      expect(
        () => TextAreaInput.fromJson(manualJson(['PU', '', 'MP'])),
        inputError(TextInputErrorCode.emptyManualLine, 'lineBreak.lines[1]'),
      );
    });
    for (final ending in ['\r', '\n', '\r\n']) {
      test('원문과 줄 내 CR/LF의 원인을 구분한다: ${jsonEncode(ending)}', () {
        expect(
          () => TextAreaInput(
            areaId: 'a',
            sourceText: 'PU${ending}MP',
            lineBreak: const AutoLineBreak(),
          ),
          inputError(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
        );
        expect(
          () => TextAreaInput.fromJson({
            ...automaticJson(),
            'sourceText': 'PU${ending}MP',
          }),
          inputError(TextInputErrorCode.sourceContainsCrLf, 'sourceText'),
        );
        expect(
          () => ManualLineBreak(['PU', '${ending}MP']),
          inputError(
            TextInputErrorCode.manualLineContainsCrLf,
            'lineBreak.lines[1]',
          ),
        );
        expect(
          () => TextAreaInput.fromJson(manualJson(['PU', '${ending}MP'])),
          inputError(
            TextInputErrorCode.manualLineContainsCrLf,
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
          () => TextAreaInput.fromJson(manualJson(lines)),
          inputError(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines'),
        );
      });
    }
  });
}
