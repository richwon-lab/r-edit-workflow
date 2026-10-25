import 'package:r_edit_workflow/r_edit_workflow.dart';
import 'package:test/test.dart';

import '../support/design_builders.dart'
    show
        circleCenteredAt2,
        designError,
        rectangularBoundary4By2,
        slotBoundaryFrom1To3,
        textAreaWithCircularRegion;

void main() {
  group('TextRegion의 외부·제외 경계', () {
    {
      final json = textAreaWithCircularRegion('a').region.toJson();
      for (final key in json.keys) {
        test('TextRegion JSON에서 $key 누락을 보정하지 않는다', () {
          final missing = Map<String, Object?>.of(json)..remove(key);
          expect(
            () => TextRegion.fromJson(missing),
            designError(DesignErrorCode.missingField, key),
          );
        });
      }
      test('TextRegion JSON의 최상위 목록을 거부한다', () {
        expect(
          () => TextRegion.fromJson([]),
          designError(DesignErrorCode.invalidType, r'$'),
        );
      });
      test('TextRegion JSON의 알 수 없는 필드를 거부한다', () {
        expect(
          () => TextRegion.fromJson({...json, 'extra': true}),
          designError(DesignErrorCode.unexpectedField, 'extra'),
        );
      });
    }

    test('제외 경계를 수정해도 전달 목록과 기존 영역은 서로 영향을 주지 않는다', () {
      final original = TextRegion(
        outer: circleCenteredAt2(10),
        exclusions: [slotBoundaryFrom1To3()],
      );
      final replacements = <ClosedBoundary>[rectangularBoundary4By2()];
      final changed = original.copyWith(exclusions: replacements);
      replacements.clear();
      expect(changed.exclusions, [rectangularBoundary4By2()]);
      expect(original.exclusions, [slotBoundaryFrom1To3()]);
      expect(() => changed.exclusions.clear(), throwsUnsupportedError);
    });
  });
}
