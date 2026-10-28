import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/product_examples.dart';
import '../support/product_geometry_changes.dart';

void main() {
  test('요청·대상·지정 줄은 외부 목록 수정과 분리되고 공개 목록은 수정 불가다', () {
    final mappings = [
      const TextAreaInputMapping(fromAreaId: 'a', toAreaId: 'b'),
    ];
    final inputs = [automaticAreaText('new', ' A ')];
    final removed = ['old'];
    final targets = [
      ProductGeometryTarget(
        productId: 'p1',
        areaMappings: mappings,
        newTextInputs: inputs,
        removedInputAreaIds: removed,
      ),
    ];
    final request = ReplaceAppliedGeometry(
      proposedGeometry: appliedMillimeterDesign('next', ['b', 'new']),
      targets: targets,
    );
    mappings.clear();
    inputs.clear();
    removed.clear();
    targets.clear();
    expect(request.targets.single.areaMappings.single.fromAreaId, 'a');
    expect(request.targets.single.newTextInputs.single.sourceText, ' A ');
    expect(request.targets.single.removedInputAreaIds, ['old']);
    expect(() => request.targets.clear(), throwsUnsupportedError);
    expect(
      () => request.targets.single.areaMappings.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => request.targets.single.newTextInputs.clear(),
      throwsUnsupportedError,
    );
    expect(
      () => request.targets.single.removedInputAreaIds.clear(),
      throwsUnsupportedError,
    );
  });
  test('요청 수정은 새 불변 값이며 이전 대상 목록을 바꾸지 않는다', () {
    final request = ReviseAppliedGeometry(
      sourceAppliedGeometryId: 'old',
      proposedGeometry: appliedMillimeterDesign('next', ['title']),
      targets: [targetPreservingAreas('p1')],
    );
    final modified = request.copyWith(targets: [targetPreservingAreas('p2')]);
    expect(request.targets.single.productId, 'p1');
    expect(modified.targets.single.productId, 'p2');
    expect(modified.sourceAppliedGeometryId, 'old');
    expect(modified == request, isFalse);
  });
  test('빈 ID를 가진 미완료 요청은 보존하고 준비에서 정상 거부한다', () {
    final result = prepareProductGeometryChange(
      baseline: twoProductsSharingTitleGeometry(),
      request: ReviseAppliedGeometry(
        sourceAppliedGeometryId: '',
        proposedGeometry: appliedMillimeterDesign('next', ['title']),
        targets: [targetPreservingAreas('')],
      ),
    );
    final blocked = result as BlockedProductGeometryChange;
    expect(
      blocked.issues.map((i) => i.code),
      everyElement(ProductGeometryChangeCode.invalidChangeIdentifier),
    );
    expect(
      blocked.issues.map((i) => i.fieldPath),
      unorderedEquals([
        'request.sourceAppliedGeometryId',
        'request.targets[0].productId',
      ]),
    );
  });
}
