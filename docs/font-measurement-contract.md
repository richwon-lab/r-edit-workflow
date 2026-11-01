# 글꼴·측정 근거와 글자 크기 의미 계약 — 설계

검토일 2026-11-01. [최소 probe 부분 실행](font-size-probe.md)에서 설치 후보의 메트릭을 읽었다. 현장 동일성·CAD/Type3·명목↔em은 여전히 미확정이다.

**운영용 글꼴 로딩/파싱/측정/렌더링/엔진/DXF 연결은 구현하지 않았다.** 격리 실험 스크립트와 운영 지원을 구분한다.
모델·필드·측정 도구 이름은 설계 후보이며 새 공개 API/패키지 채택이 아니다.
[저장 결과 정합성](saved-layout-consistency.md), [현행 개발 기준](development-foundation.md),
[기반 보완](development-foundation-additions.md), [실패·로그 계약](failure-diagnostics-logging.md)을 따른다.
ProductGeometryTextBasis는 기하·문구 부분만 담는다. 이 문서로 측정/규칙/그룹까지 완성됐다고 하지 않는다.

## 1. 근거와 우선순위

최신 사용자 결정 → 형제 앱 decisions.md → 논리 설계 → 과거 시험 순으로 해석했다.
형제 앱은 수정하지 않고 다음 자료를 읽었다. 소비자는 형제 폴더 없이도 아래 계약 자체를 이해할 수 있어야 한다.

| 읽은 자료 | 이번에 확인한 범위/한계 |
|---|---|
| 앱 docs/decisions.md·module-boundaries.md | 원문/지정 줄 보존·수량 분리·저장 결과 재열기와 플랫폼/엔진 경계 |
| docs/development-reference/reference/text/리치원_도안데이터_논리설계_초안_v0.1.txt | 영역 내 같은 크기·줄별 자폭, 실제 측정 근거/환경을 결과에 연결 |
| 같은 text 폴더의 리치원_핵심요구사항_설계검토_v0.13.txt | 기본 크기/허용 범위는 작업 기준, 특정 디자인 수치는 전역 기본값 아님. HY의 H 외곽 높이 환산은 Type3/조각 검증 아님 |
| development-reference/docs/03-naming.md | 명목 높이와 실제 획 높이를 구분. 당시 이름 예시는 확정 API가 아님 |
| reference/verification-supplement/req_work/font_size_probe_v01/package/먼저_읽어주세요.txt | DXF 높이 숫자 유지와 실제 외곽 일치는 별개 검사. 과거 preview는 외부 프로그램 실제 화면 아님 |
| reference/verification-supplement/req_work/title_border_fonts/results.json | 과거 제공 글꼴/윤곽 연구 기록과 합성 문구. H 환산·Type3 동등성 미검증이라는 note 확인. 당시 간격/윤곽 평탄화 값을 현재 상수로 채택하지 않음 |

위 경로는 형제 앱 docs/ 아래다. font_size_probe 안내가 참조하는 expected.json·font_metrics.json은
현재 그 package 경로에 없다. 자료 묶음에서 실제 TTF/OTF와 해당 이름의 측정 파일도 찾지 못했다.
다른 연구 JSON의 glyph 자료가 곧 현재 글꼴 원본·허가·측정 계약·CAD 대응을 증명하지는 않는다.
최초 설계 시에는 글꼴 실물/Type3/CAD를 새로 실행하지 않았다. 후속 [부분 probe](font-size-probe.md)는 설치 후보의 메트릭만 읽었으며, 과거 Python 기록을 새 Dart 검증으로 표시하지 않는다.

중요한 기존 기록: 크기 probe 안내는 커터 기준의 사용자 확인을 **CAD/Type3에 표시되는 글자 크기**로 적고 있다.
이를 '특정 문구의 실제 잉크 높이' 또는 '어떤 글꼴에서도 1 em'이라고 바꾸지 않는다.
이 기록의 표시값 의미와 기존 HY 환산의 정확성은 별개의 문제다.

## 2. 첫 지원 방향 — 추천과 결정 게이트

