<#
.SYNOPSIS
지정한 단일 sfnt의 기록용 메트릭을 읽는다. 실험 전용이며 운영 API가 아니다.
#>
param(
  [Parameter(Mandatory)][string]$FontPath,
  [Parameter(Mandatory)][string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore
$fontFile = Get-Item -LiteralPath $FontPath
$bytes = [IO.File]::ReadAllBytes($fontFile.FullName)
function Read-U16([int]$offset) { [int]$bytes[$offset] * 256 + [int]$bytes[$offset + 1] }
function Read-I16([int]$offset) {
  $value = Read-U16 $offset
  if ($value -ge 32768) { $value - 65536 } else { $value }
}
function Read-U32([int]$offset) {
  [long]$bytes[$offset] * 16777216 + [long]$bytes[$offset + 1] * 65536 +
    [long]$bytes[$offset + 2] * 256 + [long]$bytes[$offset + 3]
}
# TTC/variable font는 이 실험 범위 밖이며 face를 추정하지 않는다.
$signature = [Text.Encoding]::ASCII.GetString($bytes, 0, 4)
if ($signature -eq 'ttcf') { throw 'TTC is not supported: choose an explicit standalone face.' }
if ((Read-U32 0) -ne 65536 -and $signature -ne 'OTTO') { throw 'Unsupported sfnt signature.' }
$tables = @{}
for ($i = 0; $i -lt (Read-U16 4); $i++) {
  $entry = 12 + 16 * $i
  $tag = [Text.Encoding]::ASCII.GetString($bytes, $entry, 4)
  $tables[$tag] = [int](Read-U32 ($entry + 8))
}
if ($tables.ContainsKey('fvar')) { throw 'Variable font is outside this probe.' }
$head = $tables['head']; $hhea = $tables['hhea']; $os2 = $tables['OS/2']; $name = $tables['name']
$unitsPerEm = Read-U16 ($head + 18)
# name은 Windows Unicode/Unicode platform 원문을 보존하며 다른 인코딩은 추정하지 않는다.
$names = @(
  for ($i = 0; $i -lt (Read-U16 ($name + 2)); $i++) {
    $entry = $name + 6 + 12 * $i
    $platform = Read-U16 $entry; $encoding = Read-U16 ($entry + 2)
    $id = Read-U16 ($entry + 6)
    if ($id -notin @(1,2,4,5,6,16,17) -or
      !($platform -eq 0 -or ($platform -eq 3 -and $encoding -in @(0,1,10)))) { continue }
    $length = Read-U16 ($entry + 8)
    $offset = $name + (Read-U16 ($name + 4)) + (Read-U16 ($entry + 10))
    [ordered]@{nameId=$id;platformId=$platform;encodingId=$encoding;
      languageId=(Read-U16 ($entry + 4));value=[Text.Encoding]::BigEndianUnicode.GetString($bytes,$offset,$length)}
  }
)
$face = [Windows.Media.GlyphTypeface]::new([Uri]$fontFile.FullName)
$metrics = [ordered]@{
  schema='local-font-probe-v1'; status='installed-candidate-not-confirmed-production-font'
  fileName=$fontFile.Name;byteLength=$bytes.Length;sha256=(Get-FileHash -LiteralPath $fontFile.FullName -Algorithm SHA256).Hash
  collectionFaceIndex=0; collection=$false; names=$names
  unitsPerEm=$unitsPerEm; fontRevision=(Read-U32 ($head + 4))/65536.0
  hhea=[ordered]@{ascender=(Read-I16 ($hhea+4));descender=(Read-I16 ($hhea+6));lineGap=(Read-I16 ($hhea+8))}
  os2=[ordered]@{version=(Read-U16 $os2);fsType=(Read-U16 ($os2+8));
    typoAscender=(Read-I16 ($os2+68));typoDescender=(Read-I16 ($os2+70));typoLineGap=(Read-I16 ($os2+72));
    winAscent=(Read-U16 ($os2+74));winDescent=(Read-U16 ($os2+76))}
  tool=[ordered]@{powershell=$PSVersionTable.PSVersion.ToString();runtime=[Runtime.InteropServices.RuntimeInformation]::FrameworkDescription;
    assembly=$face.GetType().Assembly.FullName;fileVersion=$face.GetType().Assembly.GetName().Version.ToString();
    method='WPF GetGlyphOutline(renderingEmSize=unitsPerEm,hintingEmSize=unitsPerEm); per-character cmap; no shaping/kerning'}
}
if ((Read-U16 $os2) -ge 2) {
  $metrics.os2['xHeight'] = Read-I16 ($os2+86)
  $metrics.os2['capHeight'] = Read-I16 ($os2+88)
}
# glyf의 헤더 bbox는 원본 제어점 포함 경계다. WPF의 곡선 잉크 경계와 구분한다.
function Read-GlyphHeaderBounds([int]$glyphId) {
  if (!$tables.ContainsKey('glyf')) { return $null }
  $loca=$tables['loca']; $format=Read-I16 ($head+50)
  if ($format -eq 0) {
    $start=2*(Read-U16 ($loca+2*$glyphId)); $end=2*(Read-U16 ($loca+2*($glyphId+1)))
  } elseif ($format -eq 1) {
    $start=Read-U32 ($loca+4*$glyphId); $end=Read-U32 ($loca+4*($glyphId+1))
  } else { throw 'Unsupported indexToLocFormat.' }
  if ($start -eq $end) { return $null }
  $entry=$tables['glyf']+$start
  [ordered]@{minX=(Read-I16 ($entry+2));minY=(Read-I16 ($entry+4));
    maxX=(Read-I16 ($entry+6));maxY=(Read-I16 ($entry+8))}
}
$glyphRows = [Collections.Generic.List[object]]::new()
$sampleRows = [Collections.Generic.List[object]]::new()
$seen = [Collections.Generic.HashSet[int]]::new()
foreach ($text in @('H','x','g','PUMP 123','한글')) {
  $pen = 0.0; $minX = [double]::PositiveInfinity; $maxX = [double]::NegativeInfinity
  $minY = [double]::PositiveInfinity; $maxY = [double]::NegativeInfinity
  foreach ($character in $text.ToCharArray()) {
    $codePoint = [int]$character
    if (!$face.CharacterToGlyphMap.ContainsKey($codePoint)) { throw "Missing glyph: U+$($codePoint.ToString('X4'))" }
    $glyph = $face.CharacterToGlyphMap[$codePoint]
    if ($glyph -eq 0) { throw "Notdef glyph: U+$($codePoint.ToString('X4'))" }
    $bounds = $face.GetGlyphOutline($glyph,$unitsPerEm,$unitsPerEm).Bounds
    $advance = $face.AdvanceWidths[$glyph] * $unitsPerEm
    if ($seen.Add($codePoint)) {
      $glyphRows.Add([ordered]@{codePoint=('U+{0:X4}' -f $codePoint);glyphId=$glyph;
        advanceFontUnits=$advance;hasInk=(!$bounds.IsEmpty);rawGlyfHeaderBounds=(Read-GlyphHeaderBounds $glyph);
        boundsFontUnitsYUp=$(if ($bounds.IsEmpty) {$null} else {
          [ordered]@{minX=$bounds.Left;maxX=$bounds.Right;minY=-$bounds.Bottom;maxY=-$bounds.Top}
        })})
    }
    if (!$bounds.IsEmpty) {
      $minX=[Math]::Min($minX,$pen+$bounds.Left);$maxX=[Math]::Max($maxX,$pen+$bounds.Right)
      $minY=[Math]::Min($minY,-$bounds.Bottom);$maxY=[Math]::Max($maxY,-$bounds.Top)
    }
    $pen += $advance
  }
  foreach ($size in @(2,3,5)) { foreach ($ratio in @(1.0,0.8)) {
    $sampleRows.Add([ordered]@{sampleId=('S{0:D2}' -f ($sampleRows.Count+1));text=$text;
      requestedNominalSize=$size;horizontalScale=$ratio;documentUnit='mm';alignment='left-baseline';
      originX=0;originY=0;advanceSumFontUnits=$pen;
      inkMinXFontUnits=$minX;inkMaxXFontUnits=$maxX;inkMinYFontUnits=$minY;inkMaxYFontUnits=$maxY;
      hypotheticalEmMm=$size;hypotheticalAdvanceMm=$pen*$size/$unitsPerEm*$ratio;
      hypotheticalInkWidthMm=($maxX-$minX)*$size/$unitsPerEm*$ratio;
      hypotheticalInkHeightMm=($maxY-$minY)*$size/$unitsPerEm;
      cadStatus='not-run';type3Status='not-run'})
  }}
}
$metrics['glyphs'] = $glyphRows.ToArray()
# 실험 출력만 지정 디렉터리에 쓴다. 글꼴이나 윤곽은 복제하지 않는다.
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$utf8 = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'font-metrics.json'),($metrics|ConvertTo-Json -Depth 10),$utf8)
$sampleRows | ForEach-Object {[pscustomobject]$_} | Export-Csv (Join-Path $OutputDirectory 'comparison-candidates.csv') -NoTypeInformation -Encoding utf8
$sampleRows | ForEach-Object {
  foreach ($program in @('CAD','Type3')) { foreach ($route in @('direct-text','dxf-import')) {
    [pscustomobject]@{sampleId=$_.sampleId;text=$_.text;requestedSize=$_.requestedNominalSize;requestedHorizontalScale=$_.horizontalScale;
      program=$program;route=$route;programVersion='';requestedFont='';actualFont='';fallbackEvidence='';documentUnit='mm';
      displayedSize='';displayedHorizontalScale='';styleFixedHeight='';baselineOrigin='';inkWidthMm='';inkHeightMm='';
      geometryMeasurementMethod='';evidenceFile='';status='not-run';notes=''}
  }}
} | Export-Csv (Join-Path $OutputDirectory 'program-observations.csv') -NoTypeInformation -Encoding utf8
Write-Output "Read $($fontFile.Name): UPEM=$unitsPerEm; $($glyphRows.Count) glyphs; $($sampleRows.Count) conditional samples. CAD/Type3 NOT RUN."