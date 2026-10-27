import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/design/applied_design_geometry.dart';
import 'package:r_edit_workflow/src/design/cutout_definition.dart';
import 'package:r_edit_workflow/src/design/text_area_definition.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/geometry_path.dart';
import 'package:r_edit_workflow/src/geometry/path_segments.dart';
import 'package:r_edit_workflow/src/geometry/point2.dart';
import 'package:r_edit_workflow/src/product/applied_geometry_id_conflict.dart';
import 'package:r_edit_workflow/src/product/product_design_configuration.dart';

/// 유효한 두 구성의 공통 적용 ID가 전체 스냅샷 내용을 보존하는지 검사한다.
///
/// ID로 연결한 AppliedDesignGeometry의 기존 값 동등성을 사용한다.
/// 구성의 적용 목록 재정렬·제품 입력은 비교 대상이 아니며, 내부 목록 순서는 내용이다.
/// 공통 ID 하나의 모든 변경을 한 충돌로 모아 수정 불가 목록으로 반환한다. 순서는 계약이 아니다.
/// 입력을 변경/정렬하거나 로깅하지 않는다. 정상 내용 충돌은 예외가 아니다.
///
/// 빈 결과는 전체 변경 허용/배치·제작·저장 가능 판정이 아니다.
/// 제거 ID의 과거 재사용·A→B→A·제품 보존·영역 대응·안전 반영은 검사하지 않는다.
/// 준비/반영에는 별도 기준/세션·개정 확인이 필요하다.
@useResult
List<AppliedGeometryIdConflict> validateAppliedGeometryIdConsistency({
  required ProductDesignConfiguration previous,
  required ProductDesignConfiguration next,
}) {
  final previousById = {
    for (final (index, value) in previous.appliedGeometries.indexed)
      value.appliedGeometryId: (index, value),
  };
  final conflicts = <AppliedGeometryIdConflict>[];
  for (final (nextIndex, value) in next.appliedGeometries.indexed) {
    final match = previousById[value.appliedGeometryId];
    if (match == null || match.$2 == value) continue;
    final changed = _collectSnapshotChanges(match.$2, value);
    if (changed.isEmpty) {
      // 새 필드의 경로 수집 누락 같은 결함을 정상 충돌로 숨기지 않는다.
      throw StateError('스냅샷 값 비교와 변경 경로 수집이 일치하지 않습니다.');
    }
    conflicts.add(
      AppliedGeometryIdConflict(
        appliedGeometryId: value.appliedGeometryId,
        previousIndex: match.$1,
        nextIndex: nextIndex,
        changedFieldPaths: changed,
      ),
    );
  }
  return List.unmodifiable(conflicts);
}

List<String> _collectSnapshotChanges(
  AppliedDesignGeometry previous,
  AppliedDesignGeometry next,
) {
  final changed = <String>[];
  final a = previous.geometry;
  final b = next.geometry;
  _recordValueChange(
    a.coordinateSpace.lengthUnit,
    b.coordinateSpace.lengthUnit,
    'geometry.coordinateSpace.lengthUnit',
    changed,
  );
  _collectBoundaryChanges(a.outline, b.outline, 'geometry.outline', changed);
  _compareOrderedList(
    a.cutouts,
    b.cutouts,
    'geometry.cutouts',
    changed,
    (a, b, path) => _collectCutoutChanges(a, b, path, changed),
  );
  _compareOrderedList(
    a.textAreas,
    b.textAreas,
    'geometry.textAreas',
    changed,
    (a, b, path) => _collectAreaChanges(a, b, path, changed),
  );
  final oldSource = previous.source;
  final newSource = next.source;
  if (oldSource == null || newSource == null) {
    _recordValueChange(oldSource, newSource, 'source', changed);
  } else {
    _recordValueChange(
      oldSource.sourceDesignId,
      newSource.sourceDesignId,
      'source.sourceDesignId',
      changed,
    );
    _recordValueChange(
      oldSource.sourceRevision,
      newSource.sourceRevision,
      'source.sourceRevision',
      changed,
    );
  }
  return changed;
}

void _collectCutoutChanges(
  CutoutDefinition previous,
  CutoutDefinition next,
  String path,
  List<String> changed,
) {
  _recordValueChange(
    previous.cutoutId,
    next.cutoutId,
    '$path.cutoutId',
    changed,
  );
  _collectBoundaryChanges(
    previous.boundary,
    next.boundary,
    '$path.boundary',
    changed,
  );
}

void _collectAreaChanges(
  TextAreaDefinition previous,
  TextAreaDefinition next,
  String path,
  List<String> changed,
) {
  _recordValueChange(previous.areaId, next.areaId, '$path.areaId', changed);
  _recordValueChange(previous.label, next.label, '$path.label', changed);
  _collectBoundaryChanges(
    previous.region.outer,
    next.region.outer,
    '$path.region.outer',
    changed,
  );
  _compareOrderedList(
    previous.region.exclusions,
    next.region.exclusions,
    '$path.region.exclusions',
    changed,
    (a, b, path) => _collectBoundaryChanges(a, b, path, changed),
  );
}

void _collectBoundaryChanges(
  ClosedBoundary previous,
  ClosedBoundary next,
  String path,
  List<String> changed,
) {
  switch ((previous, next)) {
    case (final CircleBoundary a, final CircleBoundary b):
      _collectPointChanges(a.center, b.center, '$path.center', changed);
      _recordValueChange(a.radius, b.radius, '$path.radius', changed);
    case (final PathBoundary a, final PathBoundary b):
      _collectPathChanges(a.path, b.path, '$path.path', changed);
    default:
      changed.add(path);
  }
}

void _collectPathChanges(
  GeometryPath previous,
  GeometryPath next,
  String path,
  List<String> changed,
) {
  _collectPointChanges(previous.start, next.start, '$path.start', changed);
  _compareOrderedList(
    previous.segments,
    next.segments,
    '$path.segments',
    changed,
    (a, b, path) {
      switch ((a, b)) {
        case (final LineTo a, final LineTo b):
          _collectPointChanges(a.end, b.end, '$path.end', changed);
        case (final ArcTo a, final ArcTo b):
          _collectPointChanges(a.end, b.end, '$path.end', changed);
          _recordValueChange(a.bulge, b.bulge, '$path.bulge', changed);
        default:
          changed.add(path);
      }
    },
  );
}

void _collectPointChanges(
  Point2 previous,
  Point2 next,
  String path,
  List<String> changed,
) {
  _recordValueChange(previous.x, next.x, '$path.x', changed);
  _recordValueChange(previous.y, next.y, '$path.y', changed);
}

void _compareOrderedList<T>(
  List<T> previous,
  List<T> next,
  String path,
  List<String> changed,
  void Function(T, T, String) compare,
) {
  if (previous.length != next.length) {
    changed.add(path);
    return;
  }
  for (var i = 0; i < previous.length; i++) {
    compare(previous[i], next[i], '$path[$i]');
  }
}

void _recordValueChange(
  Object? previous,
  Object? next,
  String path,
  List<String> changed,
) {
  if (previous != next) changed.add(path);
}
