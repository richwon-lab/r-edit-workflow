import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart';

void main() {
  group('중첩 예외의 원인과 스택', () {
    test('기하 문맥 접두사는 최초 예외·상세·실패 스택을 유지한다', () {
      final original = GeometryValidationException(
        GeometryErrorCode.invalidType,
        'x',
        const GeometryDiagnostic(
          operation: 'readNumber',
          details: GeometryTypeDetails(
            expectedType: 'num',
            actualType: 'String',
          ),
        ),
      );
      final stack = StackTrace.fromString('original.failure');
      final contextual = original
          .prefixed('center', stackTrace: stack)
          .prefixed('outline', stackTrace: StackTrace.current);
      expect(contextual.fieldPath, 'outline.center.x');
      expect(contextual.cause, same(original));
      expect(contextual.causeStackTrace, same(stack));
      expect(contextual.diagnostic, same(original.diagnostic));
      expect(contextual.contextStackTrace, isNotNull);
    });
    test('제품 JSON의 하위 문구 오류는 상위 경로와 원래 코드·스택을 제공한다', () {
      try {
        ProductInput.fromJson({
          'productId': 'p',
          'appliedGeometryId': 'g',
          'textInputs': [
            {
              'areaId': 'a',
              'sourceText': 123,
              'lineBreak': {'mode': 'automatic'},
            },
          ],
        });
        fail('잘못된 제품 복원 허용');
      } on ProductDesignNestedException catch (error, stack) {
        expect(error.fieldPath, 'textInputs[0].sourceText');
        expect(error.cause, isA<TextInputValidationException>());
        final cause = error.cause as TextInputValidationException;
        expect(cause.fieldPath, 'sourceText');
        expect(cause.code, TextInputErrorCode.invalidType);
        expect(cause.details, isA<TextInputTypeDetails>());
        expect(error.causeStackTrace.toString(), contains('TextAreaInput'));
        expect(stack.toString(), error.causeStackTrace.toString());
        final next = error.prefixed('products[2]');
        expect(next.fieldPath, 'products[2].textInputs[0].sourceText');
        expect(next.cause, same(cause));
        expect(next.causeStackTrace, same(error.causeStackTrace));
      }
    });
    test('도안 JSON의 잘못된 타입은 부모 경로에서도 기대/실제 타입을 보존한다', () {
      final json = inchDesignWithIrregularOutline().toJson();
      json['textAreas'] = [
        {
          'areaId': 12,
          'label': '',
          'region': {
            'outer': circleCenteredAt2().toJson(),
            'exclusions': <Object?>[],
          },
        },
      ];
      try {
        DesignGeometry.fromJson(json);
        fail('잘못된 도안 복원 허용');
      } on DesignValidationException catch (error, stack) {
        expect(error.fieldPath, 'textAreas[0].areaId');
        expect(error.cause, isA<DesignValidationException>());
        final details = error.issue.details! as DesignTypeDetails;
        expect(details.expectedType, 'String');
        expect(details.actualType, 'int');
        expect(stack.toString(), error.causeStackTrace.toString());
      }
    });
  });
  group('오류 코드와 필수 상세의 일치', () {
    test('도안 타입 상세가 없으면 issue를 만들지 않는다', () {
      expect(
        () => DesignValidationIssue(
          code: DesignErrorCode.invalidType,
          fieldPath: 'label',
        ),
        throwsArgumentError,
      );
    });
    test('제품 타입 상세와 참조 오류를 조합하지 않는다', () {
      expect(
        () => ProductDesignIssue(
          code: ProductDesignErrorCode.unknownAppliedGeometryId,
          fieldPath: 'products[0].appliedGeometryId',
          details: const ProductDesignTypeDetails(
            expectedType: 'String',
            actualType: 'int',
          ),
        ),
        throwsArgumentError,
      );
    });
    test('기하 타입 상세가 없으면 예외를 만들지 않는다', () {
      expect(
        () => GeometryValidationException(
          GeometryErrorCode.invalidType,
          'x',
          const GeometryDiagnostic(operation: 'readNumber'),
        ),
        throwsArgumentError,
      );
    });
    test('제품 검증 예외의 빈 진단 목록을 거부한다', () {
      expect(() => ProductDesignValidationException([]), throwsArgumentError);
    });
    test('기하 미지원 태그는 실제 값과 방어 복사된 지원 목록을 제공한다', () {
      final supported = ['circle'];
      final details = GeometryTagDetails('spline', supportedValues: supported);
      supported.add('spline');
      expect(details.supportedValues, ['circle']);
      expect(
        () => details.supportedValues.add('spline'),
        throwsUnsupportedError,
      );
      expect(details.toString(), allOf(contains('spline'), contains('circle')));
    });
  });
}
