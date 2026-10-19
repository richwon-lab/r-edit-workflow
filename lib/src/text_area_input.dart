/// Why an area text input could not be constructed or decoded.
enum TextInputErrorCode {
  missingField,
  invalidType,
  unknownMode,
  unexpectedField,
  emptyAreaId,
  emptySourceText,
  emptyManualLines,
  emptyManualLine,
  sourceContainsCrLf,
  manualLineContainsCrLf,
  manualTextMismatch,
}

/// A validation failure with a stable code and a JSON-style field path.
///
/// [path] identifies a field or list item, not a character offset.
final class TextInputException implements Exception {
  const TextInputException(this.code, this.path);

  final TextInputErrorCode code;
  final String path;

  @override
  String toString() => 'TextInputException(${code.name}, $path)';
}

/// Explicit line-break input, independent of layout size and placement.
sealed class LineBreakSpec {
  const LineBreakSpec();

  /// Decodes a JSON object; missing or unknown modes are never inferred.
  factory LineBreakSpec.fromJson(Object? json) {
    final object = _object(json, 'lineBreak');
    final mode = _stringField(object, 'mode', 'lineBreak.mode');
    switch (mode) {
      case 'auto':
        _checkFields(object, const {'mode'}, 'lineBreak');
        return const AutoLineBreak();
      case 'manual':
        final value = _required(object, 'lines', 'lineBreak.lines');
        if (value is! List) {
          throw const TextInputException(
            TextInputErrorCode.invalidType,
            'lineBreak.lines',
          );
        }
        final lines = <String>[];
        for (var i = 0; i < value.length; i++) {
          final line = value[i];
          if (line is! String) {
            throw TextInputException(
              TextInputErrorCode.invalidType,
              'lineBreak.lines[$i]',
            );
          }
          lines.add(line);
        }
        _checkFields(object, const {'mode', 'lines'}, 'lineBreak');
        return ManualLineBreak(lines);
      default:
        throw const TextInputException(
          TextInputErrorCode.unknownMode,
          'lineBreak.mode',
        );
    }
  }

  /// Returns detached JSON values suitable for dart:convert's jsonEncode.
  Map<String, Object?> toJson();
}

/// Lets a future layout calculation choose line breaks.
final class AutoLineBreak extends LineBreakSpec {
  const AutoLineBreak();

  @override
  Map<String, Object?> toJson() => {'mode': 'auto'};

  @override
  bool operator ==(Object other) => other is AutoLineBreak;

  @override
  int get hashCode => Object.hash(AutoLineBreak, 0);
}

/// Complete, explicitly specified lines, including a single manual line.
///
/// Empty lines and CR/LF are outside this first implementation's scope.
final class ManualLineBreak extends LineBreakSpec {
  factory ManualLineBreak(List<String> lines) {
    final copy = List<String>.unmodifiable(lines);
    if (copy.isEmpty) {
      throw const TextInputException(
        TextInputErrorCode.emptyManualLines,
        'lineBreak.lines',
      );
    }
    for (var i = 0; i < copy.length; i++) {
      if (copy[i].isEmpty) {
        throw TextInputException(
          TextInputErrorCode.emptyManualLine,
          'lineBreak.lines[$i]',
        );
      }
      if (_containsCrLf(copy[i])) {
        throw TextInputException(
          TextInputErrorCode.manualLineContainsCrLf,
          'lineBreak.lines[$i]',
        );
      }
    }
    return ManualLineBreak._(copy);
  }

  const ManualLineBreak._(this.lines);

  final List<String> lines;

  @override
  Map<String, Object?> toJson() => {'mode': 'manual', 'lines': lines.toList()};

  @override
  bool operator ==(Object other) {
    if (other is! ManualLineBreak || lines.length != other.lines.length) {
      return false;
    }
    for (var i = 0; i < lines.length; i++) {
      if (lines[i] != other.lines[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(ManualLineBreak, Object.hashAll(lines));
}

/// An immutable area's original text and explicit line-break input.
///
/// Construct a complete replacement to change text and manual lines together.
/// Validation here does not establish layout or manufacturing feasibility.
final class TextAreaInput {
  factory TextAreaInput({
    required String areaId,
    required String sourceText,
    required LineBreakSpec lineBreak,
  }) {
    _validateAreaId(areaId);
    _validateSourceText(sourceText);
    if (lineBreak is ManualLineBreak && lineBreak.lines.join() != sourceText) {
      throw const TextInputException(
        TextInputErrorCode.manualTextMismatch,
        'lineBreak.lines',
      );
    }
    return TextAreaInput._(areaId, sourceText, lineBreak);
  }

  const TextAreaInput._(this.areaId, this.sourceText, this.lineBreak);

  /// Decodes this input fragment, not a WorkDocument or an unfinished save.
  factory TextAreaInput.fromJson(Object? json) {
    final object = _object(json, r'$');
    final areaId = _stringField(object, 'areaId', 'areaId');
    _validateAreaId(areaId);
    final sourceText = _stringField(object, 'sourceText', 'sourceText');
    _validateSourceText(sourceText);
    final lineBreak = LineBreakSpec.fromJson(
      _required(object, 'lineBreak', 'lineBreak'),
    );
    _checkFields(object, const {'areaId', 'sourceText', 'lineBreak'}, '');
    return TextAreaInput(
      areaId: areaId,
      sourceText: sourceText,
      lineBreak: lineBreak,
    );
  }

  final String areaId;
  final String sourceText;
  final LineBreakSpec lineBreak;

  Map<String, Object?> toJson() => {
    'areaId': areaId,
    'sourceText': sourceText,
    'lineBreak': lineBreak.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is TextAreaInput &&
      areaId == other.areaId &&
      sourceText == other.sourceText &&
      lineBreak == other.lineBreak;

  @override
  int get hashCode => Object.hash(areaId, sourceText, lineBreak);
}

bool _containsCrLf(String text) => text.contains('\r') || text.contains('\n');

void _validateAreaId(String areaId) {
  if (areaId.isEmpty) {
    throw const TextInputException(TextInputErrorCode.emptyAreaId, 'areaId');
  }
}

void _validateSourceText(String sourceText) {
  if (sourceText.isEmpty) {
    throw const TextInputException(
      TextInputErrorCode.emptySourceText,
      'sourceText',
    );
  }
  if (_containsCrLf(sourceText)) {
    throw const TextInputException(
      TextInputErrorCode.sourceContainsCrLf,
      'sourceText',
    );
  }
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw TextInputException(TextInputErrorCode.invalidType, path);
  }
  return value;
}

Object? _required(Map<String, Object?> object, String key, String path) {
  if (!object.containsKey(key)) {
    throw TextInputException(TextInputErrorCode.missingField, path);
  }
  return object[key];
}

String _stringField(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! String) {
    throw TextInputException(TextInputErrorCode.invalidType, path);
  }
  return value;
}

void _checkFields(
  Map<String, Object?> object,
  Set<String> allowed,
  String prefix,
) {
  for (final key in object.keys) {
    if (!allowed.contains(key)) {
      throw TextInputException(
        TextInputErrorCode.unexpectedField,
        prefix.isEmpty ? key : '$prefix.$key',
      );
    }
  }
}
