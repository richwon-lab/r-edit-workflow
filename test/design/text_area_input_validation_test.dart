import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart'
    show
        textAreaWithCircularRegion,
        inchDesignWithIrregularOutline,
        textInputForArea;

void main() {
  group('validateTextAreaInputs의 정확한 ID 대응', () {
    {
      test('공백 areaId는 trim하지 않고 정확히 연결한다', () {
        expect(
          validateTextAreaInputs(
            design: inchDesignWithIrregularOutline(
              areas: [textAreaWithCircularRegion('   ')],
            ),
            inputs: [textInputForArea('   ')],
          ),
          isEmpty,
        );
      });
    }

    {
      test('입력 순서가 달라도 ID로 연결하고 원문·지정 한 줄·공백과 순서를 보존한다', () {
        final current = inchDesignWithIrregularOutline(
          areas: [
            textAreaWithCircularRegion('a'),
            textAreaWithCircularRegion('b'),
          ],
        );
        final first = textInputForArea(
          'b',
          text: '  PUMP e\u0301 👩‍🔧  ',
          specified: true,
        );
        final second = textInputForArea('a', text: '   ');
        final inputs = [first, second];
        expect(
          validateTextAreaInputs(design: current, inputs: inputs),
          isEmpty,
        );
        expect(identical(inputs.first, first), isTrue);
        expect(inputs.map((i) => i.areaId), ['b', 'a']);
        expect((first.lineBreak as SpecifiedLineBreak).lines, [
          '  PUMP e\u0301 👩‍🔧  ',
        ]);
        expect(second.sourceText, '   ');
      });
    }

    {
      test('동시 발생한 중복·미정의·누락의 코드·경로·상세를 순서와 무관하게 제공한다', () {
        final current = inchDesignWithIrregularOutline(
          areas: [
            textAreaWithCircularRegion('a'),
            textAreaWithCircularRegion('b'),
          ],
        );
        final inputs = [
          textInputForArea('a'),
          textInputForArea('a', specified: true),
          textInputForArea('unknown'),
        ];
        final issues = validateTextAreaInputs(design: current, inputs: inputs);
        DesignValidationIssue issueFor(DesignErrorCode code) =>
            issues.singleWhere((issue) => issue.code == code);
        expect(
          issues.map((i) => i.code),
          unorderedEquals([
            DesignErrorCode.duplicateInputAreaId,
            DesignErrorCode.unknownInputAreaId,
            DesignErrorCode.missingAreaInput,
          ]),
        );
        expect(
          issueFor(DesignErrorCode.duplicateInputAreaId).fieldPath,
          'inputs[1].areaId',
        );
        expect(
          issueFor(DesignErrorCode.unknownInputAreaId).fieldPath,
          'inputs[2].areaId',
        );
        expect(
          issueFor(DesignErrorCode.missingAreaInput).fieldPath,
          'textAreas[1].areaId',
        );
        final duplicate =
            issueFor(DesignErrorCode.duplicateInputAreaId).details
                as DesignDuplicateDetails;
        expect(duplicate.identifier, 'a');
        expect(duplicate.firstIndex, 0);
        expect(duplicate.duplicateIndex, 1);
        expect(
          (issueFor(DesignErrorCode.unknownInputAreaId).details
                  as DesignIdentifierDetails)
              .identifier,
          'unknown',
        );
        expect(
          (issueFor(DesignErrorCode.missingAreaInput).details
                  as DesignIdentifierDetails)
              .identifier,
          'b',
        );
        expect(() => issues.clear(), throwsUnsupportedError);
        expect(inputs, hasLength(3));
        expect(
          issueFor(DesignErrorCode.unknownInputAreaId).toString(),
          allOf(
            contains('unknown'),
            contains('inputs[2].areaId'),
            contains(DesignErrorCode.unknownInputAreaId.description),
          ),
        );
      });
    }

    {
      test('영역·입력 모두 없으면 연결 오류가 없다', () {
        expect(
          validateTextAreaInputs(
            design: inchDesignWithIrregularOutline(),
            inputs: [],
          ),
          isEmpty,
        );
      });
    }

    {
      test('영역 없는 도안에 입력하면 미정의 오류를 반환한다', () {
        expect(
          validateTextAreaInputs(
            design: inchDesignWithIrregularOutline(),
            inputs: [textInputForArea('x')],
          ).single.code,
          DesignErrorCode.unknownInputAreaId,
        );
      });
    }

    {
      test('영역에 입력이 없으면 누락 오류를 반환한다', () {
        expect(
          validateTextAreaInputs(
            design: inchDesignWithIrregularOutline(
              areas: [textAreaWithCircularRegion('x')],
            ),
            inputs: [],
          ).single.code,
          DesignErrorCode.missingAreaInput,
        );
      });
    }
  });
}
