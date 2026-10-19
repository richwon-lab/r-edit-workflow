import 'package:r_edit_workflow/r_edit_workflow.dart';

// 비교 전용 오류 계약. 기존 구현에 검증을 위임하지 않는다.
Never fail(TextInputErrorCode code, String path) =>
    throw TextInputException(code, path);

void validateBreak(String? mode, Iterable<String>? lines) {
  if (mode == null) fail(TextInputErrorCode.missingField, 'lineBreak.mode');
  if (mode != 'auto' && mode != 'manual') {
    fail(TextInputErrorCode.unknownMode, 'lineBreak.mode');
  }
  if (mode == 'auto') {
    if (lines != null) {
      fail(TextInputErrorCode.unexpectedField, 'lineBreak.lines');
    }
    return;
  }
  if (lines == null) fail(TextInputErrorCode.missingField, 'lineBreak.lines');
  if (lines.isEmpty) {
    fail(TextInputErrorCode.emptyManualLines, 'lineBreak.lines');
  }
  var index = 0;
  for (final line in lines) {
    if (line.isEmpty) {
      fail(TextInputErrorCode.emptyManualLine, 'lineBreak.lines[$index]');
    }
    if (line.contains('\r') || line.contains('\n')) {
      fail(
        TextInputErrorCode.manualLineContainsCrLf,
        'lineBreak.lines[$index]',
      );
    }
    index++;
  }
}

void validateArea(
  String? id,
  String? text,
  String? mode,
  Iterable<String>? lines,
) {
  if (id == null) fail(TextInputErrorCode.missingField, 'areaId');
  if (id.isEmpty) fail(TextInputErrorCode.emptyAreaId, 'areaId');
  if (text == null) fail(TextInputErrorCode.missingField, 'sourceText');
  if (text.isEmpty) fail(TextInputErrorCode.emptySourceText, 'sourceText');
  if (text.contains('\r') || text.contains('\n')) {
    fail(TextInputErrorCode.sourceContainsCrLf, 'sourceText');
  }
  validateBreak(mode, lines);
  if (mode == 'manual' && lines!.join() != text) {
    fail(TextInputErrorCode.manualTextMismatch, 'lineBreak.lines');
  }
}

Map<String, Object?> readObject(Object? raw, String path) {
  if (raw is! Map<String, Object?>) fail(TextInputErrorCode.invalidType, path);
  return raw;
}

Object? field(Map<String, Object?> map, String key, String path) {
  if (!map.containsKey(key)) fail(TextInputErrorCode.missingField, path);
  return map[key];
}

String stringField(Map<String, Object?> map, String key, String path) {
  final value = field(map, key, path);
  if (value is! String) fail(TextInputErrorCode.invalidType, path);
  return value;
}

void fields(Map<String, Object?> map, Set<String> allowed, String prefix) {
  for (final key in map.keys) {
    if (!allowed.contains(key)) {
      fail(
        TextInputErrorCode.unexpectedField,
        prefix.isEmpty ? key : '$prefix.$key',
      );
    }
  }
}

Map<String, Object?> readBreak(Object? raw) {
  final map = readObject(raw, 'lineBreak');
  final mode = stringField(map, 'mode', 'lineBreak.mode');
  List<String>? lines;
  if (mode == 'manual') {
    final values = field(map, 'lines', 'lineBreak.lines');
    if (values is! List) {
      fail(TextInputErrorCode.invalidType, 'lineBreak.lines');
    }
    lines = [];
    for (var i = 0; i < values.length; i++) {
      if (values[i] is! String) {
        fail(TextInputErrorCode.invalidType, 'lineBreak.lines[$i]');
      }
      lines.add(values[i] as String);
    }
    fields(map, {'mode', 'lines'}, 'lineBreak');
  } else if (mode == 'auto') {
    fields(map, {'mode'}, 'lineBreak');
  }
  validateBreak(mode, lines);
  return map;
}

Map<String, Object?> readArea(Object? raw) {
  final map = readObject(raw, r'$');
  final id = stringField(map, 'areaId', 'areaId');
  // 기존 오류 순서: ID, 원문, 방식, 추가 필드, 원문 연결.
  if (id.isEmpty) fail(TextInputErrorCode.emptyAreaId, 'areaId');
  final text = stringField(map, 'sourceText', 'sourceText');
  if (text.isEmpty) fail(TextInputErrorCode.emptySourceText, 'sourceText');
  if (text.contains('\r') || text.contains('\n')) {
    fail(TextInputErrorCode.sourceContainsCrLf, 'sourceText');
  }
  final spec = readBreak(field(map, 'lineBreak', 'lineBreak'));
  fields(map, {'areaId', 'sourceText', 'lineBreak'}, '');
  validateArea(
    id,
    text,
    spec['mode'] as String,
    (spec['lines'] as List?)?.cast<String>(),
  );
  return map;
}
