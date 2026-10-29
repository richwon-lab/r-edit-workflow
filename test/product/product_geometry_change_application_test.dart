import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  test('공개 성공 구성은 기존 스냅샷·비대상·원문·순서·공유를 고정 기대 값대로 보존한다', () {
    final old = appliedMillimeterDesign('old', ['a', 'b', 'gone']);
    final unused = appliedMillimeterDesign('unused', []);
    final proposed = appliedMillimeterDesign('new', ['b', 'y', 'n1', 'n2']);
    final multi = SpecifiedLineBreak([' A ', 'e\u0301', '😀!? ']);
    final one = SpecifiedLineBreak([' SECOND  한글 ']);
    final p1 = ProductInput(
      productId: 'p1',
      appliedGeometryId: 'old',
      textInputs: [
        automaticAreaText('gone', 'DROP 1'),
        TextAreaInput(
          areaId: 'a',
          sourceText: ' A e\u0301😀!? ',
          lineBreak: multi,
        ),
        automaticAreaText('b', ' KEEP 1 '),
      ],
    );
    final p3 = ProductInput(
      productId: 'p3',
      appliedGeometryId: 'old',
      textInputs: [
        automaticAreaText('b', ' KEEP 3 '),
        TextAreaInput(areaId: 'a', sourceText: ' SECOND  한글 ', lineBreak: one),
        automaticAreaText('gone', 'DROP 3'),
      ],
    );
    final untouched = ProductInput(
      productId: 'p2',
      appliedGeometryId: 'old',
      textInputs: [
        automaticAreaText('a', 'UNTOUCHED A'),
        automaticAreaText('b', 'UNTOUCHED B'),
        automaticAreaText('gone', 'UNTOUCHED G'),
      ],
    );
    final baseline = ProductDesignConfiguration(
      appliedGeometries: [old, unused],
      products: [untouched, p1, p3],
    );
    final session = ProductDesignEditSession.open(configuration: baseline);
    final request = ReviseAppliedGeometry(
      sourceAppliedGeometryId: 'old',
      proposedGeometry: proposed,
      targets: [
        for (final id in ['p3', 'p1'])
          ProductGeometryTarget(
            productId: id,
            areaMappings: [
              const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'y'),
            ],
            newTextInputs: [
              automaticAreaText('n2', '$id N2'),
              automaticAreaText('n1', '$id N1'),
            ],
            removedInputAreaIds: ['gone'],
          ),
      ],
    );
    final prepared =
        session.prepareGeometryChange(request) as ReadyProductGeometryChange;
    final result = session.applyPreparedGeometryChange(
      prepared,
    ) as AppliedProductGeometryChange;
    final expected = ProductDesignConfiguration(
      appliedGeometries: [old, unused, proposed],
      products: [
        untouched,
        ProductInput(
          productId: 'p1',
          appliedGeometryId: 'new',
          textInputs: [
            TextAreaInput(
              areaId: 'y',
              sourceText: ' A e\u0301😀!? ',
              lineBreak: SpecifiedLineBreak([' A ', 'e\u0301', '😀!? ']),
            ),
            automaticAreaText('b', ' KEEP 1 '),
            automaticAreaText('n2', 'p1 N2'),
            automaticAreaText('n1', 'p1 N1'),
          ],
        ),
        ProductInput(
          productId: 'p3',
          appliedGeometryId: 'new',
          textInputs: [
            automaticAreaText('b', ' KEEP 3 '),
            TextAreaInput(
              areaId: 'y',
              sourceText: ' SECOND  한글 ',
              lineBreak: SpecifiedLineBreak([' SECOND  한글 ']),
            ),
            automaticAreaText('n2', 'p3 N2'),
            automaticAreaText('n1', 'p3 N1'),
          ],
        ),
      ],
    );
    expect(result.configuration, expected);
    expect(result.configuration.products.map((p) => p.productId), [
      'p2',
      'p1',
      'p3',
    ]);
    expect(
      result.configuration.appliedGeometries.map((g) => g.appliedGeometryId),
      ['old', 'unused', 'new'],
    );
    expect(result.configuration.products.first, untouched);
    expect(baseline.products, [untouched, p1, p3]);
    expect(baseline.appliedGeometries, [old, unused]);
    expect(result.state.revision, 1);
    expect(result.summary, same(prepared.summary));
  });
  test('이미 선언된 동일 내용 슬롯은 중복 추가 없이 그대로 채택한다', () {
    final old = appliedMillimeterDesign('old', ['title']);
    final next = appliedMillimeterDesign('next', ['title']);
    final baseline = ProductDesignConfiguration(
      appliedGeometries: [next, old],
      products: [
        ProductInput(
          productId: 'p',
          appliedGeometryId: 'old',
          textInputs: [automaticAreaText('title', ' T ')],
        ),
      ],
    );
    final session = ProductDesignEditSession.open(configuration: baseline);
    final ready = session.prepareGeometryChange(
      ReviseAppliedGeometry(
        sourceAppliedGeometryId: 'old',
        proposedGeometry: appliedMillimeterDesign('next', ['title']),
        targets: [
          ProductGeometryTarget(
            productId: 'p',
            areaMappings: [],
            newTextInputs: [],
            removedInputAreaIds: [],
          ),
        ],
      ),
    ) as ReadyProductGeometryChange;
    final result = session.applyPreparedGeometryChange(
      ready,
    ) as AppliedProductGeometryChange;
    expect(
      result.configuration,
      ProductDesignConfiguration(
        appliedGeometries: [next, old],
        products: [
          ProductInput(
            productId: 'p',
            appliedGeometryId: 'next',
            textInputs: [automaticAreaText('title', ' T ')],
          ),
        ],
      ),
    );
  });
}