추천 첫 범위는 **실물과 이용 조건을 확인한 글꼴 한 종류/명시 face·style의 가로쓰기**, 원문을 보존한 문구 단위 측정이다.
영역의 모든 줄은 같은 명목 크기를 사용하고 줄마다 자폭을 달리할 수 있다. 이때 동일 크기의 em 환산도 같다.
Latin 대/소문자·숫자·완성형 한글·공백은 최초 시험 대상이지, 자료 없이 이미 지원한다고 선언한 목록이 아니다.
조합 자모·결합 부호·ZWJ·복잡한 script·variable/color font·혼합 폰트 지원은 명시적인 능력 검증 전 보류한다.
지원 밖 문자가 들어왔다고 원문을 바꾸거나 대체 글꼴로 성공 처리하지 않는다.

사용자 크기는 기존 업무의 **제작용 명목 크기**로 유지하고, 계산용 em 크기는 검증된 대응 규약으로 별도 해석하는 안을 추천한다.
추천을 채택하더라도 명목 크기↔em↔DXF/Type3 표시값의 수치 대응은 실물 시험 전 확정할 수 없다.
필요 자료/이용 조건/대상 프로그램/글꼴 식별이 없으면 측정 성공 경로를 구현하지 않는다.
임시 H 환산·공통 보정률·'항상 0.7 em' 같은 상수를 넣어 막힌 부분을 감추지 않는다.

## 3. 다섯 가지 높이/크기를 구분한다

| 값/후보 이름 | 단위·의미 | 같은 값으로 취급하면 안 되는 것 |
|---|---|---|
| 사용자 지정 productionTextSize | 도안 길이 단위의 제작용 명목 크기. CAD 표시값과의 의미 연결이 필요한 업무 입력 | 실제 문구 bbox 높이·Flutter fontSize |
| 계산 emSize | 도안 길이 단위에서 1 em에 대응할 크기 | 명목 크기와 자동 1:1 대응하지 않음 |
| 글꼴 기준 메트릭 | unitsPerEm·cap height·ascent/descent·line gap 등 원래 font units와 출처 테이블/해석 규약 | cap height가 모든 글자의 실제 높이를 뜻하지 않음 |
| 실제 문구 inkBounds | 셰이핑/배치된 glyph 잉크의 범위. baseline 상대 min/max와 실제 높이 | 글꼴 em·행 높이·공백을 포함한 advance |
| 줄 배치 lineBox/줄 간격 | 정해진 전역 메트릭과 추가 줄 간격으로 계산한 배치 높이/기준선 간 거리 | 특정 줄 잉크 bbox 높이에 따라 매번 글자 배율을 바꾸는 것 |

cap height는 일반 대문자 기준, ascent/descent는 기준선 위/아래의 메트릭이다.
OS/2의 음수 descent와 플랫폼 API의 양수 descent 등 부호/출처가 다를 수 있다.
후속 측정 경계가 한 좌표 규약으로 변환하고 원래 출처·단위를 함께 보존해야 한다.
사용하지 않은 테이블 값까지 전부 복제할 필요는 없지만 서로 다른 메트릭을 출처 없이 하나의 height로 합치지 않는다.

### 대안과 추천 이유

| 사용자 크기 해석 | 장점 | 문제/추천 여부 |
|---|---|---|
| 사용자 크기 = em | 수학적으로 명확하고 문구에 독립적 | 기존 CAD/Type3 표시값과 같다는 근거 없음. 업무 입력 의미를 바꾸려면 사용자 결정 필요 |
| 사용자 크기 = 특정 cap/reference 높이 | 문구에 무관한 일정 배율 구성 가능 | 한글·글꼴별 메트릭 품질/기준 glyph·CAD 대응 검증 필요. 과거 H 환산을 정답으로 채택하지 않음 |
| 사용자 크기 = 그 문구의 실제 잉크 높이 | 해당 문구 외곽을 숫자에 맞춤 | 소문자/descender/부호에 따라 em이 달라지고 줄 간 크기 일관성을 깨뜨릴 수 있어 첫 지원 비추천 |
| 제작용 명목 크기 + 검증된 글꼴/대상 프로그램 대응 | 기존 작업 기준을 보존하며 계산/출력 의미를 명시 가능 | 실물 대응 검증이 필요하다는 조건부 추천. 미검증 상태에서 변환계수 생성 금지 |

'3'이 도안 mm 문맥의 사용자 크기라면 **명목 3 mm**다. glyph가 모두 3 mm 높이라는 뜻이 아니다.
계산에서는 검증된 크기 해석이 얻은 emSize와 원래 font units를 사용한다.
화면은 그 설계 길이를 카메라/확대율로 표시한다. 3 logical pixel, 3 physical pixel, 3 pt로 바꿔 해석하지 않는다.
DPI/devicePixelRatio/접근성 글자 확대는 화면 표시/앱 UI 책임이며 제작 기하를 조용히 변경하지 않는다.

