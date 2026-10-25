import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  group('제품 구성 JSON 경계와 원인 보존', () {
    final parsers = <(String, Map<String, Object?>, Object Function(Object?))>[
      (
        'AppliedDesignGeometry',
        {'appliedGeometryId': 'g', 'geometry': expectedTitleGeometryJson()},
        AppliedDesignGeometry.fromJson,
      ),
      (
        'DesignSourceReference',
        {'sourceDesignId': 's'},
        DesignSourceReference.fromJson,
      ),
      (
        'ProductInput',
        {'productId': 'p', 'appliedGeometryId': 'g', 'textInputs': []},
        ProductInput.fromJson,
      ),
      (
        'ProductDesignConfiguration',
        {'appliedGeometries': [], 'products': []},
        ProductDesignConfiguration.fromJson,
      ),
    ];
    for (final (name, json, parse) in parsers) {
      test('$name 최상위가 문자열이면 객체 타입 오류를 반환한다', () {
        expect(
          () => parse('value'),
          productFailure(ProductDesignErrorCode.invalidType, r'$'),
        );
      });
      test('$name 알 수 없는 추가 필드를 버리지 않는다', () {
        expect(
          () => parse({...json, 'unknown': false}),
          productFailure(ProductDesignErrorCode.unexpectedField, 'unknown'),
        );
      });
    }
    for (final field in ['appliedGeometryId', 'geometry']) {
      test('적용 형상의 필수 $field 누락을 보정하지 않는다', () {
        final json = {
          'appliedGeometryId': 'g',
          'geometry': expectedTitleGeometryJson(),
        }..remove(field);
        expect(
          () => AppliedDesignGeometry.fromJson(json),
          productFailure(ProductDesignErrorCode.missingField, field),
        );
      });
    }
    test('빈 ID로 복원한 적용 형상을 거부한다', () {
      expect(
        () => AppliedDesignGeometry.fromJson({
          'appliedGeometryId': '',
          'geometry': expectedTitleGeometryJson(),
        }),
        productFailure(
          ProductDesignErrorCode.emptyAppliedGeometryId,
          'appliedGeometryId',
        ),
      );
    });
    test('제품 구성 중첩 타입 오류는 상세 객체를 보존해 접두사를 붙인다', () {
      try {
        ProductDesignConfiguration.fromJson({
          'appliedGeometries': [
            {
              'appliedGeometryId': 'g',
              'geometry': expectedTitleGeometryJson(),
              'source': {'sourceDesignId': false},
            },
          ],
          'products': [],
        });
        fail('타입 오류 허용');
      } on ProductDesignValidationException catch (e) {
        final issue = e.issues.single;
        expect(issue.code, ProductDesignErrorCode.invalidType);
        expect(issue.fieldPath, 'appliedGeometries[0].source.sourceDesignId');
        final details = issue.details as ProductDesignTypeDetails;
        expect(details.expectedType, 'String');
        expect(details.actualType, 'bool');
        expect(
          identical(e.prefixed('configuration').issues.single.details, details),
          isTrue,
        );
        expect(
          e.toString(),
          allOf(
            contains('invalidType'),
            contains(issue.fieldPath),
            contains('expectedType=String'),
            contains('actualType=bool'),
            contains('기대 타입'),
          ),
        );
      }
    });
    test('중첩 도안 정의 오류도 원래 ID와 상세를 유지한다', () {
      final geometry = expectedTitleGeometryJson();
      ((geometry['textAreas'] as List).single as Map)['areaId'] = '';
      try {
        ProductDesignConfiguration.fromJson({
          'appliedGeometries': [
            {'appliedGeometryId': 'g', 'geometry': geometry},
          ],
          'products': [],
        });
        fail('빈 영역 ID 허용');
      } on ProductDesignNestedException catch (e) {
        expect(
          e.fieldPath,
          'appliedGeometries[0].geometry.textAreas[0].areaId',
        );
        final cause = e.cause as DesignValidationException;
        expect(cause.code, DesignErrorCode.emptyAreaId);
        expect((cause.issue.details as DesignIdentifierDetails).identifier, '');
        expect(identical(e.prefixed('configuration').cause, cause), isTrue);
      }
    });
    test('예외에 전달한 issue 목록을 나중에 변경해도 진단이 유지된다', () {
      const issue = ProductDesignIssue(
        code: ProductDesignErrorCode.emptyProductId,
        fieldPath: 'productId',
        details: ProductDesignIdentifierDetails(''),
      );
      final list = [issue];
      final error = ProductDesignValidationException(list);
      list.clear();
      expect(error.issues.single, issue);
      expect(() => error.issues.clear(), throwsUnsupportedError);
    });
    test('구성의 영역 진단에 하위 상세와 두 ID를 모두 출력한다', () {
      final issues = validateProductDesignConfiguration(
        appliedGeometries: [
          appliedMillimeterDesign('g', ['title']),
        ],
        products: [
          ProductInput(productId: 'p', appliedGeometryId: 'g', textInputs: []),
        ],
      );
      expect(
        issues.single.toString(),
        allOf(
          contains('productId=p'),
          contains('appliedGeometryId=g'),
          contains('missingAreaInput'),
          contains('id="title"'),
          contains('geometry.textAreas[0].areaId'),
        ),
      );
    });
  });
}
