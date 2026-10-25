import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  group('AppliedDesignGeometry의 불변 적용 내용', () {
    for (final includeSource in [false, true]) {
      test('출처 포함=$includeSource에서 실제 형상을 고정 JSON으로 보존한다', () {
        final geometry = millimeterDesignWithAreaIds(['title']);
        final source = DesignSourceReference(
          sourceDesignId: 'catalog',
          sourceRevision: 'r7',
        );
        final value = AppliedDesignGeometry(
          appliedGeometryId: 'g',
          geometry: geometry,
          source: includeSource ? source : null,
        );
        final expected = <String, Object?>{
          'appliedGeometryId': 'g',
          'geometry': expectedTitleGeometryJson(),
          if (includeSource)
            'source': {'sourceDesignId': 'catalog', 'sourceRevision': 'r7'},
        };
        expect(value.toJson(), expected);
        expect(identical(value.geometry, geometry), isTrue);
        expect(
          AppliedDesignGeometry.fromJson(jsonDecode(jsonEncode(expected))),
          value,
        );
      });
    }
    test('source=null은 기록 없음이며 다시 출력할 때 생략한다', () {
      final value = AppliedDesignGeometry.fromJson({
        'appliedGeometryId': 'g',
        'geometry': expectedTitleGeometryJson(),
        'source': null,
      });
      expect(value.source, isNull);
      expect(value.toJson().containsKey('source'), isFalse);
    });
    test('일반 copyWith로 같은 ID의 내용을 교체할 수 없다', () {
      final value = appliedMillimeterDesign('g', ['title']);
      expect(
        () => (value as dynamic).copyWith(
          geometry: millimeterDesignWithAreaIds([]),
        ),
        throwsNoSuchMethodError,
      );
      expect(
        () => (value as dynamic).copyWith(
          source: DesignSourceReference(sourceDesignId: 's'),
        ),
        throwsNoSuchMethodError,
      );
    });
    test('빈 적용 ID를 거부하고 공백 ID는 그대로 보존한다', () {
      expect(
        () => appliedMillimeterDesign('', ['title']),
        productFailure(
          ProductDesignErrorCode.emptyAppliedGeometryId,
          'appliedGeometryId',
        ),
      );
      expect(appliedMillimeterDesign('   ', []).appliedGeometryId, '   ');
    });
    test('중첩 기하 오류는 원래 코드·경로·수치 진단을 보존한다', () {
      final json = expectedTitleGeometryJson();
      (json['outline'] as Map)['radius'] = 0;
      try {
        AppliedDesignGeometry.fromJson({
          'appliedGeometryId': 'g',
          'geometry': json,
        });
        fail('잘못된 반지름을 수락함');
      } on ProductDesignNestedException catch (e) {
        expect(e.fieldPath, 'geometry.outline.radius');
        final cause = e.cause as GeometryValidationException;
        expect(cause.code, GeometryErrorCode.nonPositiveRadius);
        expect(cause.fieldPath, 'outline.radius');
        expect((cause.diagnostic.details as GeometryNumberDetails).value, 0);
        expect(
          identical(e.prefixed('appliedGeometries[0]').cause, cause),
          isTrue,
        );
      }
    });
    test('출처의 잘못된 타입은 source 위치와 기대·실제 타입을 제공한다', () {
      expect(
        () => AppliedDesignGeometry.fromJson({
          'appliedGeometryId': 'g',
          'geometry': expectedTitleGeometryJson(),
          'source': false,
        }),
        productFailure(ProductDesignErrorCode.invalidType, 'source'),
      );
    });
    test('반환 JSON의 중첩 내용 변경으로 스냅샷은 바뀌지 않는다', () {
      final value = AppliedDesignGeometry(
        appliedGeometryId: 'g',
        geometry: millimeterDesignWithAreaIds(['title']),
        source: DesignSourceReference(sourceDesignId: 's'),
      );
      final json = value.toJson();
      ((json['geometry'] as Map)['outline'] as Map)['radius'] = 999;
      (json['source'] as Map)['sourceDesignId'] = 'changed';
      expect((value.geometry.outline as CircleBoundary).radius, 30);
      expect(value.source!.sourceDesignId, 's');
    });
  });
}
