import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

void main() {
  _existingDiagnosticContracts();
  group('문구 입력 실패의 구조화 진단', () {
    test('타입 오류는 원문 대신 기대/실제 타입을 제공한다', () {
      try {
        TextAreaInput.fromJson({
          'areaId': 'a',
          'sourceText': 123,
          'lineBreak': {'mode': 'automatic'},
        });
        fail('타입 오류 허용');
      } on TextInputValidationException catch (error) {
        expect(error.code, TextInputErrorCode.invalidType);
        expect(error.fieldPath, 'sourceText');
        final details = error.details! as TextInputTypeDetails;
        expect(details.expectedType, 'String');
        expect(details.actualType, 'int');
        expect(
          error.toString(),
          allOf(
            contains('sourceText'),
            contains(error.code.description),
            contains('actualType=int'),
          ),
        );
      }
    });
    test('알 수 없는 방식은 실제 값과 수정 불가 지원 목록을 제공한다', () {
      try {
        LineBreakInput.fromJson({'mode': 'auto'});
        fail('지원하지 않는 방식 허용');
      } on TextInputValidationException catch (error) {
        final details = error.details! as TextInputModeDetails;
        expect(details.actualValue, 'auto');
        expect(details.supportedValues, ['automatic', 'specified']);
        expect(
          () => details.supportedValues.add('auto'),
          throwsUnsupportedError,
        );
      }
    });
    test('줄 불일치 상세는 내용 대신 길이와 줄 수만 보존한다', () {
      try {
        TextAreaInput(
          areaId: 'a',
          sourceText: '비공개',
          lineBreak: SpecifiedLineBreak(['다름']),
        );
        fail('불일치 허용');
      } on TextInputValidationException catch (error) {
        final details = error.details! as TextInputMismatchDetails;
        expect(details.sourceLength, 3);
        expect(details.specifiedLength, 2);
        expect(details.lineCount, 1);
        expect(error.toString(), isNot(contains('비공개')));
        expect(error.toString(), isNot(contains('다름')));
      }
    });
    test('CR/LF 상세는 해당 문자열의 UTF-16 위치와 코드 단위를 제공한다', () {
      try {
        TextAreaInput(
          areaId: 'a',
          sourceText: '😀\nA',
          lineBreak: const AutomaticLineBreak(),
        );
        fail('LF 허용');
      } on TextInputValidationException catch (error) {
        final details = error.details! as TextInputCharacterDetails;
        expect(details.codeUnitIndex, 2);
        expect(details.codeUnit, 10);
      }
    });
    for (final (name, build) in <(String, void Function())>[
      (
        '타입 상세 누락',
        () => TextInputValidationException(
          TextInputErrorCode.invalidType,
          'sourceText',
        ),
      ),
      (
        '다른 코드의 타입 상세',
        () => TextInputValidationException(
          TextInputErrorCode.emptySourceText,
          'sourceText',
          details: const TextInputTypeDetails(
            expectedType: 'String',
            actualType: 'int',
          ),
        ),
      ),
      (
        '지원하는 방식을 미지원으로 보고',
        () => TextInputValidationException(
          TextInputErrorCode.unknownLineBreakMode,
          'lineBreak.mode',
          details: const TextInputModeDetails('automatic'),
        ),
      ),
      (
        'CR/LF가 아닌 코드 단위',
        () => TextInputValidationException(
          TextInputErrorCode.sourceContainsCrLf,
          'sourceText',
          details: const TextInputCharacterDetails(
            codeUnitIndex: 0,
            codeUnit: 65,
          ),
        ),
      ),
    ]) {
      test('$name 조합은 입력 거부가 아닌 호출 코드 결함으로 거부한다', () {
        expect(build, throwsArgumentError);
      });
    }
  });
}

void _existingDiagnosticContracts() {
  group('문구 입력 오류의 개발자 출력', () {
    test('JSON 타입 오류의 코드·상대 경로·한국어 원인을 제공한다', () {
      try {
        TextAreaInput.fromJson({
          'areaId': 42,
          'sourceText': 'PUMP',
          'lineBreak': {'mode': 'automatic'},
        });
        fail('타입 오류 수락');
      } on TextInputValidationException catch (error) {
        expect(error.code, TextInputErrorCode.invalidType);
        expect(error.fieldPath, 'areaId');
        expect(
          error.toString(),
          allOf(
            contains('code=invalidType'),
            contains('fieldPath=areaId'),
            contains('문구 입력의 JSON 값 타입이 기대 타입과 다릅니다.'),
          ),
        );
      }
    });

    test('지정 줄의 빈 항목은 인덱스와 현재 지원 제한 설명을 제공한다', () {
      try {
        SpecifiedLineBreak(['A', '']);
        fail('빈 줄 수락');
      } on TextInputValidationException catch (error) {
        expect(
          error.toString(),
          allOf(
            contains('code=emptySpecifiedLine'),
            contains('fieldPath=lineBreak.lines[1]'),
            contains('현재 입력 모델은 빈 지정 줄을 지원하지 않습니다.'),
          ),
        );
      }
    });
  });
}
