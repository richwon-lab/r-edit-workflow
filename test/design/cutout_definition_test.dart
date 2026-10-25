import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart' show circleCenteredAt2, designError;

void main() {
  group('CutoutDefinition의 관통 경계', () {
    {
      test('빈 관통 ID 생성을 거부한다', () {
        expect(
          () => CutoutDefinition(cutoutId: '', boundary: circleCenteredAt2()),
          designError(DesignErrorCode.emptyCutoutId, 'cutoutId'),
        );
      });
    }

    {
      test('관통 ID를 빈 값으로 수정하면 거부한다', () {
        expect(
          () => CutoutDefinition(
            cutoutId: 'h',
            boundary: circleCenteredAt2(),
          ).copyWith(cutoutId: ''),
          designError(DesignErrorCode.emptyCutoutId, 'cutoutId'),
        );
      });
    }

    {
      final json = CutoutDefinition(
        cutoutId: 'h',
        boundary: circleCenteredAt2(),
      ).toJson();
      for (final key in json.keys) {
        test('CutoutDefinition JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => CutoutDefinition.fromJson(missing),
            designError(DesignErrorCode.missingField, key),
          );
        });
      }
      test('CutoutDefinition JSON의 최상위 목록을 거부한다', () {
        expect(
          () => CutoutDefinition.fromJson([]),
          designError(DesignErrorCode.invalidType, r'$'),
        );
      });
      test('CutoutDefinition JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => CutoutDefinition.fromJson({...json, 'extra': true}),
          designError(DesignErrorCode.unexpectedField, 'extra'),
        );
      });
    }
  });
}
