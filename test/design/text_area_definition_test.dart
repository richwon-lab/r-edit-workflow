import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart'
    show
        circleCenteredAt2,
        textAreaWithCircularRegion,
        inchDesignWithIrregularOutline,
        textInputForArea,
        designJsonThroughString,
        designError;

void main() {
  group('TextAreaDefinition의 식별과 표시 이름', () {
    {
      for (final label in ['', '  본문 e\u0301 👩‍🔧  ']) {
        test('label=${jsonEncode(label)} 빈 값·중복·Unicode와 공백 ID를 보존한다', () {
          final original = inchDesignWithIrregularOutline(
            cutouts: [
              CutoutDefinition(cutoutId: ' a ', boundary: circleCenteredAt2()),
            ],
            areas: [
              textAreaWithCircularRegion(' a ', label: label),
              textAreaWithCircularRegion('b', label: label),
            ],
          );
          final restored = DesignGeometry.fromJson(
            designJsonThroughString(original.toJson()),
          );
          expect(restored.textAreas[0].label, label);
          expect(restored.textAreas[0].areaId, ' a ');
          expect(restored.cutouts.single.cutoutId, ' a ');
          expect(
            validateTextAreaInputs(
              design: original,
              inputs: [textInputForArea('b'), textInputForArea(' a ')],
            ),
            isEmpty,
          );
        });
      }
    }

    {
      test('빈 영역 ID 생성을 거부한다', () {
        expect(
          () => textAreaWithCircularRegion(''),
          designError(DesignErrorCode.emptyAreaId, 'areaId'),
        );
      });
    }

    {
      test('영역 ID를 빈 값으로 수정하면 거부한다', () {
        expect(
          () => textAreaWithCircularRegion('a').copyWith(areaId: ''),
          designError(DesignErrorCode.emptyAreaId, 'areaId'),
        );
      });
    }

    {
      final json = textAreaWithCircularRegion('a').toJson();
      for (final key in json.keys) {
        test('TextAreaDefinition JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => TextAreaDefinition.fromJson(missing),
            designError(DesignErrorCode.missingField, key),
          );
        });
      }
      test('TextAreaDefinition JSON의 최상위 목록을 거부한다', () {
        expect(
          () => TextAreaDefinition.fromJson([]),
          designError(DesignErrorCode.invalidType, r'$'),
        );
      });
      test('TextAreaDefinition JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => TextAreaDefinition.fromJson({...json, 'extra': true}),
          designError(DesignErrorCode.unexpectedField, 'extra'),
        );
      });
    }
  });
}
