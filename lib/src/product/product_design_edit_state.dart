part of 'product_design_edit_session.dart';

/// 단일 isolate의 open 한 번을 나타내는 불투명 수명 토큰이다.
/// const/필드 없는 값 동등성/문자열 복원이 아닌 발급 인스턴스 동일성으로 구분한다.
/// 파일 경로·시각·해시가 아니며 전송/직렬화/다른 isolate 사용을 지원하지 않는다.
final class ProductDesignEditSessionId {
  ProductDesignEditSessionId._();
}

/// 세션이 확정한 구성/개정의 읽기 전용 관찰값이다.
/// 외부 생성·복제·수정·JSON API를 제공하지 않으며 현재 정본 설치에 사용할 수 없다.
final class ProductDesignEditState {
  ProductDesignEditState._({
    required this.configuration,
    required this.sessionId,
    required this.revision,
    required this.isClosed,
  });

  /// 미사용 스냅샷과 순서까지 포함하는 유효 전체 구성이다. 배치/저장 완료가 아니다.
  final ProductDesignConfiguration configuration;

  /// 이 관찰값이 속한 편집 수명의 발급 토큰이다.
  final ProductDesignEditSessionId sessionId;

  /// 실제 수락한 서로 다른 구성 변경 수다. 음수/순환/리셋을 허용하지 않는다.
  final int revision;

  /// 명시적 close 여부다. 구성/개정은 close로 바뀌지 않는다.
  final bool isClosed;
}

/// 준비 시작 시 한 상태에서 캡처한 기준이다. 사후 토큰/개정 결합을 허용하지 않는다.
/// 후보와 마찬가지로 외부 생성·copyWith·JSON 복원을 제공하지 않는다.
final class ProductDesignEditBasis {
  ProductDesignEditBasis._(this._captured);
  final ProductDesignEditState _captured;

  /// 준비에 실제 사용한 전체 불변 기준 값이다.
  ProductDesignConfiguration get configuration => _captured.configuration;

  /// 준비가 시작된 세션 수명이다.
  ProductDesignEditSessionId get sessionId => _captured.sessionId;

  /// 준비가 시작된 실행 개정이다. 최신 값으로 다시 붙일 수 없다.
  int get revision => _captured.revision;
}
