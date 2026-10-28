import 'package:r_edit_workflow/r_edit_workflow.dart';
// 비공개 후보를 공개 getter로 노출하지 않고 실제 준비에 쓰는 내부 입력 투영 책임을 검증한다.
import 'package:r_edit_workflow/src/product/text_area_input_change_preparation.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';

void main() {
  for (final lines in [
    <String>['  Ab e\u0301😀!?한글 '],
    <String>['  Ab ', 'e\u0301', '😀!?한글 '],
  ]) {
    test('유지 영역은 직접 지정 ${lines.length}줄과 원문 Unicode를 그대로 공유한다', () {
      final input = TextAreaInput(
        areaId: 'a',
        sourceText: '  Ab e\u0301😀!?한글 ',
        lineBreak: SpecifiedLineBreak(lines),
      );
      final product = ProductInput(
        productId: 'p',
        appliedGeometryId: 'old',
        textInputs: [input],
      );
      final result = prepareTargetTextInputs(
        product: product,
        productIndex: 0,
        targetIndex: 0,
        previous: appliedMillimeterDesign('old', ['a']),
        proposed: appliedMillimeterDesign('next', ['a']),
        revise: true,
        target: ProductGeometryTarget(
          productId: 'p',
          areaMappings: [],
          newTextInputs: [],
          removedInputAreaIds: [],
        ),
      );
      expect(result.issues, isEmpty);
      expect(result.inputs!.single, same(input));
      expect(result.inputs!.single.sourceText, '  Ab e\u0301😀!?한글 ');
      expect(
        (result.inputs!.single.lineBreak as SpecifiedLineBreak).lines,
        lines,
      );
    });
  }
  test('대응 순서와 무관하게 이전 상대 순서를 보존하고 신규 입력은 뒤에 붙인다', () {
    final specified = TextAreaInput(
      areaId: 'b',
      sourceText: ' AA  AA ',
      lineBreak: SpecifiedLineBreak([' AA ', ' AA ']),
    );
    final automatic = automaticAreaText('a', 'Zz!? 한글');
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [specified, automatic],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 1,
      targetIndex: 2,
      previous: appliedMillimeterDesign('old', ['a', 'b']),
      proposed: appliedMillimeterDesign('next', ['x', 'y', 'n1', 'n2']),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [
          const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'x'),
          const TextAreaInputMapping(fromAreaId: 'b', toAreaId: 'y'),
        ],
        newTextInputs: [
          automaticAreaText('n2', 'NEW 2'),
          automaticAreaText('n1', 'NEW 1'),
        ],
        removedInputAreaIds: [],
      ),
    );
    expect(result.issues, isEmpty);
    expect(result.inputs!.map((i) => i.areaId), ['y', 'x', 'n2', 'n1']);
    expect(result.inputs![0].sourceText, ' AA  AA ');
    expect(result.inputs![0].lineBreak, same(specified.lineBreak));
    expect(result.inputs![1].lineBreak, isA<AutomaticLineBreak>());
    expect(product.textInputs.map((i) => i.areaId), ['b', 'a']);
    expect(result.summary!.areaMappings.map((m) => m.fromAreaId), ['b', 'a']);
    expect(result.summary!.newInputAreaIds, ['n2', 'n1']);
  });
  test('삭제된 영역 입력은 새 영역에 명시 대응하고 유지 입력은 그대로 보존한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [
        automaticAreaText('deleted', 'OLD'),
        automaticAreaText('keep', 'KEEP'),
      ],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 0,
      previous: appliedMillimeterDesign('old', ['keep', 'deleted']),
      proposed: appliedMillimeterDesign('next', ['keep', 'new']),
      revise: true,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [
          const TextAreaInputMapping(fromAreaId: 'deleted', toAreaId: 'new'),
        ],
        newTextInputs: [],
        removedInputAreaIds: [],
      ),
    );
    expect(result.issues, isEmpty);
    expect(result.inputs!.map((i) => i.areaId), ['new', 'keep']);
    expect(result.inputs!.first.sourceText, 'OLD');
    expect(result.inputs!.last, same(product.textInputs.last));
  });
  for (final remove in [false, true]) {
    test('영역 삭제는 개별 제거 ${remove ? '선택으로만 허용한다' : '선택 없이는 거부한다'}', () {
      final product = ProductInput(
        productId: 'p',
        appliedGeometryId: 'old',
        textInputs: [automaticAreaText('a', 'KEEP ORIGINAL')],
      );
      final result = prepareTargetTextInputs(
        product: product,
        productIndex: 3,
        targetIndex: 1,
        previous: appliedMillimeterDesign('old', ['a']),
        proposed: appliedMillimeterDesign('next', []),
        revise: true,
        target: ProductGeometryTarget(
          productId: 'p',
          areaMappings: [],
          newTextInputs: [],
          removedInputAreaIds: remove ? ['a'] : [],
        ),
      );
      if (remove) {
        expect(result.issues, isEmpty);
        expect(result.inputs, isEmpty);
        expect(result.summary!.removedInputAreaIds, ['a']);
      } else {
        expect(result.inputs, isNull);
        expect(
          result.issues.single.code,
          ProductGeometryChangeCode.unresolvedSourceInput,
        );
        expect(
          result.issues.single.fieldPath,
          'baseline.products[3].textInputs[0].areaId',
        );
      }
      expect(product.textInputs.single.sourceText, 'KEEP ORIGINAL');
    });
  }
  test('교체는 같은 areaId에도 유지하지 않고 명시 선택과 공급을 요구한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [automaticAreaText('a', 'A')],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 0,
      previous: appliedMillimeterDesign('old', ['a']),
      proposed: appliedMillimeterDesign('next', ['a']),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [],
        newTextInputs: [],
        removedInputAreaIds: [],
      ),
    );
    expect(result.inputs, isNull);
    expect(
      result.issues.map((i) => i.code),
      unorderedEquals([
        ProductGeometryChangeCode.unresolvedSourceInput,
        ProductGeometryChangeCode.areaInputMismatch,
      ]),
    );
    final missing = result.issues.singleWhere(
      (i) => i.code == ProductGeometryChangeCode.areaInputMismatch,
    );
    expect(
      missing.fieldPath,
      'request.proposedGeometry.geometry.textAreas[0].areaId',
    );
    final cause = (missing.details as ChangeAreaInputDetails).cause;
    expect(cause.code, DesignErrorCode.missingAreaInput);
    expect(cause.fieldPath, 'textAreas[0].areaId');
    expect((cause.details! as DesignIdentifierDetails).identifier, 'a');
  });
  for (final choice in ['mapping', 'new', 'remove']) {
    test('부분 수정 유지 영역을 $choice 선택으로 덮어쓰지 않는다', () {
      final product = ProductInput(
        productId: 'p',
        appliedGeometryId: 'old',
        textInputs: [automaticAreaText('a', 'A')],
      );
      final result = prepareTargetTextInputs(
        product: product,
        productIndex: 0,
        targetIndex: 0,
        previous: appliedMillimeterDesign('old', ['a']),
        proposed: appliedMillimeterDesign('next', ['a']),
        revise: true,
        target: ProductGeometryTarget(
          productId: 'p',
          areaMappings: choice == 'mapping'
              ? [const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'a')]
              : [],
          newTextInputs: choice == 'new'
              ? [automaticAreaText('a', 'DIFFERENT')]
              : [],
          removedInputAreaIds: choice == 'remove' ? ['a'] : [],
        ),
      );
      expect(result.inputs, isNull);
      expect(
        result.issues.map((i) => i.code),
        everyElement(ProductGeometryChangeCode.conflictingInputDisposition),
      );
      expect(product.textInputs.single.sourceText, 'A');
    });
  }
  for (final side in [ChangeAreaSide.source, ChangeAreaSide.target]) {
    test('중복 ${side.name} mapping을 선택하지 않고 종속 누락도 보고하지 않는다', () {
      final product = ProductInput(
        productId: 'p',
        appliedGeometryId: 'old',
        textInputs: [
          automaticAreaText('a', 'A'),
          if (side == ChangeAreaSide.target) automaticAreaText('b', 'B'),
        ],
      );
      final mappings = side == ChangeAreaSide.source
          ? [
              const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'x'),
              const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'y'),
            ]
          : [
              const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'x'),
              const TextAreaInputMapping(fromAreaId: 'b', toAreaId: 'x'),
            ];
      final result = prepareTargetTextInputs(
        product: product,
        productIndex: 0,
        targetIndex: 0,
        previous: appliedMillimeterDesign(
          'old',
          side == ChangeAreaSide.source ? ['a'] : ['a', 'b'],
        ),
        proposed: appliedMillimeterDesign(
          'next',
          side == ChangeAreaSide.source ? ['x', 'y'] : ['x'],
        ),
        revise: false,
        target: ProductGeometryTarget(
          productId: 'p',
          areaMappings: mappings,
          newTextInputs: [],
          removedInputAreaIds: [],
        ),
      );
      expect(result.inputs, isNull);
      expect(
        result.issues.single.code,
        side == ChangeAreaSide.source
            ? ProductGeometryChangeCode.duplicateSourceMapping
            : ProductGeometryChangeCode.duplicateTargetMapping,
      );
      final details =
          result.issues.single.details as ChangeAreaSelectionDetails;
      expect(details.side, side);
      expect(
        details.selectionPaths,
        side == ChangeAreaSide.source
            ? [
                'request.targets[0].areaMappings[0].fromAreaId',
                'request.targets[0].areaMappings[1].fromAreaId',
              ]
            : [
                'request.targets[0].areaMappings[0].toAreaId',
                'request.targets[0].areaMappings[1].toAreaId',
              ],
      );
    });
  }
  test('없는 이전·새 영역은 각각 문맥과 실제 mapping 위치를 진단한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 2,
      previous: appliedMillimeterDesign('old', []),
      proposed: appliedMillimeterDesign('next', []),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [
          const TextAreaInputMapping(
            fromAreaId: 'absent-old',
            toAreaId: 'absent-new',
          ),
        ],
        newTextInputs: [],
        removedInputAreaIds: [],
      ),
    );
    expect(
      result.issues.map((i) => i.code),
      unorderedEquals([
        ProductGeometryChangeCode.unknownSourceArea,
        ProductGeometryChangeCode.unknownTargetArea,
      ]),
    );
    expect(
      result.issues.map((i) => i.fieldPath),
      unorderedEquals([
        'request.targets[2].areaMappings[0].fromAreaId',
        'request.targets[2].areaMappings[0].toAreaId',
      ]),
    );
  });
  for (final duplicate in [false, true]) {
    test('신규 입력의 ${duplicate ? '중복' : '미정의'} 영역은 원래 연결 진단을 보존한다', () {
      final product = ProductInput(
        productId: 'p',
        appliedGeometryId: 'old',
        textInputs: [],
      );
      final result = prepareTargetTextInputs(
        product: product,
        productIndex: 0,
        targetIndex: 0,
        previous: appliedMillimeterDesign('old', []),
        proposed: appliedMillimeterDesign('next', duplicate ? ['a'] : []),
        revise: false,
        target: ProductGeometryTarget(
          productId: 'p',
          areaMappings: [],
          newTextInputs: [
            automaticAreaText('a', 'A'),
            if (duplicate) automaticAreaText('a', 'B'),
          ],
          removedInputAreaIds: [],
        ),
      );
      final issue = result.issues.single;
      expect(issue.code, ProductGeometryChangeCode.areaInputMismatch);
      expect(
        issue.fieldPath,
        'request.targets[0].newTextInputs[${duplicate ? 1 : 0}].areaId',
      );
      final cause = (issue.details as ChangeAreaInputDetails).cause;
      expect(
        cause.code,
        duplicate
            ? DesignErrorCode.duplicateInputAreaId
            : DesignErrorCode.unknownInputAreaId,
      );
      expect(cause.fieldPath, 'inputs[${duplicate ? 1 : 0}].areaId');
    });
  }
  test('중복 제거 선택은 폐기나 임의 선택 없이 충돌로 거부한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [automaticAreaText('a', 'A')],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 0,
      previous: appliedMillimeterDesign('old', ['a']),
      proposed: appliedMillimeterDesign('next', []),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [],
        newTextInputs: [],
        removedInputAreaIds: ['a', 'a'],
      ),
    );
    expect(
      result.issues.single.code,
      ProductGeometryChangeCode.conflictingInputDisposition,
    );
    expect(result.inputs, isNull);
  });

  test('mapping과 신규 공급의 충돌은 종속 누락을 억제하고 독립 누락은 보존한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [automaticAreaText('a', 'A')],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 0,
      previous: appliedMillimeterDesign('old', ['a']),
      proposed: appliedMillimeterDesign('next', ['x', 'y']),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [
          const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'x'),
        ],
        newTextInputs: [automaticAreaText('x', 'NEW')],
        removedInputAreaIds: [],
      ),
    );
    expect(
      result.issues.map((i) => i.code),
      unorderedEquals([
        ProductGeometryChangeCode.conflictingInputDisposition,
        ProductGeometryChangeCode.areaInputMismatch,
      ]),
    );
    final missing = result.issues.singleWhere(
      (i) => i.code == ProductGeometryChangeCode.areaInputMismatch,
    );
    expect(
      missing.fieldPath,
      'request.proposedGeometry.geometry.textAreas[1].areaId',
    );
    expect(
      ((missing.details as ChangeAreaInputDetails).cause.details!
              as DesignIdentifierDetails)
          .identifier,
      'y',
    );
    expect(result.inputs, isNull);
  });
  test('교체에서 개별 제거와 신규 공급을 명시하면 같은 영역에도 새 입력을 제공할 수 있다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [automaticAreaText('a', 'OLD')],
    );
    final input = TextAreaInput(
      areaId: 'a',
      sourceText: ' NEW ',
      lineBreak: SpecifiedLineBreak([' NEW ']),
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 0,
      previous: appliedMillimeterDesign('old', ['a']),
      proposed: appliedMillimeterDesign('next', ['a']),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [],
        newTextInputs: [input],
        removedInputAreaIds: ['a'],
      ),
    );
    expect(result.issues, isEmpty);
    expect(result.inputs!.single, same(input));
    expect(product.textInputs.single.sourceText, 'OLD');
    expect(result.summary!.removedInputAreaIds, ['a']);
    expect(result.summary!.newInputAreaIds, ['a']);
  });
  test('빈 mapping ID와 없는 제거 ID는 실제 요청 항목에서 구분한다', () {
    final product = ProductInput(
      productId: 'p',
      appliedGeometryId: 'old',
      textInputs: [],
    );
    final result = prepareTargetTextInputs(
      product: product,
      productIndex: 0,
      targetIndex: 2,
      previous: appliedMillimeterDesign('old', []),
      proposed: appliedMillimeterDesign('next', []),
      revise: false,
      target: ProductGeometryTarget(
        productId: 'p',
        areaMappings: [
          const TextAreaInputMapping(fromAreaId: '', toAreaId: ''),
        ],
        newTextInputs: [],
        removedInputAreaIds: ['absent', ''],
      ),
    );
    expect(
      result.issues.map((i) => i.fieldPath),
      unorderedEquals([
        'request.targets[2].areaMappings[0].fromAreaId',
        'request.targets[2].areaMappings[0].toAreaId',
        'request.targets[2].removedInputAreaIds[0]',
        'request.targets[2].removedInputAreaIds[1]',
      ]),
    );
    expect(
      result.issues.where(
        (i) => i.code == ProductGeometryChangeCode.invalidChangeIdentifier,
      ),
      hasLength(3),
    );
    expect(result.inputs, isNull);
  });
}
