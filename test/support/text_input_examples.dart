import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

Matcher inputError(TextInputErrorCode code, String fieldPath) => throwsA(
  isA<TextInputValidationException>()
      .having((error) => error.code, 'code', code)
      .having((error) => error.fieldPath, 'fieldPath', fieldPath),
);

Map<String, Object?> automaticTextInputJson() => {
  'areaId': 'area-1',
  'sourceText': 'PUMP',
  'lineBreak': {'mode': 'automatic'},
};

Map<String, Object?> specifiedTextInputJson(Object? lines) => {
  ...automaticTextInputJson(),
  'lineBreak': {'mode': 'specified', 'lines': lines},
};

TextAreaInput textInputThroughJsonString(TextAreaInput input) =>
    TextAreaInput.fromJson(jsonDecode(jsonEncode(input.toJson())));
