import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  group('ProductInput의 독립 문구 값', () {
    test('공백·Unicode·직접 지정 한 줄을 고정 JSON과 왕복에서 보존한다', () {
      const text = '  PUMP e\u0301 👩‍🔧  ';
      final value = ProductInput(
        productId: ' p ',
        appliedGeometryId: ' g ',
        textInputs: [
          TextAreaInput(
            areaId: 'title',
            sourceText: text,
            lineBreak: SpecifiedLineBreak([text]),
          ),
        ],
      );
      final expected = {
        'productId': ' p ',
        'appliedGeometryId': ' g ',
        'textInputs': [
          {
            'areaId': 'title',
            'sourceText': text,
            'lineBreak': {
              'mode': 'specified',
              'lines': [text],
            },
          },
        ],
      };
      expect(value.toJson(), expected);
      expect(ProductInput.fromJson(jsonDecode(jsonEncode(expected))), value);
    });
    for (final field in ['productId', 'appliedGeometryId']) {
      for (final route in ['생성', '수정', '복원']) {
        test('$route에서 $field 빈 문자열을 거부한다', () {
          final old = ProductInput(
            productId: 'p',
            appliedGeometryId: 'g',
            textInputs: [],
          );
          final json = {
            'productId': 'p',
            'appliedGeometryId': 'g',
            'textInputs': <Object?>[],
          };
          expect(
            () => switch (route) {
              '생성' => ProductInput(
                productId: field == 'productId' ? '' : 'p',
                appliedGeometryId: field == 'appliedGeometryId' ? '' : 'g',
                textInputs: [],
              ),
              '수정' =>
                field == 'productId'
                    ? old.copyWith(productId: '')
                    : old.copyWith(appliedGeometryId: ''),
              _ => ProductInput.fromJson({...json, field: ''}),
            },
            productFailure(
              field == 'productId'
                  ? ProductDesignErrorCode.emptyProductId
                  : ProductDesignErrorCode.emptyAppliedGeometryId,
              field,
            ),
          );
        });
      }
    }
    test('areaId 중복은 단독 제품에서 숨기지 않고 구성 검증에 전달한다', () {
      final value = ProductInput(
        productId: 'p',
        appliedGeometryId: 'g',
        textInputs: [
          automaticAreaText('title', 'A'),
          automaticAreaText('title', 'B'),
        ],
      );
      expect(value.textInputs.map((i) => i.sourceText), ['A', 'B']);
      final issues = validateProductDesignConfiguration(
        appliedGeometries: [
          appliedMillimeterDesign('g', ['title']),
        ],
        products: [value],
      );
      expect(issues, hasLength(1));
      expect(
        (issues.single.details as ProductDesignAreaDetails).cause.code,
        DesignErrorCode.duplicateInputAreaId,
      );
    });
    test('생성·수정·공개 목록·반환 JSON을 통해 기존 원문을 바꾸지 못한다', () {
      final inputs = [automaticAreaText('a', 'PUMP')];
      final old = ProductInput(
        productId: 'p',
        appliedGeometryId: 'g',
        textInputs: inputs,
      );
      inputs.clear();
      expect(() => old.textInputs.clear(), throwsUnsupportedError);
      final replacements = [automaticAreaText('b', 'VALVE')];
      final changed = old.copyWith(textInputs: replacements);
      replacements.clear();
      final json = changed.toJson();
      ((json['textInputs'] as List).single as Map)['sourceText'] = 'changed';
      expect(changed.textInputs.single.sourceText, 'VALVE');
      expect(old.textInputs.single.sourceText, 'PUMP');
    });
    test('잘못된 지정 줄 복원의 원래 문구 오류를 상위 위치와 함께 제공한다', () {
      try {
        ProductInput.fromJson({
          'productId': 'p',
          'appliedGeometryId': 'g',
          'textInputs': [
            {
              'areaId': 'title',
              'sourceText': 'PUMP',
              'lineBreak': {
                'mode': 'specified',
                'lines': ['VALVE'],
              },
            },
          ],
        });
        fail('불일치 원문 수락');
      } on ProductDesignNestedException catch (e) {
        expect(e.fieldPath, 'textInputs[0].lineBreak.lines');
        final cause = e.cause as TextInputValidationException;
        expect(cause.code, TextInputErrorCode.specifiedLinesMismatchSourceText);
        expect(cause.fieldPath, 'lineBreak.lines');
      }
    });
    for (final field in ['productId', 'appliedGeometryId', 'textInputs']) {
      test('필수 $field 누락을 보정하지 않는다', () {
        final json = {
          'productId': 'p',
          'appliedGeometryId': 'g',
          'textInputs': <Object?>[],
        }..remove(field);
        expect(
          () => ProductInput.fromJson(json),
          productFailure(ProductDesignErrorCode.missingField, field),
        );
      });
      test('$field=null의 타입 오류를 거부한다', () {
        expect(
          () => ProductInput.fromJson({
            'productId': 'p',
            'appliedGeometryId': 'g',
            'textInputs': <Object?>[],
            field: null,
          }),
          productFailure(ProductDesignErrorCode.invalidType, field),
        );
      });
    }
  });
}
