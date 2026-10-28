import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

void main() {
  Matcher argumentNamed(String name) =>
      throwsA(isA<ArgumentError>().having((e) => e.name, '인자', name));
  ChangeAreaSelectionDetails areaDetails({
    List<String>? paths,
    ChangeAreaSide side = ChangeAreaSide.source,
  }) => ChangeAreaSelectionDetails(
    productId: 'p',
    previousAppliedGeometryId: 'old',
    proposedAppliedGeometryId: 'new',
    areaId: 'a',
    side: side,
    selectionPaths: paths ?? ['request.targets[0].areaMappings[0].fromAreaId'],
  );
  test('진단 코드에 다른 상세를 전달하면 런타임에서 거부한다', () {
    expect(
      () => ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.unknownTargetProduct,
        fieldPath: 'request.targets[0].productId',
        details: const ChangeEmptyTargetsDetails(),
      ),
      argumentNamed('details'),
    );
  });
  test('충돌 코드에는 서로 다른 위치 둘 이상이 필요하다', () {
    expect(
      () => ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.duplicateSourceMapping,
        fieldPath: 'request.targets[0].areaMappings[0].fromAreaId',
        details: areaDetails(),
      ),
      argumentNamed('details'),
    );
  });
  test('이전 영역 오류에 새 영역 문맥을 섞으면 거부한다', () {
    expect(
      () => ProductGeometryChangeIssue(
        code: ProductGeometryChangeCode.unknownSourceArea,
        fieldPath: 'request.targets[0].areaMappings[0].fromAreaId',
        details: areaDetails(side: ChangeAreaSide.target),
      ),
      argumentNamed('details.side'),
    );
  });
  for (final path in [
    '',
    'products[0].textAreas',
    'request.targets[-1].productId',
    'request..targets',
    'candidate.products[01].productId',
  ]) {
    test('잘못된 경로 "$path"를 진단으로 생성하지 않는다', () {
      expect(
        () => ProductGeometryChangeIssue(
          code: ProductGeometryChangeCode.emptyTargetSet,
          fieldPath: path,
          details: const ChangeEmptyTargetsDetails(),
        ),
        argumentNamed('fieldPath'),
      );
    });
  }
  test('없는 제품 상세의 음수 인덱스와 빈 ID를 구분한다', () {
    expect(
      () => ChangeTargetDetails(productId: 'p', targetIndex: -1),
      argumentNamed('targetIndex'),
    );
    expect(
      () => ChangeTargetDetails(productId: '', targetIndex: 0),
      argumentNamed('productId'),
    );
  });
  test('중복 대상 위치는 방어 복사하고 중복/음수/단일 위치를 거부한다', () {
    final indices = [0, 2];
    final detail = ChangeDuplicateTargetsDetails(
      productId: 'p',
      targetIndices: indices,
    );
    indices.clear();
    expect(detail.targetIndices, [0, 2]);
    expect(() => detail.targetIndices.clear(), throwsUnsupportedError);
    expect(
      () =>
          ChangeDuplicateTargetsDetails(productId: 'p', targetIndices: [0, 0]),
      argumentNamed('targetIndices'),
    );
    expect(
      () => ChangeDuplicateTargetsDetails(productId: 'p', targetIndices: [0]),
      argumentNamed('targetIndices'),
    );
    expect(
      () =>
          ChangeDuplicateTargetsDetails(productId: 'p', targetIndices: [0, -1]),
      argumentNamed('targetIndices[1]'),
    );
  });
  test('선택 위치는 방어 복사하고 출력에 코드·위치·설명을 제공한다', () {
    final paths = [
      'request.targets[0].areaMappings[0].fromAreaId',
      'request.targets[0].removedInputAreaIds[0]',
    ];
    final details = areaDetails(paths: paths);
    final issue = ProductGeometryChangeIssue(
      code: ProductGeometryChangeCode.conflictingInputDisposition,
      fieldPath: paths.last,
      details: details,
    );
    paths.clear();
    expect(details.selectionPaths.length, 2);
    expect(() => details.selectionPaths.clear(), throwsUnsupportedError);
    expect(issue.toString(), contains('conflictingInputDisposition'));
    expect(
      issue.toString(),
      contains('request.targets[0].removedInputAreaIds[0]'),
    );
    expect(
      issue.toString(),
      contains(
        ProductGeometryChangeCode.conflictingInputDisposition.description,
      ),
    );
    expect(issue.toString(), contains('productId=p'));
  });
  test('스냅샷 충돌 경로와 원래 영역 진단을 손실 없이 보존한다', () {
    final paths = ['geometry.outline.radius'];
    final details = ChangeSnapshotConflictDetails(
      appliedGeometryId: 'g',
      baselineIndex: 2,
      changedFieldPaths: paths,
    );
    paths.clear();
    expect(details.changedFieldPaths, ['geometry.outline.radius']);
    expect(() => details.changedFieldPaths.clear(), throwsUnsupportedError);
    expect(
      () => ChangeSnapshotConflictDetails(
        appliedGeometryId: 'g',
        baselineIndex: 0,
        changedFieldPaths: ['geometry.fake'],
      ),
      argumentNamed('changedFieldPaths[0]'),
    );
    final lower = DesignValidationIssue(
      code: DesignErrorCode.missingAreaInput,
      fieldPath: 'textAreas[0].areaId',
      details: const DesignIdentifierDetails('a'),
    );
    final nested = ChangeAreaInputDetails(
      productId: 'p',
      previousAppliedGeometryId: 'old',
      proposedAppliedGeometryId: 'new',
      cause: lower,
    );
    expect(nested.cause, same(lower));
    expect(nested.cause.details, same(lower.details));
    expect(nested.cause.fieldPath, 'textAreas[0].areaId');
  });
}
