import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_text_basis_examples.dart';

void main() {
  group('ProductGeometryTextBasis의 값 동등성과 생성', () {
    for (final mode in ['입력만', '정의만', '입력과 정의']) {
      test('$mode 재정렬은 같은 영역별 값·해시이며 원본 순서를 변경하지 않는다', () {
        final configuration = twoAreaBasisConfiguration();
        final geometry = configuration.appliedGeometries.first.geometry;
        final definitions = mode == '입력만'
            ? geometry.textAreas
            : geometry.textAreas.reversed.toList();
        final inputs = mode == '정의만'
            ? configuration.products.first.textInputs
            : configuration.products.first.textInputs.reversed.toList();
        final updated = twoAreaBasisConfiguration(
          geometry: geometry.copyWith(textAreas: definitions),
          inputs: inputs,
        );
        final a = extractProductGeometryTextBasis(
          configuration: configuration,
          productId: 'target',
        );
        final b = extractProductGeometryTextBasis(
          configuration: updated,
          productId: 'target',
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(compareProductGeometryTextBasis(previous: a, next: b), isEmpty);
        expect(
          updated.appliedGeometries.first.geometry.textAreas.map(
            (a) => a.areaId,
          ),
          mode == '입력만' ? ['a', 'b'] : ['b', 'a'],
        );
      });
    }
    test('전달 목록과 공개 맵·목록을 수정해도 기존 근거 값은 바뀌지 않는다', () {
      final basis = extractProductGeometryTextBasis(
        configuration: twoAreaBasisConfiguration(),
        productId: 'target',
      );
      final areas = basis.areas.toList();
      final cutouts = [
        CutoutDefinition(
          cutoutId: 'h',
          boundary: CircleBoundary(center: Point2(x: 0, y: 0), radius: 1),
        ),
      ];
      final created = rebuildGeometryTextBasis(
        basis,
        areas: areas,
        cutouts: cutouts,
      );
      areas.clear();
      cutouts.clear();
      expect(created.areas.map((a) => a.areaId), ['a', 'b']);
      expect(created.cutouts.single.cutoutId, 'h');
      expect(() => created.areas.clear(), throwsUnsupportedError);
      expect(() => created.areasById.clear(), throwsUnsupportedError);
      expect(() => created.cutouts.clear(), throwsUnsupportedError);
    });
    test('영역 정의와 입력 ID가 다르면 구체 ID 쌍으로 거부한다', () {
      final configuration = twoAreaBasisConfiguration();
      expect(
        () => AreaGeometryTextBasis(
          definition:
              configuration.appliedGeometries.first.geometry.textAreas.first,
          input: configuration.products.first.textInputs.first,
        ),
        throwsA(
          isA<GeometryTextBasisException>()
              .having(
                (e) => e.code,
                '코드',
                GeometryTextBasisErrorCode.areaInputMismatch,
              )
              .having(
                (e) => (e.details as BasisAreaInputDetails).definitionAreaId,
                '정의',
                'a',
              )
              .having(
                (e) => (e.details as BasisAreaInputDetails).inputAreaId,
                '입력',
                'b',
              ),
        ),
      );
    });
    test('새 근거 생성에서 중복 영역의 두 위치를 구분한다', () {
      final basis = extractProductGeometryTextBasis(
        configuration: twoAreaBasisConfiguration(),
        productId: 'target',
      );
      expect(
        () => rebuildGeometryTextBasis(
          basis,
          areas: [basis.areas.first, basis.areas.first],
        ),
        throwsA(
          isA<GeometryTextBasisException>()
              .having(
                (e) => e.code,
                '코드',
                GeometryTextBasisErrorCode.duplicateAreaId,
              )
              .having((e) => e.fieldPath, '경로', 'areas[1].areaId')
              .having(
                (e) => (e.details as BasisDuplicateDetails).firstIndex,
                '첫 위치',
                0,
              ),
        ),
      );
    });
    test('새 근거 생성에서 중복 관통 경계 ID를 거부한다', () {
      final basis = extractProductGeometryTextBasis(
        configuration: twoAreaBasisConfiguration(),
        productId: 'target',
      );
      final hole = CutoutDefinition(cutoutId: 'h', boundary: basis.outline);
      expect(
        () => rebuildGeometryTextBasis(basis, cutouts: [hole, hole]),
        throwsA(
          isA<GeometryTextBasisException>()
              .having(
                (e) => e.code,
                '코드',
                GeometryTextBasisErrorCode.duplicateCutoutId,
              )
              .having((e) => e.fieldPath, '경로', 'cutouts[1].cutoutId'),
        ),
      );
    });
    test('직접 생성한 근거의 빈 제품 ID를 거부한다', () {
      final basis = extractProductGeometryTextBasis(
        configuration: twoAreaBasisConfiguration(),
        productId: 'target',
      );
      expect(
        () => rebuildGeometryTextBasis(basis, productId: ''),
        throwsA(
          isA<GeometryTextBasisException>().having(
            (e) => e.code,
            '코드',
            GeometryTextBasisErrorCode.emptyProductId,
          ),
        ),
      );
    });
  });
}
