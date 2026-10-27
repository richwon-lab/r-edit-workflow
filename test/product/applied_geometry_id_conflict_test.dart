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
    for (final (name, id, oldIndex, newIndex, paths)
        in <(String, String, int, int, List<String>)>[
          ('빈 ID', '', 0, 0, ['source']),
          ('음수 이전 위치', 'g', -1, 0, ['source']),
          ('음수 이후 위치', 'g', 0, -1, ['source']),
          ('줄 끝 개행 경로', 'g', 0, 0, ['source\n']),
          ('빈 개별 경로', 'g', 0, 0, ['']),
          ('빈 경로 목록', 'g', 0, 0, []),
          ('중복 경로', 'g', 0, 0, ['source', 'source']),
          ('다른 모델 필드', 'g', 0, 0, ['products[0].sourceText']),
          ('음수 목록 위치', 'g', 0, 0, ['geometry.cutouts[-1].cutoutId']),
          ('존재하지 않는 필드 종류', 'g', 0, 0, ['geometry.holes']),
          ('출처 하위 잘못된 필드', 'g', 0, 0, ['source.revision']),
          ('JSON 전용 kind', 'g', 0, 0, ['geometry.outline.kind']),
        ]) {
      test('$name 진단 구성은 정상 충돌로 숨기지 않고 ArgumentError로 거부한다', () {
        expect(
          () => AppliedGeometryIdConflict(
            appliedGeometryId: id,
            previousIndex: oldIndex,
            nextIndex: newIndex,
            changedFieldPaths: paths,
          ),
          throwsArgumentError,
        );
      });
    }
  });
}
