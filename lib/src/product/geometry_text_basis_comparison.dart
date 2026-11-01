import 'package:meta/meta.dart';
import 'package:r_edit_workflow/src/geometry/closed_boundary.dart';
import 'package:r_edit_workflow/src/geometry/geometry_path.dart';
import 'package:r_edit_workflow/src/geometry/path_segments.dart';
import 'package:r_edit_workflow/src/geometry/point2.dart';
import 'package:r_edit_workflow/src/product/geometry_text_basis_differences.dart';
import 'package:r_edit_workflow/src/product/product_geometry_text_basis.dart';
import 'package:r_edit_workflow/src/text_area_input.dart';

/// 두 근거의 형상·문구 부분만 대조한다. 빈 목록은 이 부분의 일치만 뜻한다.
/// 다른 제품이면 productMismatch 하나를 반환한다. 영역은 ID로 연결하고 나머지 순서 있는 목록은 순서도 비교한다.
/// 원본을 정렬/수정하거나 단위 환산·반올림하지 않는다. 반환 목록은 수정 불가이며 순서는 계약이 아니다.
@useResult
List<GeometryTextBasisDifference> compareProductGeometryTextBasis({
  required ProductGeometryTextBasis previous,
  required ProductGeometryTextBasis next,
}) {
  if (previous.productId != next.productId) {
    return List.unmodifiable([
      GeometryTextBasisDifference.productMismatch(
        previousProductId: previous.productId,
        nextProductId: next.productId,
      ),
    ]);
  }
  final differences = <GeometryTextBasisDifference>[];
  final root = _BasisComparison(previous.productId, differences);
  root.value(
    previous.coordinateSpace.lengthUnit,
    next.coordinateSpace.lengthUnit,
    'coordinateSpace.lengthUnit',
  );
  root.boundary(previous.outline, next.outline, 'outline');
  root.ordered(previous.cutouts, next.cutouts, 'cutouts', (a, b, path) {
    root.value(a.cutoutId, b.cutoutId, '$path.cutoutId');
    root.boundary(a.boundary, b.boundary, '$path.boundary');
  });
  final previousIndices = {
    for (final (i, a) in previous.areas.indexed) a.areaId: i,
  };
  final nextIndices = {for (final (i, a) in next.areas.indexed) a.areaId: i};
  for (final entry in previous.areasById.entries) {
    final id = entry.key;
    final a = entry.value;
    final b = next.areasById[id];
    final oldPath = 'areas[${previousIndices[id]}]';
    if (b == null) {
      differences.add(
        GeometryTextBasisDifference.removed(
          productId: previous.productId,
          areaId: id,
          element: RemovedBasisElement(oldPath),
        ),
      );
      continue;
    }
    final area = _BasisComparison(
      previous.productId,
      differences,
      areaId: id,
      previousPrefix: '$oldPath.',
      nextPrefix: 'areas[${nextIndices[id]}].',
    );
    area.boundary(a.region.outer, b.region.outer, 'region.outer');
    area.ordered(
      a.region.exclusions,
      b.region.exclusions,
      'region.exclusions',
      area.boundary,
    );
    area.value(a.input.sourceText, b.input.sourceText, 'input.sourceText');
    switch ((a.input.lineBreak, b.input.lineBreak)) {
      case (AutomaticLineBreak(), SpecifiedLineBreak()):
        area.kind(
          'input.lineBreak',
          GeometryTextBasisKind.automaticLineBreak,
          GeometryTextBasisKind.specifiedLineBreak,
        );
      case (SpecifiedLineBreak(), AutomaticLineBreak()):
        area.kind(
          'input.lineBreak',
          GeometryTextBasisKind.specifiedLineBreak,
          GeometryTextBasisKind.automaticLineBreak,
        );
      case (final SpecifiedLineBreak old, final SpecifiedLineBreak updated):
        if (old != updated) area.changed('input.lineBreak.lines');
      case (AutomaticLineBreak(), AutomaticLineBreak()):
        break;
    }
  }
  for (final id in next.areasById.keys) {
    if (!previous.areasById.containsKey(id)) {
      differences.add(
        GeometryTextBasisDifference.added(
          productId: previous.productId,
          areaId: id,
          element: AddedBasisElement('areas[${nextIndices[id]}]'),
        ),
      );
    }
  }
  return List.unmodifiable(differences);
}

