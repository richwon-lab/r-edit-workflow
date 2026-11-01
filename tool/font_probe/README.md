# 로컬 글꼴 메트릭 probe

목적은 [부분 실행 기록](../../docs/font-size-probe.md)의 원본 테이블·기본 glyph 수치와 조건부 비교표 재현이다.
운영 측정 브리지/엔진/지원 글꼴 등록 기능이 아니다. Windows PowerShell 7과 로드 가능한 WPF가 필요하다.
이번 환경은 PowerShell 7.6.9/.NET 10.0.14이며 추가 설치하지 않았다.

```powershell
./tool/font_probe/read_font_metrics.ps1 -FontPath C:/Windows/Fonts/H2GTRE.TTF -OutputDirectory .tooling/font-size-probe-20261101
```

- 입력: 호출자가 확인한 신뢰할 수 있는 로컬 단독 TrueType/OpenType sfnt 파일. TTC/variable font는 명시 거부한다.
  범용/보안 검증된 font parser가 아니며 외부의 손상된 글꼴을 검사하는 데 사용하지 않는다.
- 출력: `font-metrics.json`, `comparison-candidates.csv`, `program-observations.csv`.
  지정 출력 디렉터리의 동명 실험 파일을 덮어쓰므로 전용 경로를 쓴다. 원본 font는 읽기만 한다.
- 글꼴 바이트/윤곽은 복제하지 않는다. 출력은 `.tooling/` 안에 두고 `git check-ignore`로 확인한다.
- 메트릭은 font units. WPF glyph geometry는 em/hinting 크기=unitsPerEm이며 Y 위 baseline 좌표로 기록한다.
  raw glyf bbox(제어점 포함)와 WPF ink 경계를 구분한다. 단순 cmap/advance 합이며 shaping/kerning/문구 전체 측정이 아니다.
- 크기 2/3/5를 em mm라고 **가정한** 계산은 명목 크기 대응 실측이 아니다. 30조건·120개 프로그램 기록행은 미실행 표다.
- 누락 glyph/.notdef를 대체 글꼴·폭 0으로 처리하지 않는다. 복잡한 문자/혼합 글꼴·레이아웃·DXF 출력은 지원하지 않는다.
- 입력 글꼴의 현장 사용·CAD/Type3 매핑·라이선스는 호출자가 별도 확인한다. 도구 성공이 제작·임베딩 허가를 뜻하지 않는다.

실제 프로그램에서 직접 만든 텍스트부터 속성과 기하를 측정하는 순서는 위 실행 기록 5절을 따른다.