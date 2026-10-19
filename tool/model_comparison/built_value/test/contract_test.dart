import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart' as current;
import 'package:test/test.dart';

import 'package:built_value_model_probe/model.dart';
import 'package:built_value_model_probe/usage.dart';

Map<String, Object?> jsonFor(String text, [List<String>? lines]) => {
  'areaId': 'area-1',
  'sourceText': text,
  'lineBreak': lines == null
      ? {'mode': 'auto'}
      : {'mode': 'manual', 'lines': lines},
};
Object signature(void Function() action) {
  try {
    action();
  } on current.TextInputException catch (error) {
    return (error.code, error.path);
  }
  return '검증 오류 없음';
}

Matcher mismatch() => throwsA(
  isA<current.TextInputException>()
      .having(
        (e) => e.code,
        'code',
        current.TextInputErrorCode.manualTextMismatch,
      )
      .having((e) => e.path, 'path', 'lineBreak.lines'),
);

void main() {
  final samples = <String, List<String>>{
    ' PUMP  A-1 ': [' PUMP ', ' A-1 '],
    'Ø Φ × ± ℃ # / A-b': ['Ø Φ × ± ℃', ' # / A-b'],
    '리치원 명판': ['리치원 ', '명판'],
    '가\u1100\u1161 e\u0301 é': ['가', '\u1100\u1161 ', 'e\u0301 é'],
    '👩‍🔧😀🇰🇷': ['👩‍🔧', '😀', '🇰🇷'],
    'AA AA  AA': ['AA ', 'AA  ', 'AA'],
    '   ': [' ', '  '],
    '\t PUMP\t': ['\t ', 'PUMP\t'],
    'ABABAB': ['A', 'BAB', 'AB'],
  };
  for (final sample in samples.entries) {
    test('기존 사례 원문·방식·JSON 보존: ${sample.key}', () {
      for (final lines in <List<String>?>[
        null,
        [sample.key],
        sample.value,
      ]) {
        final value = create(sample.key, lines);
        final json = jsonDecode(jsonEncode(value.toJson()));
        expect(json, jsonFor(sample.key, lines));
        expect(TrialArea.fromJson(json), value);
        final oracle = current.TextAreaInput.fromJson(json);
        expect(oracle.sourceText, sample.key);
        expect(oracle.toJson(), json);
        expect(value.lineBreak.mode, lines == null ? 'auto' : 'manual');
        expect(value.lineBreak.lines?.toList(), lines);
      }
    });
  }
  test('원문과 줄을 함께 바꾸고 기존 값은 유지', () {
    final old = create('PUMP', ['PUMP']);
    final next = replaceText(old, 'VALVE', ['VAL', 'VE']);
    expect(next.sourceText, 'VALVE');
    expect(next.lineBreak.lines!.toList(), ['VAL', 'VE']);
    expect(old.toJson(), jsonFor('PUMP', ['PUMP']));
    expect(() => changeOnlySource(old, 'VALVE'), mismatch());
    expect(() => changeOnlyLines(old, ['VALVE']), mismatch());
    expect(() => replaceText(old, 'VALVE', ['PUMP']), mismatch());
  });
  test('생성 경로와 직접 생성 도구 API도 검증', () {
    expect(() => create('PUMP', ['pump']), mismatch());
    expect(signature(() => invalidNativeBreak()), (
      current.TextInputErrorCode.unknownMode,
      'lineBreak.mode',
    ));
    expect(signature(() => replaceLines(TrialBreak.manual(['PUMP']), [''])), (
      current.TextInputErrorCode.emptyManualLine,
      'lineBreak.lines[0]',
    ));
  });
  test('외부 목록·기존 값·JSON 출력으로 원문을 바꾸지 못함', () {
    final lines = ['PU', 'MP'];
    final old = create('PUMP', lines);
    lines.clear();
    expect(old.lineBreak.lines!.toList(), ['PU', 'MP']);
    final nextLines = ['VAL', 'VE'];
    final next = replaceText(old, 'VALVE', nextLines);
    nextLines.clear();
    expect(next.lineBreak.lines!.toList(), ['VAL', 'VE']);
    expect(old.lineBreak.lines!.toList(), ['PU', 'MP']);
    final output = old.toJson();
    final spec = output['lineBreak'] as Map;
    try {
      (spec['lines'] as List).clear();
    } on UnsupportedError {
      /* 수정 불가 출력도 허용 */
    }
    expect(old.toJson(), jsonFor('PUMP', ['PU', 'MP']));
  });
  test('직접 지정 한 줄과 자동 값은 다름', () {
    expect(create('PUMP', null), isNot(create('PUMP', ['PUMP'])));
    expect(create('é', null), isNot(create('e\u0301', null)));
  });

  final invalid = <Object?>[
    null,
    [],
    1,
    'text',
    {1: 'value'},
    for (final key in ['areaId', 'sourceText', 'lineBreak'])
      Map<String, Object?>.from(jsonFor('PUMP'))..remove(key),
    for (final key in ['areaId', 'sourceText', 'lineBreak'])
      for (final value in <Object?>[null, 1, true, []])
        {...jsonFor('PUMP'), key: value},
    {...jsonFor('PUMP'), 'areaId': ''},
    {...jsonFor('PUMP'), 'sourceText': ''},
    for (final ending in ['\r', '\n', '\r\n']) jsonFor('PU${ending}MP'),
    for (final spec in <Object?>[
      {},
      {'mode': null},
      {'mode': 1},
      {'mode': []},
      {'mode': {}},
      {'mode': ''},
      {'mode': 'AUTO'},
      {'mode': 'manual '},
      {'mode': 'unknown'},
      {'mode': 'manual'},
      for (final value in <Object?>[null, 'PUMP', 1, {}])
        {'mode': 'manual', 'lines': value},
      for (final value in <Object?>[null, 1, true, []])
        {
          'mode': 'manual',
          'lines': ['PU', value],
        },
      {
        'mode': 'auto',
        'lines': ['PUMP'],
      },
      {
        'mode': 'manual',
        'lines': ['PUMP'],
        'extra': 1,
      },
    ])
      {...jsonFor('PUMP'), 'lineBreak': spec},
    {...jsonFor('PUMP'), 'extra': 1},
    for (final lines in <List<String>>[
      [],
      [''],
      ['PU', '', 'MP'],
      ['pump'],
      ['PUMP '],
      ['P', 'UM'],
      ['MP', 'PU'],
      ['PU', ' MP'],
      ['PU', '\rMP'],
      ['PU', '\nMP'],
      ['PU', '\r\nMP'],
    ])
      jsonFor('PUMP', lines),
  ];
  for (var i = 0; i < invalid.length; i++) {
    test('기존 오류 code/path 대조 $i', () {
      final expected = signature(
        () => current.TextAreaInput.fromJson(invalid[i]),
      );
      expect(expected, isNot('검증 오류 없음'));
      expect(signature(() => TrialArea.fromJson(invalid[i])), expected);
    });
  }
}