DXF는 출력 단위로 환산한 명목/실제 배치와 대상 프로그램 대응 규약을 사용한다.
TEXT의 height/width factor/정렬·STYLE 설정이 어떻게 결합되는지 검증해야 한다.
DXF height=3을 썼다는 사실만으로 Type3 표시값 3 또는 실제 잉크 높이 3을 보장하지 않는다.
CAD 표시 크기만 맞추고 공간 계산용 형상이 다르면 성공이 아니다.

### 문구 변화와 수직 배치

같은 명목 크기·동일 글꼴/조건이면 문구가 H, x, g, 한글로 바뀌어도 측정 단계가 em 배율을 자동 재설정하지 않는다.
잉크 위/아래 끝이 달라지는 것은 실제 glyph 차이로 남긴다. 맞춤 엔진이 규칙에 따라 다른 크기를 선택하는 동작은 별도다.
줄 배치 높이는 명시한 전역 메트릭 원천/간격 규약으로 정하고, 잉크는 영역/홀/여백 검사의 실제 근거로 별도 다룬다.
메트릭 lineBox가 잉크를 항상 포함한다고 가정하지 않는다. accent/overshoot/음수 bearing 등은 실제 경계로 확인한다.
첫 다중 줄 모델은 baseline 간 거리와 추가 간격을 명시하고, OS/2/hhea/플랫폼 행 높이 중 선택한 원천을 기록하는 방향을 추천한다.
어떤 원천을 최초로 사용할지는 대표 글꼴과 CAD 대응 시험 후 결정한다. 없거나 0인 메트릭을 H/1em으로 자동 대체하지 않는다.

제작 계산에는 화면 raster hinting/pixel snapping에 종속되지 않는 design metric/outline 기준을 우선 추천한다.
측정 근거에는 실제 measuring mode·단위·사용 load flags/variation axes·기능 설정을 구분해 기록해야 한다.
도구의 pixel/DIP 값을 가져온 경우 단위를 숨긴 채 font units처럼 사용하지 않는다.
광학 크기 축/힌팅 모드가 결과를 바꾸면 그 실제 설정도 근거다. bitmap 전용 자료를 scalable 윤곽인 것처럼 확대하지 않는다.

## 4. 폭·원점·정렬·변환

| 값 | 쓰임과 보장 범위 |
|---|---|
| advance | 다음 pen 위치까지의 진행량. 공백과 shaping 위치 조정을 포함한 논리 진행 폭 |
| inkBounds | 실제 잉크의 baseline 상대 경계. 좌/우 bearing·기준선 아래 부분을 포함할 수 있음 |
| bearing | pen 원점과 잉크 시작/끝의 관계. 음수일 수 있으므로 advance 구간 밖 잉크도 검사 |
| baseline origin | 줄 첫 pen의 설계 좌표. 첫 보이는 잉크의 왼쪽 아래점과 다름 |
| horizontalScaleRatio | 무차원 수평 변환. 예: 0.8과 80% 표기를 구분. 허용 범위는 작업 규칙에서 별도로 판단 |
| 추가 문자 간격 | shaping 결과에 추가하는 간격. 원래 glyph advance·kerning과 별도 |
| 줄 간격 | baseline 간 거리/추가 leading의 명시적 규약. 문구별 bbox 높이로 암묵 결정하지 않음 |
| 정렬 기준 | 논리 advance 구간 기준인지 잉크 범위 기준인지 명시. 서로 바꿔 쓰지 않음 |

첫 좌표 기준은 기존 도안의 X 오른쪽/Y 위쪽이며, 줄 배치점은 baseline의 첫 pen 원점으로 추천한다.
화면의 Y 아래쪽 및 DXF 출력 배열 이동은 각 경계에서 변환한다. 같은 원점을 임의로 inkBounds.min으로 이동하지 않는다.

수평 정렬은 원문 공백 의도를 보존하는 advance 구간 기준을 첫 추천으로 둔다.
선행/후행 공백을 포함한 중앙/우측 정렬과 잉크 시각 중심 정렬은 다르므로,
현장의 기대를 대표 문구로 확인하기 전 기존 '중앙 중심'을 어느 하나라고 단정하지 않는다.
최소 크기 대응 시험은 좌측/baseline 정렬부터 하여 크기와 중앙 정렬 문제를 분리한다.
실제 영역 중앙 배치 규약은 이 시험 뒤 선택하며, 잉크 중심 정렬이 필요해도 공백을 삭제하지 않는다.

