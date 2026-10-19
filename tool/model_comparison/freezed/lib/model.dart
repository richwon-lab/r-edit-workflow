import 'package:freezed_annotation/freezed_annotation.dart';

import 'validation.dart';

part 'model.freezed.dart';
part 'model.g.dart';

// 일반 생성자에서 검증하므로 생성된 copyWith/JSON 경로도 같은 검사를 거친다.
@freezed
@JsonSerializable(explicitToJson: true)
final class TrialArea with _$TrialArea {
  TrialArea({
    required this.areaId,
    required this.sourceText,
    required this.lineBreak,
  }) {
    validateArea(areaId, sourceText, lineBreak.mode, lineBreak.lines);
  }
  final String areaId;
  final String sourceText;
  final TrialBreak lineBreak;

  factory TrialArea.fromJson(Object? json) =>
      _$TrialAreaFromJson(readArea(json));
  Map<String, Object?> toJson() => _$TrialAreaToJson(this);
}

// 두 방식은 명시적 mode로 구분한다. 자동의 lines는 JSON에서 생략한다.
@freezed
@JsonSerializable(includeIfNull: false)
final class TrialBreak with _$TrialBreak {
  TrialBreak({required this.mode, List<String>? lines})
    : lines = lines == null ? null : List.unmodifiable(lines) {
    validateBreak(mode, this.lines);
  }
  factory TrialBreak.auto() => TrialBreak(mode: 'auto');
  factory TrialBreak.manual(List<String> lines) =>
      TrialBreak(mode: 'manual', lines: lines);
  final String mode;
  final List<String>? lines;

  factory TrialBreak.fromJson(Object? json) =>
      _$TrialBreakFromJson(readBreak(json));
  Map<String, Object?> toJson() => _$TrialBreakToJson(this);
}
