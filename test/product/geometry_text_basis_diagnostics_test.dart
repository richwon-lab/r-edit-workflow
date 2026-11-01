import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

void main() {
  Matcher argument(String name, Object? value) => throwsA(
    isA<ArgumentError>()
        .having((e) => e.name, '인자명', name)
        .having((e) => e.invalidValue, '문제 값', value)
        .having((e) => e.message.toString(), '위반 조건', isNotEmpty),
  );
  test(
    '같은 ID의 제품 불일치 진단을 생성할 수 없다',
    () => expect(
      () => GeometryTextBasisDifference.productMismatch(
        previousProductId: 'p',
        nextProductId: 'p',
      ),
      argument('nextProductId', 'p'),
    ),
  );
  for (final path in [
    '',
    'areas[-1].input.sourceText',
    'areas[00].input.sourceText',
    'areas[0].label',
    'outline.radius.x',
  ]) {
    test(
      '경로 "$path"의 잘못된 문법은 인자명과 문제 값으로 거부한다',
      () => expect(
        () => ComparedBasisFields(previousFieldPath: path, nextFieldPath: path),
        argument('previousFieldPath', path),
      ),
    );
  }
  test(
    '영역 경로에 영역 ID가 누락되면 거부한다',
    () => expect(
      () => GeometryTextBasisDifference.value(
        productId: 'p',
        fields: ComparedBasisFields(
          previousFieldPath: 'areas[0].input.sourceText',
          nextFieldPath: 'areas[2].input.sourceText',
        ),
      ),
      argument('areaId', null),
    ),
  );
  test(
    '영역 밖의 차이에 영역 ID를 붙일 수 없다',
    () => expect(
      () => GeometryTextBasisDifference.value(
        productId: 'p',
        areaId: 'a',
        fields: ComparedBasisFields(
          previousFieldPath: 'outline.radius',
          nextFieldPath: 'outline.radius',
        ),
      ),
      argument('areaId', 'a'),
    ),
  );
  test(
    '다른 필드를 이전/다음의 같은 차이라고 묶을 수 없다',
    () => expect(
      () => ComparedBasisFields(
        previousFieldPath: 'areas[0].input.sourceText',
        nextFieldPath: 'areas[1].region.outer',
      ),
      argument('nextFieldPath', 'areas[1].region.outer'),
    ),
  );
  test(
    '추가/삭제는 존재하는 목록 항목 전체만 가리킨다',
    () => expect(
      () => AddedBasisElement('outline.radius'),
      argument('nextFieldPath', 'outline.radius'),
    ),
  );
  test(
    '종류 계열이 다른 값의 변경을 잘못 묶을 수 없다',
    () => expect(
      () => ChangedBasisKinds(
        fields: ComparedBasisFields(
          previousFieldPath: 'outline',
          nextFieldPath: 'outline',
        ),
        previousKind: GeometryTextBasisKind.circleBoundary,
        nextKind: GeometryTextBasisKind.lineTo,
      ),
      argument('nextKind', GeometryTextBasisKind.lineTo),
    ),
  );
  test(
    '같은 종류를 종류 변경으로 표시할 수 없다',
    () => expect(
      () => ChangedBasisKinds(
        fields: ComparedBasisFields(
          previousFieldPath: 'outline',
          nextFieldPath: 'outline',
        ),
        previousKind: GeometryTextBasisKind.circleBoundary,
        nextKind: GeometryTextBasisKind.circleBoundary,
      ),
      argument('nextKind', GeometryTextBasisKind.circleBoundary),
    ),
  );
  test(
    '원소 하위 필드로 경계 종류 변경을 보고할 수 없다',
    () => expect(
      () => ChangedBasisKinds(
        fields: ComparedBasisFields(
          previousFieldPath: 'outline.radius',
          nextFieldPath: 'outline.radius',
        ),
        previousKind: GeometryTextBasisKind.circleBoundary,
        nextKind: GeometryTextBasisKind.pathBoundary,
      ),
      argument('fields.previousFieldPath', 'outline.radius'),
    ),
  );
  test(
    '중복 상세는 목록을 덤프하지 않고 두 위치의 순서 위반을 거부한다',
    () => expect(
      () => BasisDuplicateDetails(
        identifier: 'a',
        firstIndex: 2,
        duplicateIndex: 1,
      ),
      argument('duplicateIndex', 1),
    ),
  );
  test(
    '입력 불일치 상세에는 실제로 다른 정의/입력 ID가 필요하다',
    () => expect(
      () => BasisAreaInputDetails(definitionAreaId: 'a', inputAreaId: 'a'),
      argument('inputAreaId', 'a'),
    ),
  );
  test('제품 ID의 값 차이를 같은 제품의 일반 필드 차이로 보고할 수 없다', () {
    final fields = ComparedBasisFields(
      previousFieldPath: 'productId',
      nextFieldPath: 'productId',
    );
    expect(
      () => GeometryTextBasisDifference.value(productId: 'p', fields: fields),
      argument('position', fields),
    );
  });
}