공백은 outline이 없어도 advance가 있을 수 있다. 공백만 있는 원문도 기존 입력처럼 보존한다.
정상 측정의 빈 잉크 범위는 명시적 '잉크 없음'이며, 측정 실패를 width=0이나 빈 사각형으로 정상 처리하는 것과 다르다.
결합 부호 등 정당한 zero advance도 실패와 구분한다. 실패 여부를 숫자 0 하나로 표현하지 않는다.
ink bbox는 contour 그 자체가 아니며 bbox 비교가 글리프/홀의 정확한 충돌 검사라는 뜻도 아니다.

### 문구 단위 측정과 문자별 합

문자별 advance의 합은 한 문자→한 glyph, 고정 font/instance, 명시적으로 kerning/치환/문맥 위치 조정 없음,
해당 문자 집합과 도구의 단순 모드가 실제 검증된 때에만 지원할 수 있다.
이 조건을 확인하지 않은 Latin 문자도 무조건 합산하지 않는다.
AV/To, fi, 조합 부호, 한글 자모, ZWJ, 복잡한 script는 glyph 선택/위치가 문맥에 의존할 수 있다.
문구 전체를 language/script/direction/features가 명시된 run으로 측정하고 cluster 연결을 보존하는 방식을 우선 추천한다.
한 문자열의 prefix 폭을 재거나 독립 단어 폭을 더하면 전체 문자열 shaping과 같다는 보장은 없다.
입력의 자동/직접 줄바꿈은 바뀌지 않으며 실제 측정할 후보 줄을 어떻게 제공할지는 후속 엔진 계약이다.

### 자폭의 적용 순서 추천

1. 실제 font/instance/features로 원문 run을 shaping해 glyph·advance·offset·잉크 근거를 얻는다.
2. 원래 font units를 emSize/unitsPerEm에 따라 도안 길이로 변환한다.
3. baseline 원점을 기준으로 X에 horizontalScaleRatio를 적용한다.
   잉크 X·glyph X offset·진행량·수평 kerning을 함께 변환한다. Y와 글자 높이를 자폭 때문에 바꾸지 않는다.
4. 추가 간격을 지원한다면 그 후 도안 길이 단위로 지정한 간격을 명시한 cluster 경계 사이에 적용하는 안을 추천한다.
   마지막 뒤에 임의 간격을 더하지 않는다. 이 물리 간격은 자폭에 다시 곱하지 않는다.
5. 그 최종 진행 폭/잉크로 정렬 이동을 계산하고 baseline 원점을 결정한다.

cluster는 Unicode 문자 개수와 같지 않다. ligature 내부/결합 부호 사이에 간격을 넣어야 한다면
단순 위치 덧셈 대신 기능 변경/재shaping 정책이 필요하다. 최초 지원에서 추가 간격 기능을 보류할 수도 있다.
'추가 간격 미적용'과 '아직 모르는 간격을 0으로 채움'은 구분한다. 위 순서는 추천이며 도구 기본 tracking 의미를 그대로 가져온 계약이 아니다.

### 합성 수치 예시 — 실제 글꼴/CAD 검증 아님

가상의 unitsPerEm=1000, cap metric=700, ascent=800, descent=-200을 가정한다.
이미 별도로 해석된 emSize가 3 mm라면 font units 1은 0.003 mm이고 cap metric은 2.1 mm가 된다.
이는 **사용자 명목 3을 em 3으로 변환해도 된다는 증거가 아니다.**
실제 문구 잉크가 [yMin=-180, yMax=720]이라면 잉크 높이는 2.7 mm이고, 다른 문구의 잉크 높이는 다를 수 있다.
run advance=2000이고 X ratio=0.8이면 추가 간격 미적용 진행 폭은 4.8 mm다.
잉크와 진행 폭이 함께 X 변환되고 Y는 유지돼야 한다. 위 수치/비율은 예시이며 제품 기본값/보정 계수가 아니다.

## 5. 실제 자원 식별과 보존

