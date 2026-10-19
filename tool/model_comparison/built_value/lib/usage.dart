import 'package:built_collection/built_collection.dart';

import 'model.dart';

// 임시 빌더의 중간 상태가 아니라 build한 값에 업무 검증을 적용한다.
TrialArea create(String source, List<String>? lines) => TrialArea(
  (b) => b
    ..areaId = 'area-1'
    ..sourceText = source
    ..lineBreak.replace(
      lines == null ? TrialBreak.auto() : TrialBreak.manual(lines),
    ),
);
TrialArea replaceText(TrialArea value, String source, List<String> lines) =>
    value.rebuild(
      (b) => b
        ..sourceText = source
        ..lineBreak.replace(TrialBreak.manual(lines)),
    );
TrialArea changeOnlySource(TrialArea value, String source) =>
    value.rebuild((b) => b.sourceText = source);
TrialBreak replaceLines(TrialBreak value, List<String> lines) =>
    value.rebuild((b) => b.lines = BuiltList(lines));
TrialBreak invalidNativeBreak() => TrialBreak((b) => b.mode = 'unknown');

TrialArea changeOnlyLines(TrialArea value, List<String> lines) =>
    value.rebuild((b) => b.lineBreak.lines = BuiltList(lines));
