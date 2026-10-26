import 'dart:io';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 실행에서 진단 구성의 런타임 검사를 확인한다.
void main() {
  var rejected = false;
  try {
    TextInputValidationException(TextInputErrorCode.invalidType, 'sourceText');
    // AOT 검사에서 호출 코드 결함이 실제로 거부되는지만 검증한다.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    rejected = true;
  }
  if (!rejected) throw StateError('필수 타입 진단 누락이 허용됨');
  try {
    ProductInput.fromJson({
      'productId': 'p',
      'appliedGeometryId': 'g',
      'textInputs': [
        {
          'areaId': 'a',
          'sourceText': 1,
          'lineBreak': {'mode': 'automatic'},
        },
      ],
    });
  } on ProductDesignNestedException catch (error, stack) {
    if (error.cause is! TextInputValidationException ||
        error.fieldPath != 'textInputs[0].sourceText' ||
        stack.toString() != error.causeStackTrace.toString()) {
      throw StateError('중첩 실패 진단/스택 손실');
    }
    stdout.writeln('AOT 진단 필수 값·중첩 원인·스택 보존 확인');
    return;
  }
  throw StateError('잘못된 입력을 복원함');
}