// 이 비교에 필요한 구체 타입만 순회한다. 범용 객체 diff가 아니다.
final class _BasisComparison {
  _BasisComparison(
    this.productId,
    this.differences, {
    this.areaId,
    this.previousPrefix = '',
    this.nextPrefix = '',
  });
  final String productId;
  final List<GeometryTextBasisDifference> differences;
  final String? areaId;
  final String previousPrefix;
  final String nextPrefix;
  ComparedBasisFields fields(String path) => ComparedBasisFields(
    previousFieldPath: '$previousPrefix$path',
    nextFieldPath: '$nextPrefix$path',
  );
  void changed(String path) => differences.add(
    GeometryTextBasisDifference.value(
      productId: productId,
      areaId: areaId,
      fields: fields(path),
    ),
  );
  void value(Object? a, Object? b, String path) {
    if (a != b) changed(path);
  }

  void kind(String path, GeometryTextBasisKind a, GeometryTextBasisKind b) =>
      differences.add(
        GeometryTextBasisDifference.kind(
          productId: productId,
          areaId: areaId,
          kinds: ChangedBasisKinds(
            fields: fields(path),
            previousKind: a,
            nextKind: b,
          ),
        ),
      );
  void point(Point2 a, Point2 b, String path) {
    value(a.x, b.x, '$path.x');
    value(a.y, b.y, '$path.y');
  }

  void boundary(ClosedBoundary a, ClosedBoundary b, String path) {
    switch ((a, b)) {
      case (final CircleBoundary a, final CircleBoundary b):
        point(a.center, b.center, '$path.center');
        value(a.radius, b.radius, '$path.radius');
      case (final PathBoundary a, final PathBoundary b):
        geometryPath(a.path, b.path, '$path.path');
      case (CircleBoundary(), PathBoundary()):
        kind(
          path,
          GeometryTextBasisKind.circleBoundary,
          GeometryTextBasisKind.pathBoundary,
        );
      case (PathBoundary(), CircleBoundary()):
        kind(
          path,
          GeometryTextBasisKind.pathBoundary,
          GeometryTextBasisKind.circleBoundary,
        );
    }
  }

  void geometryPath(GeometryPath a, GeometryPath b, String path) {
    point(a.start, b.start, '$path.start');
    ordered(a.segments, b.segments, '$path.segments', (a, b, path) {
      switch ((a, b)) {
        case (final LineTo a, final LineTo b):
          point(a.end, b.end, '$path.end');
        case (final ArcTo a, final ArcTo b):
          point(a.end, b.end, '$path.end');
          value(a.bulge, b.bulge, '$path.bulge');
        case (LineTo(), ArcTo()):
          kind(path, GeometryTextBasisKind.lineTo, GeometryTextBasisKind.arcTo);
        case (ArcTo(), LineTo()):
          kind(path, GeometryTextBasisKind.arcTo, GeometryTextBasisKind.lineTo);
      }
    });
  }

  void ordered<T>(
    List<T> a,
    List<T> b,
    String path,
    void Function(T, T, String) compare,
  ) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      compare(a[i], b[i], '$path[$i]');
    }
    for (var i = a.length; i < b.length; i++) {
      differences.add(
        GeometryTextBasisDifference.added(
          productId: productId,
          areaId: areaId,
          element: AddedBasisElement('$nextPrefix$path[$i]'),
        ),
      );
    }
    for (var i = b.length; i < a.length; i++) {
      differences.add(
        GeometryTextBasisDifference.removed(
          productId: productId,
          areaId: areaId,
          element: RemovedBasisElement('$previousPrefix$path[$i]'),
        ),
      );
    }
  }
}
