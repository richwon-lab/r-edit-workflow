import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

ProductInput _product(
  String id,
  String appliedId,
  List<TextAreaInput> inputs,
) => ProductInput(
  productId: id,
  appliedGeometryId: appliedId,
  textInputs: inputs,
);

void main() {
  group('ProductDesignConfiguration의 공유와 유효 참조', () {
    test('두 제품은 같은 형상을 공유하고 원문·줄바꿈은 독립적으로 보존한다', () {
      final applied = appliedMillimeterDesign('g', ['title']);
      final a = _product('a', 'g', [automaticAreaText('title', 'PUMP')]);
      final b = _product('b', 'g', [
        TextAreaInput(
          areaId: 'title',
          sourceText: 'VALVE ',
          lineBreak: SpecifiedLineBreak(['VALVE ']),
        ),
      ]);
      final value = ProductDesignConfiguration(
        appliedGeometries: [applied],
        products: [a, b],
      );
      final changedA = a.copyWith(
        textInputs: [automaticAreaText('title', 'OTHER')],
      );
      final changed = value.copyWith(products: [changedA, b]);
      expect(identical(value.appliedGeometries.single, applied), isTrue);
      expect(changed.appliedGeometries, value.appliedGeometries);
      expect(value.products.first.textInputs.single.sourceText, 'PUMP');
      expect(changed.products.last.textInputs.single.sourceText, 'VALVE ');
      expect(
        changed.products.last.textInputs.single.lineBreak,
        isA<SpecifiedLineBreak>(),
      );
    });
    test('같은 문구 제품도 productId가 다르면 별도로 보존한다', () {
      final value = ProductDesignConfiguration(
        appliedGeometries: [
          appliedMillimeterDesign('g', ['title']),
        ],
        products: [
          for (final id in ['b', 'a'])
            _product(id, 'g', [automaticAreaText('title', 'SAME')]),
        ],
      );
      expect(value.products.map((p) => p.productId), ['b', 'a']);
    });
    test('제품 ID와 적용 ID의 같은 문자열은 충돌이 아니다', () {
      expect(
        ProductDesignConfiguration(
          appliedGeometries: [appliedMillimeterDesign('same', [])],
          products: [_product('same', 'same', [])],
        ).products.single.productId,
        'same',
      );
    });
    test('여러 적용 도안은 선택한 참조의 영역 정의만 대조한다', () {
      final value = ProductDesignConfiguration(
        appliedGeometries: [
          appliedMillimeterDesign('g-b', ['b']),
          appliedMillimeterDesign('g-a', ['a']),
        ],
        products: [
          _product('p', 'g-a', [automaticAreaText('a', 'A')]),
        ],
      );
      expect(value.appliedGeometries.map((g) => g.appliedGeometryId), [
        'g-b',
        'g-a',
      ]);
    });
    test('영역 입력 순서가 달라도 ID로 연결하고 전달 순서를 유지한다', () {
      final value = ProductDesignConfiguration(
        appliedGeometries: [
          appliedMillimeterDesign('g', ['a', 'b']),
        ],
        products: [
          _product('p', 'g', [
            automaticAreaText('b', 'B'),
            automaticAreaText('a', 'A'),
          ]),
        ],
      );
      expect(value.products.single.textInputs.map((i) => i.areaId), ['b', 'a']);
    });
    test('빈 구성과 미사용 적용 스냅샷을 허용한다', () {
      expect(
        ProductDesignConfiguration(
          appliedGeometries: [],
          products: [],
        ).products,
        isEmpty,
      );
      final value = ProductDesignConfiguration(
        appliedGeometries: [appliedMillimeterDesign('unused', [])],
        products: [],
      );
      expect(value.appliedGeometries, hasLength(1));
    });
    test('공용 원본이 없어도 실제 형상·영역이 포함된 고정 JSON을 해석한다', () {
      final expected = <String, Object?>{
        'appliedGeometries': [
          {
            'appliedGeometryId': 'g',
            'geometry': expectedTitleGeometryJson(),
            'source': {'sourceDesignId': 'unavailable-source'},
          },
        ],
        'products': [
          {
            'productId': 'p',
            'appliedGeometryId': 'g',
            'textInputs': [
              {
                'areaId': 'title',
                'sourceText': ' A e\u0301 👩‍🔧 ',
                'lineBreak': {
                  'mode': 'specified',
                  'lines': [' A e\u0301 👩‍🔧 '],
                },
              },
            ],
          },
        ],
      };
      final value = ProductDesignConfiguration.fromJson(
        jsonDecode(jsonEncode(expected)),
      );
      expect(value.toJson(), expected);
      expect(
        (value.appliedGeometries.single.geometry.outline as CircleBoundary)
            .radius,
        30,
      );
      expect(
        value.products.single.textInputs.single.sourceText,
        ' A e\u0301 👩‍🔧 ',
      );
      expect(ProductDesignConfiguration.fromJson(value.toJson()), value);
      expect(
        ProductDesignConfiguration.fromJson(value.toJson()).hashCode,
        value.hashCode,
      );
    });
    test('입력·공개 목록과 중첩 반환 JSON 변경으로 원래 구성은 바뀌지 않는다', () {
      final applied = [
        appliedMillimeterDesign('g', ['title']),
      ];
      final inputs = [automaticAreaText('title', 'PUMP')];
      final products = [_product('p', 'g', inputs)];
      final value = ProductDesignConfiguration(
        appliedGeometries: applied,
        products: products,
      );
      applied.clear();
      inputs.clear();
      products.clear();
      expect(value.appliedGeometries, hasLength(1));
      expect(value.products.single.textInputs.single.sourceText, 'PUMP');
      expect(() => value.products.clear(), throwsUnsupportedError);
      expect(() => value.appliedGeometries.clear(), throwsUnsupportedError);
      final replacements = [
        _product('p2', 'g', [automaticAreaText('title', 'VALVE')]),
      ];
      final changed = value.copyWith(products: replacements);
      replacements.clear();
      final json = value.toJson();
      final restored = ProductDesignConfiguration.fromJson(json);
      final snapshot = (json['appliedGeometries'] as List).single as Map;
      ((snapshot['geometry'] as Map)['textAreas'] as List).clear();
      final outputProduct = (json['products'] as List).single as Map;
      (outputProduct['textInputs'] as List).clear();
      (json['products'] as List).clear();
      expect(restored, value);
      expect(changed.products.single.productId, 'p2');
      expect(value.products.single.productId, 'p');
    });
  });

  group('ProductDesignConfiguration의 독립 오류 수집', () {
    for (final sameContent in [false, true]) {
      test('내용 동일=$sameContent여도 같은 적용 ID의 선언 중복을 거부한다', () {
        final g = appliedMillimeterDesign('g', ['title']);
        final other = sameContent ? g : appliedMillimeterDesign('g', ['other']);
        expect(
          () => ProductDesignConfiguration(
            appliedGeometries: [g, other],
            products: [],
          ),
          productFailure(
            ProductDesignErrorCode.duplicateAppliedGeometryId,
            'appliedGeometries[1].appliedGeometryId',
          ),
        );
      });
    }
    test('같은 제품 ID 중복을 적용 ID 중복과 구분한다', () {
      final product = _product('p', 'g', []);
      expect(
        () => ProductDesignConfiguration(
          appliedGeometries: [appliedMillimeterDesign('g', [])],
          products: [product, product],
        ),
        productFailure(
          ProductDesignErrorCode.duplicateProductId,
          'products[1].productId',
        ),
      );
    });
    for (final route in ['생성', '수정', '복원']) {
      test('$route에서도 없는 적용 참조를 거부하고 기존 구성은 유지한다', () {
        final valid = ProductDesignConfiguration(
          appliedGeometries: [
            appliedMillimeterDesign('g', ['title']),
          ],
          products: [
            _product('p', 'g', [automaticAreaText('title', 'PUMP')]),
          ],
        );
        final invalid = _product(
          'p',
          'missing',
          valid.products.single.textInputs,
        );
        expect(
          () => switch (route) {
            '생성' => ProductDesignConfiguration(
              appliedGeometries: valid.appliedGeometries,
              products: [invalid],
            ),
            '수정' => valid.copyWith(products: [invalid]),
            _ => ProductDesignConfiguration.fromJson({
              ...valid.toJson(),
              'products': [invalid.toJson()],
            }),
          },
          productFailure(
            ProductDesignErrorCode.unknownAppliedGeometryId,
            'products[0].appliedGeometryId',
          ),
        );
        expect(valid.products.single.appliedGeometryId, 'g');
      });
    }
    test('적용 목록을 지우는 구성 수정도 고아 참조를 만들지 않는다', () {
      final value = ProductDesignConfiguration(
        appliedGeometries: [appliedMillimeterDesign('g', [])],
        products: [_product('p', 'g', [])],
      );
      expect(
        () => value.copyWith(appliedGeometries: []),
        productFailure(
          ProductDesignErrorCode.unknownAppliedGeometryId,
          'products[0].appliedGeometryId',
        ),
      );
    });
    test('여러 제품의 중복·미정의·누락 오류를 순서와 무관하게 함께 제공한다', () {
      final applied = [
        appliedMillimeterDesign('g', ['a', 'b']),
      ];
      final products = [
        _product('p', 'g', [
          automaticAreaText('a', 'A'),
          automaticAreaText('a', 'B'),
          automaticAreaText('unknown', 'C'),
        ]),
        _product('p', 'missing', []),
      ];
      final issues = validateProductDesignConfiguration(
        appliedGeometries: applied,
        products: products,
      );
      expect(
        issues.map((i) => i.code),
        unorderedEquals([
          ProductDesignErrorCode.textAreaInputMismatch,
          ProductDesignErrorCode.textAreaInputMismatch,
          ProductDesignErrorCode.textAreaInputMismatch,
          ProductDesignErrorCode.duplicateProductId,
          ProductDesignErrorCode.unknownAppliedGeometryId,
        ]),
      );
      final areaDetails = issues.where(
        (i) => i.details is ProductDesignAreaDetails,
      );
      expect(
        areaDetails.map(
          (i) => (i.details as ProductDesignAreaDetails).cause.code,
        ),
        unorderedEquals([
          DesignErrorCode.duplicateInputAreaId,
          DesignErrorCode.unknownInputAreaId,
          DesignErrorCode.missingAreaInput,
        ]),
      );
      for (final issue in areaDetails) {
        final details = issue.details as ProductDesignAreaDetails;
        expect(details.productId, 'p');
        expect(details.appliedGeometryId, 'g');
        switch (details.cause.code) {
          case DesignErrorCode.duplicateInputAreaId:
            expect(issue.fieldPath, 'products[0].textInputs[1].areaId');
            expect(details.cause.fieldPath, 'inputs[1].areaId');
            final duplicate = details.cause.details as DesignDuplicateDetails;
            expect(duplicate.identifier, 'a');
            expect(duplicate.firstIndex, 0);
            expect(duplicate.duplicateIndex, 1);
          case DesignErrorCode.unknownInputAreaId:
            expect(issue.fieldPath, 'products[0].textInputs[2].areaId');
          case DesignErrorCode.missingAreaInput:
            expect(
              issue.fieldPath,
              'appliedGeometries[0].geometry.textAreas[1].areaId',
            );
            expect(details.cause.fieldPath, 'textAreas[1].areaId');
            expect(
              (details.cause.details as DesignIdentifierDetails).identifier,
              'b',
            );
          default:
            fail('예상하지 않은 원인');
        }
      }
      expect(() => issues.clear(), throwsUnsupportedError);
      try {
        ProductDesignConfiguration(
          appliedGeometries: applied,
          products: products,
        );
        fail('오류 구성을 수락함');
      } on ProductDesignValidationException catch (e) {
        expect(
          e.issues.map((i) => i.fieldPath),
          unorderedEquals(issues.map((i) => i.fieldPath)),
        );
        expect(() => e.issues.clear(), throwsUnsupportedError);
        expect(
          e.toString(),
          allOf(
            contains('제품 ID'),
            contains('productId=p'),
            contains('missingAreaInput'),
            contains('appliedGeometries[0].geometry.textAreas[1].areaId'),
          ),
        );
      }
    });
    for (final unresolved in ['없는 참조', '모호한 참조']) {
      test('$unresolved에서는 영역 대조 없이 중복 입력과 다른 제품 오류를 수집한다', () {
        final applied = unresolved == '없는 참조'
            ? <AppliedDesignGeometry>[]
            : [
                appliedMillimeterDesign('g', ['a']),
                appliedMillimeterDesign('g', ['different']),
              ];
        applied.add(appliedMillimeterDesign('unique', ['needed']));
        final products = [
          _product('bad', 'g', [
            automaticAreaText('x', 'A'),
            automaticAreaText('x', 'B'),
          ]),
          _product('other', 'unique', []),
        ];
        final issues = validateProductDesignConfiguration(
          appliedGeometries: applied,
          products: products,
        );
        final badArea = issues.where(
          (i) =>
              i.details is ProductDesignAreaDetails &&
              (i.details as ProductDesignAreaDetails).productId == 'bad',
        );
        expect(badArea, hasLength(1));
        expect(
          (badArea.single.details as ProductDesignAreaDetails).cause.code,
          DesignErrorCode.duplicateInputAreaId,
        );
        final reference = issues.singleWhere(
          (i) =>
              i.code ==
              (unresolved == '없는 참조'
                  ? ProductDesignErrorCode.unknownAppliedGeometryId
                  : ProductDesignErrorCode.ambiguousAppliedGeometryId),
        );
        final detail = reference.details as ProductDesignReferenceDetails;
        expect(detail.productId, 'bad');
        expect(detail.appliedGeometryId, 'g');
        expect(
          detail.matchingIndices,
          unresolved == '없는 참조' ? <Object?>[] : [0, 1],
        );
        expect(() => detail.matchingIndices.clear(), throwsUnsupportedError);
        expect(
          issues.where(
            (i) =>
                i.details is ProductDesignAreaDetails &&
                (i.details as ProductDesignAreaDetails).productId == 'other',
          ),
          hasLength(1),
        );
      });
    }
    for (final field in ['appliedGeometries', 'products']) {
      for (final value in [null, true, 0, <String, Object?>{}]) {
        test('$field=$value의 JSON 타입 오류를 거부한다', () {
          expect(
            () => ProductDesignConfiguration.fromJson({
              'appliedGeometries': <Object?>[],
              'products': <Object?>[],
              field: value,
            }),
            productFailure(ProductDesignErrorCode.invalidType, field),
          );
        });
      }
      test('필수 $field를 생략하면 빈 목록으로 채우지 않는다', () {
        final json = {'appliedGeometries': <Object?>[], 'products': <Object?>[]}
          ..remove(field);
        expect(
          () => ProductDesignConfiguration.fromJson(json),
          productFailure(ProductDesignErrorCode.missingField, field),
        );
      });
    }
    test('중첩 원문 예외는 원래 원인과 최상위 제품 위치를 보존한다', () {
      try {
        ProductDesignConfiguration.fromJson({
          'appliedGeometries': <Object?>[],
          'products': [
            {
              'productId': 'p',
              'appliedGeometryId': 'g',
              'textInputs': [
                {
                  'areaId': 'title',
                  'sourceText': '',
                  'lineBreak': {'mode': 'automatic'},
                },
              ],
            },
          ],
        });
        fail('빈 원문 복원 수락');
      } on ProductDesignNestedException catch (e) {
        expect(e.fieldPath, 'products[0].textInputs[0].sourceText');
        final cause = e.cause as TextInputValidationException;
        expect(cause.code, TextInputErrorCode.emptySourceText);
        expect(cause.fieldPath, 'sourceText');
      }
    });
    test('중첩 기하 예외는 원래 수치 진단을 보존한다', () {
      final geometry = expectedTitleGeometryJson();
      (geometry['outline'] as Map)['radius'] = 0;
      try {
        ProductDesignConfiguration.fromJson({
          'appliedGeometries': [
            {'appliedGeometryId': 'g', 'geometry': geometry},
          ],
          'products': <Object?>[],
        });
        fail('잘못된 형상 복원 수락');
      } on ProductDesignNestedException catch (e) {
        expect(e.fieldPath, 'appliedGeometries[0].geometry.outline.radius');
        final cause = e.cause as GeometryValidationException;
        expect(cause.code, GeometryErrorCode.nonPositiveRadius);
        expect((cause.diagnostic.details as GeometryNumberDetails).value, 0);
      }
    });
    test('중첩 출처 값 오류는 적용 목록 위치와 기대 타입 상세를 제공한다', () {
      expect(
        () => ProductDesignConfiguration.fromJson({
          'appliedGeometries': [
            {
              'appliedGeometryId': 'g',
              'geometry': expectedTitleGeometryJson(),
              'source': {'sourceDesignId': false},
            },
          ],
          'products': <Object?>[],
        }),
        productFailure(
          ProductDesignErrorCode.invalidType,
          'appliedGeometries[0].source.sourceDesignId',
        ),
      );
    });
    test('상위 JSON의 추가 필드는 버리지 않는다', () {
      expect(
        () => ProductDesignConfiguration.fromJson({
          'appliedGeometries': <Object?>[],
          'products': <Object?>[],
          'status': 'done',
        }),
        productFailure(ProductDesignErrorCode.unexpectedField, 'status'),
      );
    });
  });
}
