# r_edit_workflow

R-edit의 작업 데이터, 변경 영향, 결과 확인 및 저장·출력 흐름을 관리하는 순수 Dart 라이브러리다.

## 책임과 의존 방향

작업 파일·제품·텍스트 영역의 데이터 모델, 수정에 따른 재계산 대상 관리와 이전 결과 무효화,
계산 요청과 현재 입력에 맞는 결과 수락, 작업자 확인과 저장 가능 여부,
저장·불러오기 및 배치 엔진·DXF 기능 연결을 담당할 예정이다.

의존 방향은 Flutter 앱 → 이 패키지 → 배치 엔진·DXF 패키지의 공개 API다.
Flutter 화면, 플랫폼의 폰트 측정, 실제 문구 배치 알고리즘, DXF 작성 자체는 외부 책임이다.
엔진과 DXF 패키지는 앱이나 작업 파일 저장 형식에 역으로 의존하지 않는다.

## 현재 상태

초기 구성과 개발 문서만 있다. 공개 진입점은 lib/r_edit_workflow.dart이며 현재 공개 업무 API는 없다.
업무 모델, JSON 저장 형식, 배치·저장·출력 기능과 실제 테스트는 아직 없다.
내부 구현이 생길 때 lib/src를 사용하고 공개 API만 진입점에서 노출한다.
문서의 필드·클래스 예시는 확정 API가 아니며 실제 구현 시 업무 의미에 맞춰 이름을 정한다.

## 개발과 검증

확인한 실제 환경은 Windows x64, Dart SDK 3.12.2 stable이다.
형제 앱 ../r_edit/pubspec.yaml과 이 패키지 모두 SDK 제약 ^3.12.2를 사용한다.
Flutter SDK에 포함된 Dart를 사용해도 패키지 자체는 Flutter에 의존하지 않는다.
개발 의존성은 순수 Dart용 lints와 test이며 기존 버전 제약을 유지한다.

프로젝트 루트에서 실행한다.

~~~powershell
dart --version
dart pub get
dart format lib
dart analyze
# 실제 테스트가 추가된 뒤 실행
dart test
~~~

현재는 테스트 없음이다. 이를 테스트 통과로 취급하지 않는다.
소스 디렉터리가 추가되면 존재하는 디렉터리만 format 대상에 포함한다.
라이브러리의 pubspec.lock, .dart_tool, IDE 설정과 로컬 override는 커밋하지 않는다.

## 기준 문서

- [개발 지침](AGENTS.md)
- [현재 계약](docs/contract.md)
- [완료 범위와 다음 작업](docs/next-step.md)
- 형제 앱 [현재 결정](../r_edit/docs/decisions.md), [모듈 경계](../r_edit/docs/module-boundaries.md)
- 형제 앱 [README](../r_edit/README.md)

참고한 앱 HEAD: ac11bd44cf098f3cc16b69b2d82d67eb94d1844a.
요청된 ../r_edit/docs/README.md와
../r_edit/docs/development-reference/templates/r_edit_workflow/AGENTS.md는 확인 당시 없었다.
누락 내용을 추측하지 않으며 전체 요구사항·XLSX·과거 검증 자료를 이 저장소에 반복 복사하지 않는다.