| 정보 | 의미/한계 |
|---|---|
| 파일명/접근 경로 | 자원을 찾는 위치/표시. 같은 파일명이 다른 실제 자료일 수 있고 경로는 PC마다 다름 |
| family/style 이름·버전 | 요청/표시/탐색 정보. 파일/face/variation·합성 bold/italic의 실제 내용을 단독 식별하지 못함 |
| fingerprint/hash | 바이트 탐색/교차 확인의 보조 수단. 실제 자원이나 해석 가능한 측정 자료의 내용 대조를 대신하지 않음 |
| 실제 font 자원 | 바이트/face index·관련 실제 설정으로 구분. collection/variable instance가 다르면 이름만으로 동일시하지 않음 |
| 측정 근거 | 사용한 font/instance·측정기/정책·입력 run·units/scale·실제 advance/offset/ink 자료 |

요청 글꼴과 실제 사용 글꼴을 별도로 기록한다. fallback이면 실제 glyph를 제공한 face/run 범위가 드러나야 한다.
첫 제작 지원은 자동 fallback 비허용을 추천한다. 요청한 글꼴/문자가 없으면 정상 배치 자료를 만들지 않는다.
향후 fallback을 지원해도 명시적 사용자 선택·실제 자원별 run·재검증이 필요하다. 같은 family라고 요청 font로 기록하지 않는다.

| 보존 후보 | 용량/독립성 | 재현 범위/한계 |
|---|---|---|
| 이름/버전/hash만 | 작지만 외부 자료 필요 | 자료가 없으면 측정·동일 모습 재현 불가. 단독 근거로 비추천 |
| 사용한 run의 실제 측정 자료 | 입력 길이에 비례. 문서 내 불변 풀 공유 가능 | 저장 폭/위치/근거 해석 가능. 새 문구 측정·정확한 contour/동일 렌더링까지 보장하지 않음 |
| 사용 glyph의 윤곽/배치 자료 | glyph 수/복잡도에 비례. 동일 자원+glyph 단위 공유 가능 | 정확한 사용 형상 재표시에 유리하지만 편집 가능한 CAD TEXT와 다름. 원래 글꼴 전체의 재계산 자료가 아님 |
| 허가된 font 파일/관련 자원 | 크고 라이선스/배포 관리 필요. 파일마다 중복 복사할 필요 없음 | font·측정기/셰이핑 조건이 함께 맞아야 같은 재계산/모습에 접근 가능 |

첫 추천은 **실제 측정한 run과 사용 메트릭/설정·원래 자원 식별을 불변 자료로 보존하고 같은 자료를 공유**하는 것이다.
정확한 화면 재현이 첫 범위에 필요하면 허가된 자원 또는 사용 윤곽 중 무엇을 함께 보존할지 추가 결정한다.
좌표/측정 자료만 있는데 과거 font가 없어도 동일하게 렌더링할 수 있다고 주장하지 않는다.
누락 시 저장 내용은 해석/복원하되 재렌더링/새 문구 측정/재계산의 미지원 상태를 별도로 알린다.
다른 글꼴이나 대략적인 사각형을 실제 결과인 것처럼 보여주거나 현재 근거로 바꾸지 않는다.

윤곽·측정 자료가 글꼴 이용 조건에서 자유롭게 추출/배포 가능한지는 별도 검토다.
font 임베딩 권한 비트나 이름만으로 모든 계약 조건을 판단하지 않는다.
실제 파일의 라이선스/구입 조건/배포 형태를 확인하기 전 임베딩·부분 추출·변환·배포 가능을 단정하지 않는다.

## 6. 패키지 책임과 전달 값

| 경계 | 책임과 전달 값 |
|---|---|
| 앱 플랫폼 자원 접근 | 사용자 선택/설치 자원 접근·허가/경로·실제 바이트/face 확보. workflow에 파일 경로를 따라 읽게 하지 않음 |
| 측정 담당 경계 | 실제 font/입력 run/기능/방향·단위를 받아 선택 glyph·진행량·offset·메트릭/잉크·지원 진단을 반환 |
| 순수 workflow | 요청/실제 자원 식별, 사용한 메트릭/설정·입력 대응·단위/수치·지원 범위를 자기 값으로 검증/보존 |
| 배치 엔진 | 명시 측정 자료·형상·문구/규칙을 받아 줄/크기/자폭/위치를 선택. 이름으로 시스템 font를 재조회하거나 파일 스키마 해석하지 않음 |
| 화면 | 확정 설계 좌표를 표시 좌표로 변환. 위젯의 자동 줄바꿈/대체 font로 결과를 재작성하지 않음 |
| DXF | 확정 문구/좌표/크기/자폭과 검증된 출력 대응으로 표현. 다시 배치·재측정해 다른 결과를 만들지 않음 |

