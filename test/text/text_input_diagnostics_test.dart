import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

void main() {
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
