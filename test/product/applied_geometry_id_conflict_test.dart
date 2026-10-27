import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

void main() {
  group('공통 적용 ID 충돌 진단', () {
    test('외부 경로 목록 변경을 방어하고 위치와 한국어 대응 설명을 제공한다', () {
      final paths = ['geometry.outline.radius', 'source.sourceRevision'];
      final conflict = AppliedGeometryIdConflict(
        appliedGeometryId: ' g ',
        previousIndex: 2,
        nextIndex: 5,
        changedFieldPaths: paths,
      );
      paths.clear();
      expect(conflict.appliedGeometryId, ' g ');
      expect(conflict.changedFieldPaths, [
        'geometry.outline.radius',
        'source.sourceRevision',
      ]);
      expect(conflict.fieldPath, 'next.appliedGeometries[5]');
      expect(
        conflict.code,
        AppliedGeometryIdConflictCode.snapshotContentConflict,
      );
      expect(conflict.code.description, contains('새 ID'));
      expect(
        conflict.toString(),
        allOf(
          contains('snapshotContentConflict'),
          contains(conflict.fieldPath),
          contains('previousIndex=2'),
          contains('source.sourceRevision'),
        ),
      );
      expect(() => conflict.changedFieldPaths.clear(), throwsUnsupportedError);
    });
    for (final (
          name,
          id,
          oldIndex,
          newIndex,
          paths,
          argumentName,
          invalidValue,
          explanation,
        )
        in <
          (String, String, int, int, List<String>, String, Object, List<String>)
        >[
          (
            '빈 ID',
            '',
            0,
            0,
            ['source'],
            'appliedGeometryId',
            '',
            ['ID', '빈 문자열'],
          ),
          (
            '음수 이전 위치',
            'g',
            -1,
            0,
            ['source'],
            'previousIndex',
            -1,
            ['이전', '0 이상'],
          ),
          ('음수 이후 위치', 'g', 0, -2, ['source'], 'nextIndex', -2, ['다음', '0 이상']),
          (
            '빈 경로 목록',
            'g',
            0,
            0,
            [],
            'changedFieldPaths',
            <String>[],
            ['목록', '하나 이상'],
          ),
          (
            '비연속 중복 경로',
            'g',
            0,
            0,
            ['source', 'geometry.outline.radius', 'source'],
            'changedFieldPaths[2]',
            'source',
            ['중복', '첫 위치: changedFieldPaths[0]'],
          ),
          (
            '줄 끝 개행 경로',
            'g',
            0,
            0,
            ['source', 'source\n'],
            'changedFieldPaths[1]',
            'source\n',
            ['필드 경로', '문법'],
          ),
          (
            '빈 개별 경로',
            'g',
            0,
            0,
            ['source', ''],
            'changedFieldPaths[1]',
            '',
            ['필드 경로', '문법'],
          ),
          (
            '다른 모델 필드',
            'g',
            0,
            0,
            ['source', 'products[0].sourceText'],
            'changedFieldPaths[1]',
            'products[0].sourceText',
            ['필드 경로', '문법'],
          ),
          (
            '음수 목록 위치',
            'g',
            0,
            0,
            ['source', 'geometry.cutouts[-1].cutoutId'],
            'changedFieldPaths[1]',
            'geometry.cutouts[-1].cutoutId',
            ['필드 경로', '문법'],
          ),
          (
            '존재하지 않는 필드 종류',
            'g',
            0,
            0,
            ['source', 'geometry.holes'],
            'changedFieldPaths[1]',
            'geometry.holes',
            ['필드 경로', '문법'],
          ),
          (
            '출처 하위 잘못된 필드',
            'g',
            0,
            0,
            ['source', 'source.revision'],
            'changedFieldPaths[1]',
            'source.revision',
            ['필드 경로', '문법'],
          ),
          (
            'JSON 전용 kind',
            'g',
            0,
            0,
            ['source', 'geometry.outline.kind'],
            'changedFieldPaths[1]',
            'geometry.outline.kind',
            ['필드 경로', '문법'],
          ),
        ]) {
      test('$name 오류는 인자·문제 값·위반 조건을 제공한다', () {
        expect(
          () => AppliedGeometryIdConflict(
            appliedGeometryId: id,
            previousIndex: oldIndex,
            nextIndex: newIndex,
            changedFieldPaths: paths,
          ),
          throwsA(
            isA<ArgumentError>()
                .having((error) => error.name, 'name', argumentName)
                .having(
                  (error) => error.invalidValue,
                  'invalidValue',
                  invalidValue,
                )
                .having(
                  (error) => error.message,
                  'message',
                  allOf(explanation.map(contains).toList()),
                ),
          ),
        );
      });
    }
    test('항목 오류 출력은 전체 목록을 덤프하지 않고 문제 값과 위치만 제공한다', () {
      try {
        AppliedGeometryIdConflict(
          appliedGeometryId: 'g',
          previousIndex: 0,
          nextIndex: 0,
          changedFieldPaths: ['geometry.textAreas[12].label', 'bad-path'],
        );
        fail('잘못된 경로 허용');
        // 진단 API 오용 정보 자체를 검사하는 테스트 경계다.
        // ignore: avoid_catching_errors
      } on ArgumentError catch (error) {
        expect(error.name, 'changedFieldPaths[1]');
        expect(error.invalidValue, 'bad-path');
        expect(error.message, contains('문법'));
        expect(
          error.toString(),
          isNot(contains('geometry.textAreas[12].label')),
        );
      }
    });
  });
}