이것은 책임 경계이지 별도 저장소/범용 Adapter/플러그인 체계를 지금 만들라는 뜻이 아니다.
측정 경계의 실제 소유 파일/패키지는 최초 실기 후 필요한 범위만 결정한다. workflow에 Flutter/플랫폼 font 접근/파일 I/O를 넣지 않는다.
측정 라이브러리 객체·font face 핸들·Flutter TextPainter/Paragraph를 공개 업무 값이나 작업 JSON으로 저장하지 않는다.
엔진/DXF가 앱 또는 작업 파일 스키마에 의존하지 않도록 workflow에서 공개 값으로 변환한다.

기존 UTF-8 내부 원문과 Type3/DXF 인코딩 변환도 분리한다. 출력 불가 문자를 '?'로 대체하지 않는다.
실제 출력 프로필이 shaping/추가 간격/편집 가능한 TEXT를 표현할 수 없으면 출력 지원 불가로 구분한다.
묵시적으로 윤곽화하거나 문자별 TEXT로 분해해 문자 의미를 잃는 대안을 성공으로 채택하지 않는다.

## 7. 측정 도구 비교 — 미채택, 설치 없음

공식 자료를 2026-11-01 확인했다. SDK/도구 버전은 변경하지 않는다.
이번에는 새 라이브러리/바인딩 버전을 선정하지 않았으며 아래 비교가 채택 결정은 아니다.

| 후보 | 공식 유지/라이선스·Windows | 고정 SDK·역할·한계 |
|---|---|---|
| 기존 Flutter TextPainter/Paragraph | 현재 Flutter SDK API, Flutter BSD-3-Clause. 앱 Windows renderer 사용 가능 | 3.47.7의 TextStyle source에서도 em/행 높이 구분 확인. 실제 font 매칭·fallback/잉크/윤곽·CAD 동일성은 미검증. UI 측정값을 제작 길이로 바로 저장하는 경로는 채택하지 않음 |
| Windows DirectWrite | Microsoft의 Windows API/문서와 실제 face·glyph metric/run/outline 기능. 별도 Dart 패키지 라이선스는 채택하지 않음 | 앱 네이티브 경계 후보. Windows SDK/OS 이용 조건과 브리지 구현 필요. 이 SDK 조합에서의 Dart 연결·측정 정확성은 아직 미검증 |
| FreeType + HarfBuzz | 공식 프로젝트/문서·릴리스 경로 유지. FreeType FTL 또는 GPLv2, HarfBuzz Old MIT 및 하위 파일 고지 확인 필요 | 자원/윤곽과 shaping 역할을 구분. Windows 빌드/배포 및 Dart 3.13.5 FFI 바인딩/AOT 조합은 미검증. 버전·전이 의존성·배포 라이선스를 검토하기 전 추가하지 않음 |

글리프 metric API만 있다는 이유로 문구 shaping을 대체하지 않는다.
기존/버전에 따른 FreeType kerning 지원 설명 차이도 있어, 특정 빌드 옵션·버전을 실제로 확인해야 한다.
현재 logging/Riverpod/Freezed/json_serializable은 측정 라이브러리가 아니며 별도 상태/DI/Result 패키지를 추가할 이유도 없다.
추천은 먼저 대표 font/대상 CAD의 대응을 확인하고 그 질문을 충족하는 작은 측정 경계 하나를 고르는 것이다.
버전 번호가 최신이라는 이유나 이름이 동일하다는 이유로 채택하지 않는다.

## 8. 실패·진단

