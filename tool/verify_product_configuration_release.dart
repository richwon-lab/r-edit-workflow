// AOT 검사 결과를 표준 출력하고 의도한 불변성 예외를 확인한다.
// ignore_for_file: avoid_print, avoid_catching_errors

import 'dart:convert';

import 'package:r_edit_workflow/r_edit_workflow.dart';

/// assert 비활성 환경에서 현재 제품 참조 구성만 확인한다. 저장/변경 명령 시험은 아니다.
void main() {
  var assertions = false;
  assert(() {
    assertions = true;
    return true;
  }(), 'AOT 실행 모드 확인');
  if (assertions) throw StateError('assert 비활성 AOT가 필요합니다');
  final region = CircleBoundary(center: Point2(x: 0, y: 0), radius: 10);
  final geometry = DesignGeometry(
    coordinateSpace: DrawingCoordinateSpace(lengthUnit: LengthUnit.millimeter),
    outline: region,
    cutouts: [],
    textAreas: [
      TextAreaDefinition(
        areaId: 'a',
        label: '',
        region: TextRegion(outer: region, exclusions: []),
      ),
      TextAreaDefinition(
        areaId: 'b',
        label: '',
        region: TextRegion(outer: region, exclusions: []),
      ),
    ],
  );
  final snapshot = AppliedDesignGeometry(
    appliedGeometryId: 'g',
    geometry: geometry,
    source: DesignSourceReference(sourceDesignId: 'unavailable-source'),
  );
  TextAreaInput input(String id, String text) => TextAreaInput(
    areaId: id,
    sourceText: text,
    lineBreak: SpecifiedLineBreak([text]),
  );
  final inputs = [input('b', ' B '), input('a', ' A e\u0301 👩‍🔧 ')];
  final products = [
    ProductInput(productId: 'p-a', appliedGeometryId: 'g', textInputs: inputs),
    ProductInput(
      productId: 'p-b',
      appliedGeometryId: 'g',
      textInputs: [input('a', 'OTHER A'), input('b', 'OTHER B')],
    ),
  ];
  final snapshots = [snapshot];
  final valid = ProductDesignConfiguration(
    appliedGeometries: snapshots,
    products: products,
  );
  inputs.clear();
  products.clear();
  snapshots.clear();
  final expected = valid.toJson();
  final restored = ProductDesignConfiguration.fromJson(
    jsonDecode(jsonEncode(expected)),
  );
  if (restored != valid ||
      restored.products.first.textInputs.first.areaId != 'b' ||
      valid.products.first.textInputs.last.sourceText != ' A e\u0301 👩‍🔧 ') {
    throw StateError('왕복/순서/원문/방어 복사 실패');
  }
  ((expected['products'] as List).first as Map)['productId'] = 'external';
  if (valid.products.first.productId != 'p-a') {
    throw StateError('반환 JSON 변경 방어 실패');
  }
  final invalidProduct = ProductInput(
    productId: 'broken',
    appliedGeometryId: 'g',
    textInputs: [input('a', 'A'), input('a', 'A'), input('unknown', 'X')],
  );
  var rejected = 0;
  void rejects(void Function() run, ProductDesignErrorCode code) {
    try {
      run();
    } on ProductDesignValidationException catch (e) {
      if (!e.issues.any((i) => i.code == code)) rethrow;
      rejected++;
      return;
    }
    throw StateError('잘못된 제품 값/구성을 수락함');
  }

  rejects(
    () => DesignSourceReference(sourceDesignId: ''),
    ProductDesignErrorCode.emptySourceDesignId,
  );
  rejects(
    () => DesignSourceReference(sourceDesignId: 's', sourceRevision: ''),
    ProductDesignErrorCode.emptySourceRevision,
  );
  rejects(
    () => AppliedDesignGeometry(appliedGeometryId: '', geometry: geometry),
    ProductDesignErrorCode.emptyAppliedGeometryId,
  );
  rejects(
    () => valid.products.first.copyWith(productId: ''),
    ProductDesignErrorCode.emptyProductId,
  );
  rejects(
    () => valid.copyWith(appliedGeometries: []),
    ProductDesignErrorCode.unknownAppliedGeometryId,
  );
  rejects(
    () => valid.copyWith(products: [invalidProduct]),
    ProductDesignErrorCode.textAreaInputMismatch,
  );
  rejects(
    () => ProductDesignConfiguration.fromJson({
      'appliedGeometries': [snapshot.toJson()],
      'products': [invalidProduct.toJson()],
    }),
    ProductDesignErrorCode.textAreaInputMismatch,
  );
  rejects(
    () => valid.copyWith(appliedGeometries: [snapshot, snapshot]),
    ProductDesignErrorCode.duplicateAppliedGeometryId,
  );
  rejects(
    () =>
        valid.copyWith(products: [valid.products.first, valid.products.first]),
    ProductDesignErrorCode.duplicateProductId,
  );
  final brokenJson = valid.toJson();
  final firstProduct = (brokenJson['products'] as List).first as Map;
  ((firstProduct['textInputs'] as List).first as Map)['sourceText'] = 'CHANGED';
  var nestedRejected = false;
  try {
    ProductDesignConfiguration.fromJson(brokenJson);
  } on ProductDesignNestedException catch (error) {
    final cause = error.cause as TextInputValidationException;
    if (cause.code != TextInputErrorCode.specifiedLinesMismatchSourceText ||
        error.fieldPath != 'products[0].textInputs[0].lineBreak.lines') {
      rethrow;
    }
    nestedRejected = true;
    rejected++;
  }
  if (!nestedRejected) {
    throw StateError('중첩 원문 검증 우회');
  }
  var snapshotCopyBlocked = false;
  try {
    (snapshot as dynamic).copyWith(geometry: geometry);
  } on NoSuchMethodError {
    snapshotCopyBlocked = true;
  }
  if (!snapshotCopyBlocked) throw StateError('스냅샷 copyWith 노출');
  var listBlocked = false;
  try {
    valid.products.clear();
  } on UnsupportedError {
    listBlocked = true;
  }
  if (!listBlocked) throw StateError('공개 목록 수정 허용');
  final otherMissing = ProductInput(
    productId: 'missing',
    appliedGeometryId: 'not-found',
    textInputs: [],
  );
  final issues = validateProductDesignConfiguration(
    appliedGeometries: [snapshot],
    products: [invalidProduct, otherMissing],
  );
  if (issues.length != 4) throw StateError('독립 오류 수집 실패');
  for (final issue in issues) {
    print(issue);
  }
  var issuesBlocked = false;
  try {
    issues.clear();
  } on UnsupportedError {
    issuesBlocked = true;
  }
  if (!issuesBlocked) throw StateError('진단 목록 수정 허용');
  final withoutSource = AppliedDesignGeometry.fromJson({
    'appliedGeometryId': 'g',
    'geometry': geometry.toJson(),
    'source': null,
  });
  if (withoutSource.toJson().containsKey('source')) {
    throw StateError('선택 출처 생략 실패');
  }
  print(
    '제품 구성 AOT: assert 비활성, 공유·원문·왕복·목록 방어·copyWith 비노출·독립 진단, 오류 $rejected건 통과',
  );
}
