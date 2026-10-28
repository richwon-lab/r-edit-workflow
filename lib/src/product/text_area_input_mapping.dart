import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_area_input_mapping.freezed.dart';

/// 이전 제품 입력 하나를 제안 영역 하나로 전달하는 명시적 대응이다.
/// 좌표·label·문구 유사성으로 추정하지 않는다. 빈 ID나 대응 충돌은 준비 진단이다.
@Freezed(
  fromJson: false,
  toJson: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
final class TextAreaInputMapping with _$TextAreaInputMapping {
  /// 원래 문자열을 보존한다. 이전/새 정의의 존재 여부는 준비 함수가 검사한다.
  const TextAreaInputMapping({
    required this.fromAreaId,
    required this.toAreaId,
  });

  /// 기준 제품의 입력/이전 정의 문맥에 속하는 영역 ID다.
  final String fromAreaId;

  /// 제안 형상의 영역 문맥에 속하는 ID다. 같은 문자열도 자동 연결되지 않는다.
  final String toAreaId;
}