| 구분 | 필요한 구조화 정보/호출자 대응 |
|---|---|
| fontNotFound | 요청한 자원/face 식별·조회 연산. 다른 font로 대체하지 않고 자원 재연결 |
| glyphMissing | 실제 face 식별·문제 구간/코드 포인트, 지원 범위. .notdef/fallback을 정상 glyph로 저장하지 않음 |
| fallbackOccurred | 요청/실제 자원 식별과 해당 run 범위·발생 연산. 첫 추천 정책에서는 정상 제작 측정으로 수락하지 않음 |
| unsupportedFeatureOrScript | 실제 요청 기능/방향/script·지원 범위. 허용하지 않은 문자 분해/정규화로 우회하지 않음 |
| measurementResourceMismatch | 기대/실제 자원/instance·내용 검증 결과·정책 식별. 같은 family/version/hash만으로 내용 정합성 대체하지 않음 |
| measurementFailed | 실제 연산·수치/상태·원래 원인/최초 스택. 폭 0·빈 bbox를 실패 대체값으로 사용하지 않음 |
| sizeMappingUnverified / outputProfileMismatch | 명목↔em 또는 대상 CAD 대응 규약 부재/불일치. 임의 보정률 대신 시험/설정 검토 |

이름은 진단 후보이며 enum/API를 구현하지 않았다. 작은 구체 상세를 사용하고 임의 Map이나 거대한 nullable 진단형을 만들지 않는다.
원문·전체 font 바이트/윤곽·측정 객체/전체 JSON·민감 경로를 예외 문자열/로그로 덤프하지 않는다.
원인·하위 상세·최초 스택은 보존하고 변환 경계를 구분한다. 정상 지원 거부와 내부 Error를 섞지 않으며 최종 경계에서 한 번 기록한다.

문자 위치가 필요하면 측정 요청 원문의 **UTF-16 코드 단위 [start,end)**를 진단 후보로 명시한다.
glyph/cluster index와 구분하고 문자열 길이/추출·surrogate pair 경계를 후속 측정 지원 규약에서 검증한다.
바인딩이 UTF-8 byte cluster를 반환하면 원문을 보존한 명시 변환 자료가 필요하다.
결합 문자/ZWJ의 분할 정책은 아직 미정이다. 이번 기존 TextAreaInput/ProductGeometryTextBasis에 문자 경계 검증을 추가하지 않는다.

## 9. 필요한 최소 실기 계획

먼저 대표 font 한 종류의 정확한 파일/face·이용 조건, 사용 CAD/Type3 버전·글꼴 매핑,
명목 크기/자폭 속성값을 확인할 샘플을 확보한다. 전체 작업 파일/실제 고객 원문을 무조건 요구하지 않는다.
허가된 합성 문구와 확인용 비생산 DXF/화면을 사용한다. 기존 probe 파일을 실제로 확보할 수 있을 때만 재사용한다.
크기 대응 검증은 실제 glyph 기하 치수와 표시 속성값을 나란히 기록하고, 스크린샷 픽셀만으로 mm 정확성을 인증하지 않는다.

| 사례 | 최소 확인 |
|---|---|
| H/A, x/a, g/p, 숫자·완성형 한글 | 명목 크기 고정 시 em 배율 유지, cap/descender/실제 ink의 차이와 전역 메트릭 비교 |
| AV/To/fi | 단순 합과 run shaping의 차이. 채택 features/kerning/ligature 설정과 glyph 연결 기록 |
| 반복/앞뒤 공백·공백만 | 원문 일치·advance/빈 잉크 구분·baseline/중앙 정렬의 기대 동작 확인 |
| 결합 문자·자모·ZWJ | 요청 자원 커버리지·cluster/offset과 fallback/미지원 진단. 통과 문자 집합만 첫 지원으로 채택 |
| 같은 family/style이지만 다른 파일/face | 실제 자원 차이 검출, 이전 측정 자료를 자동 재사용하지 않음 |
| 자폭 두 값·고정 baseline | X ink/advance 동시 변환·Y 유지. 추가 간격을 적용하면 그 순서/단위도 별도 확인 |
| 과거 font 자원 없음 | 저장 metric/좌표/원문은 복원 가능하되 동일 렌더링/새 측정 미지원이 분리됨 |
| 화면↔DXF↔CAD/Type3 | 먼저 좌측 baseline에서 표시 크기·ink 경계·advance/원점을 비교, 이후 중앙/우측·다중 줄 검토 |

실물의 허용 차이/오차 예산은 단위·곡선 근사·렌더러·실제 가공 요구를 보고 별도 결정한다.
과거 연구의 H 비율·평탄화 간격·홀 여유 값을 전역 보정/공차로 채택하지 않는다.
이번 합성 수치 예시는 수학적 계약 설명이며 실제 font/Type3 측정 성공이 아니다.

## 10. 확정·추천·미정과 다음 한 가지

