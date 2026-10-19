import 'model.dart';

// 생성·동시 변경·조회에 실제 사용하는 후보 API.
TrialArea create(String source, List<String>? lines) => TrialArea(
  areaId: 'area-1',
  sourceText: source,
  lineBreak: lines == null ? TrialBreak.auto() : TrialBreak.manual(lines),
);
TrialArea replaceText(TrialArea value, String source, List<String> lines) =>
    value.copyWith(sourceText: source, lineBreak: TrialBreak.manual(lines));
TrialArea changeOnlySource(TrialArea value, String source) =>
    value.copyWith(sourceText: source);
TrialBreak replaceLines(TrialBreak value, List<String> lines) =>
    value.copyWith(lines: lines);
TrialBreak invalidNativeBreak() => TrialBreak(mode: 'unknown');

TrialArea changeOnlyLines(TrialArea value, List<String> lines) =>
    value.copyWith.lineBreak(lines: lines);
