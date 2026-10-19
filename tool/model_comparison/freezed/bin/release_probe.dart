import 'package:freezed_model_probe/naming_examples.dart' show namingExamples;

import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

import 'package:freezed_model_probe/model.dart';
import 'package:freezed_model_probe/usage.dart';

// assert에 의존하지 않는 AOT 실행 검사다.
void main() {
  var assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());
  if (assertsEnabled) throw StateError('assert 비활성 실행이 필요합니다');
  final original = create(' PUMP  A-1 e\u0301👩‍🔧 ', [
    ' PUMP ',
    ' A-1 e\u0301👩‍🔧 ',
  ]);
  final restored = TrialArea.fromJson(
    jsonDecode(jsonEncode(original.toJson())),
  );
  if (restored != original) throw StateError('왕복 손실');
  final next = replaceText(original, 'VALVE', ['VAL', 'VE']);
  if (next.sourceText != 'VALVE' ||
      original.sourceText != ' PUMP  A-1 e\u0301👩‍🔧 ') {
    throw StateError('교체/불변성 실패');
  }
  if (namingExamples().values.any((text) => text != 'VALVE')) {
    throw StateError('네이밍 예시 실행 실패');
  }
  final cases = <void Function()>[
    () => create('PUMP', ['pump']),
    () => changeOnlySource(original, 'VALVE'),
    () => changeOnlyLines(original, ['VALVE']),
    () => replaceText(original, 'VALVE', ['PUMP']),
    () => create('', null),
    () => create('PUMP', []),
    () => create('PUMP', ['']),
    () => create('PUMP\n', null),
    () => invalidNativeBreak(),
    () => TrialArea.fromJson({
      'areaId': 'a',
      'sourceText': 'PUMP',
      'lineBreak': {
        'mode': 'manual',
        'lines': ['pump'],
      },
    }),
    () => TrialArea.fromJson({
      'areaId': 'a',
      'sourceText': 'PUMP',
      'lineBreak': {},
    }),
  ];
  for (var i = 0; i < cases.length; i++) {
    var rejected = false;
    try {
      cases[i]();
    } on TextInputException {
      rejected = true;
    }
    if (!rejected) throw StateError('업무 검증 우회: $i');
  }
  print('AOT: assert 비활성, 원문/왕복/동시 교체 및 오류 ${cases.length}건 통과');
}