- 확정 요구: 원문·공백 보존, 명목/실제 잉크/행 높이 분리, 설계 단위와 화면 pixel 분리,
  요청/실제 font 구분, 미지원/누락을 가짜 폭·fallback으로 정상화하지 않음, 저장 복원과 재현/재계산 분리,
  workflow의 순수 값/모듈 경계, 미실기 결과를 성공으로 보고하지 않음.
- 추천: 제작용 명목 크기+검증된 em 대응, 한 font/명시 face·가로쓰기의 run 측정부터,
  baseline pen 원점·advance 정렬과 ink 검사 분리, 자폭의 일관 X 변환, 실제 사용 측정 자료 공유 보존.
- 미정/사용자 결정 필요: 대표 실제 font/이용 조건·CAD/Type3 대상과 '3'의 표시 기준 채택,
  명목↔em 대응·lineBox 메트릭 원천/간격·정렬의 현업 기대, 추가 간격·최초 문자 범위,
  허가된 font/사용 윤곽의 보존 여부·정확한 재현 범위·측정 도구/브리지/버전.

다음 한 가지는 **대표 글꼴 한 종류의 자료·이용 조건·CAD/Type3 표시 기준을 확보하고 명목 크기↔em 대응을 최소 실기로 확인**하는 것이다.
자료가 없으면 필요한 자료/미확정 이유를 보고한다. 이 설계를 핑계로 가짜 metric 모델이나 로더를 먼저 만들지 않는다.
결과/확인/저장 전체 모델·계정·UI·동기화는 다음 범위에 자동 포함하지 않는다.

### 공식 자료 확인 위치

2026-11-01 공식 문서/라이선스 확인이며 실제 채택/실행 근거와 구분한다.
- [OpenType head/unitsPerEm](https://learn.microsoft.com/en-us/typography/opentype/otspec190/head),
  [OS/2 메트릭·임베딩 정보](https://learn.microsoft.com/en-us/typography/opentype/spec/os2).
- [DirectWrite font metrics](https://learn.microsoft.com/en-us/windows/win32/api/dwrite/ns-dwrite-dwrite_font_metrics),
  [glyph/run](https://learn.microsoft.com/en-us/windows/win32/directwrite/glyphs-and-glyph-runs),
  [glyph metrics](https://learn.microsoft.com/windows/win32/api/dwrite/ns-dwrite-dwrite_glyph_metrics).
- [Flutter TextStyle.height](https://api.flutter.dev/flutter/painting/TextStyle/height.html),
  [TextPainter](https://api.flutter.dev/flutter/painting/TextPainter-class.html).
  최신 웹 문서와 별도로 고정 SDK packages/flutter/lib/src/painting/text_style.dart를 대조했다.
- [Autodesk TEXT](https://help.autodesk.com/cloudhelp/2024/ENU/AutoCAD-DXF/files/GUID-62E5383D-8A14-47B4-BFC4-35824CAE8363.htm),
  [STYLE](https://help.autodesk.com/cloudhelp/2018/ENU/AutoCAD-DXF/files/GUID-EF68AF7C-13EF-45A1-8175-ED6CE66C8FC9.htm).
- [FreeType 프로젝트/유지 공지](https://freetype.org/index), [metric API](https://freetype.org/freetype2/docs/reference/ft2-glyph_retrieval.html),
  [라이선스](https://freetype.org/license.html).
- [HarfBuzz shaping](https://harfbuzz.github.io/shaping-concepts.html),
  [공식 저장소](https://github.com/harfbuzz/harfbuzz), [COPYING](https://raw.githubusercontent.com/harfbuzz/harfbuzz/main/COPYING).

### 이번 변경의 실제 검증

2026-11-01, 고정 Flutter 3.47.7/Dart 3.13.5로 진단 테스트 파일 단독 29건과 관련 파일 분석을 통과했다.
격리된 enum 사본에 종류를 추가했을 때 NON_EXHAUSTIVE_SWITCH_EXPRESSION이 발생해 분류 누락 검출을 확인했다.
표준 `./tool/fvm.ps1 dart tool/verify.dart`를 한 번 실행해 전체 629건, 생성 시작 상태 일치·반복 안정성,
포맷·strict 분석·문서 검사·기존 AOT·생성기 없는 소비자 검증을 통과했다.
실제 글꼴 측정·CAD/Type3 실기·원격 CI는 실행하지 않았다. 합성 수치는 실기 검증 결과가 아니다.