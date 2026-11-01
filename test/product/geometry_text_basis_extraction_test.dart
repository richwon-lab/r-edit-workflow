import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/geometry_text_basis_examples.dart';

void main() {
  group('extractProductGeometryTextBasis', () {
    test('공유 형상에서 대상만 추출하고 정의 순서로 ID를 연결하며 입력 원본 순서는 유지한다', () {
      final configuration = twoAreaBasisConfiguration();
      final basis = extractProductGeometryTextBasis(
        configuration: configuration,
        productId: 'target',
      );
      final geometry = configuration.appliedGeometries.first.geometry;
      expect(basis.productId, 'target');
      expect(basis.coordinateSpace, same(geometry.coordinateSpace));
      expect(basis.outline, same(geometry.outline));
      expect(basis.areas.map((a) => a.areaId), ['a', 'b']);
      expect(
        basis.areas[0].input,
        same(configuration.products.first.textInputs[1]),
      );
      expect(basis.areas[0].input.sourceText, ' A e\u0301🙂  ');
      expect((basis.areas[0].input.lineBreak as SpecifiedLineBreak).lines, [
        ' A e\u0301🙂  ',
      ]);
      expect((basis.areas[1].input.lineBreak as SpecifiedLineBreak).lines, [
        'PUMP ',
        'PUMP',
      ]);
      expect(configuration.products.first.textInputs.map((i) => i.areaId), [
        'b',
        'a',
      ]);
      expect(
        extractProductGeometryTextBasis(
          configuration: configuration,
          productId: 'other',
        ).areas.first.input.lineBreak,
        isA<AutomaticLineBreak>(),
      );
    });
    test('적용 ID·출처·표시명·비대상 제품은 근거 값과 대조에서 제외한다', () {
      final original = twoAreaBasisConfiguration();
      final geometry =
          twoAreaBasisConfiguration().appliedGeometries.first.geometry;
      final updated = twoAreaBasisConfiguration(
        appliedId: 'new-id',
        source: DesignSourceReference(
          sourceDesignId: 'source',
          sourceRevision: 'r7',
        ),
        otherText: 'CHANGED',
        geometry: geometry.copyWith(
          textAreas: [
            for (final a in geometry.textAreas) a.copyWith(label: '새 표시명'),
          ],
        ),
      );
      final changedUnused = updated.copyWith(
        appliedGeometries: [
          updated.appliedGeometries.first,
          AppliedDesignGeometry(
            appliedGeometryId: 'different-unused',
            geometry: geometry.copyWith(
              outline: CircleBoundary(center: Point2(x: 0, y: 0), radius: 99),
            ),
          ),
        ],
      );
      final a = extractProductGeometryTextBasis(
        configuration: original,
        productId: 'target',
      );
      final b = extractProductGeometryTextBasis(
        configuration: changedUnused,
        productId: 'target',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(compareProductGeometryTextBasis(previous: a, next: b), isEmpty);
    });
    test('대상 없음은 전용 코드와 대상 ID로 거부하며 빈 대상은 인자 오용이다', () {
      final configuration = twoAreaBasisConfiguration();
      expect(
        () => extractProductGeometryTextBasis(
          configuration: configuration,
          productId: 'absent',
        ),
        throwsA(
          isA<GeometryTextBasisException>()
              .having(
                (e) => e.code,
                '코드',
                GeometryTextBasisErrorCode.unknownProduct,
              )
              .having((e) => e.fieldPath, '위치', 'productId')
              .having(
                (e) => (e.details as BasisIdentifierDetails).identifier,
                '대상',
                'absent',
              ),
        ),
      );
      expect(
        () => extractProductGeometryTextBasis(
          configuration: configuration,
          productId: '',
        ),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, '인자', 'productId')
              .having((e) => e.invalidValue, '문제 값', ''),
        ),
      );
    });
    test('surrogate pair와 결합열 중간의 기존 지정 줄도 경계 검사 없이 그대로 공유한다', () {
      final input = TextAreaInput(
        areaId: 'a',
        sourceText: '🙂e\u0301',
        lineBreak: SpecifiedLineBreak(['\uD83D', '\uDE42e', '\u0301']),
      );
      final configuration = twoAreaBasisConfiguration(
        inputs: [
          input,
          TextAreaInput(
            areaId: 'b',
            sourceText: 'b',
            lineBreak: const AutomaticLineBreak(),
          ),
        ],
      );
      final basis = extractProductGeometryTextBasis(
        configuration: configuration,
        productId: 'target',
      );
      expect(basis.areas.first.input, same(input));
      expect((basis.areas.first.input.lineBreak as SpecifiedLineBreak).lines, [
        '\uD83D',
        '\uDE42e',
        '\u0301',
      ]);
    });
  });
}
