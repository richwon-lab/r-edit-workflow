// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<TrialArea> _$trialAreaSerializer = _$TrialAreaSerializer();
Serializer<TrialBreak> _$trialBreakSerializer = _$TrialBreakSerializer();

class _$TrialAreaSerializer implements StructuredSerializer<TrialArea> {
  @override
  final Iterable<Type> types = const [TrialArea, _$TrialArea];
  @override
  final String wireName = 'TrialArea';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    TrialArea object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'areaId',
      serializers.serialize(
        object.areaId,
        specifiedType: const FullType(String),
      ),
      'sourceText',
      serializers.serialize(
        object.sourceText,
        specifiedType: const FullType(String),
      ),
      'lineBreak',
      serializers.serialize(
        object.lineBreak,
        specifiedType: const FullType(TrialBreak),
      ),
    ];

    return result;
  }

  @override
  TrialArea deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrialAreaBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'areaId':
          result.areaId =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'sourceText':
          result.sourceText =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'lineBreak':
          result.lineBreak.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(TrialBreak),
                )!
                as TrialBreak,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$TrialBreakSerializer implements StructuredSerializer<TrialBreak> {
  @override
  final Iterable<Type> types = const [TrialBreak, _$TrialBreak];
  @override
  final String wireName = 'TrialBreak';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    TrialBreak object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'mode',
      serializers.serialize(object.mode, specifiedType: const FullType(String)),
    ];
    Object? value;
    value = object.lines;
    if (value != null) {
      result
        ..add('lines')
        ..add(
          serializers.serialize(
            value,
            specifiedType: const FullType(BuiltList, const [
              const FullType(String),
            ]),
          ),
        );
    }
    return result;
  }

  @override
  TrialBreak deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrialBreakBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'mode':
          result.mode =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'lines':
          result.lines = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, const [
              const FullType(String),
            ]),
          ) as BuiltList<String>?;
          break;
      }
    }

    return result.build();
  }
}

class _$TrialArea extends TrialArea {
  @override
  final String areaId;
  @override
  final String sourceText;
  @override
  final TrialBreak lineBreak;

  factory _$TrialArea([void Function(TrialAreaBuilder)? updates]) =>
      (TrialAreaBuilder()..update(updates))._build();

  _$TrialArea._({
    required this.areaId,
    required this.sourceText,
    required this.lineBreak,
  }) : super._();
  @override
  TrialArea rebuild(void Function(TrialAreaBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrialAreaBuilder toBuilder() => TrialAreaBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrialArea &&
        areaId == other.areaId &&
        sourceText == other.sourceText &&
        lineBreak == other.lineBreak;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, areaId.hashCode);
    _$hash = $jc(_$hash, sourceText.hashCode);
    _$hash = $jc(_$hash, lineBreak.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrialArea')
          ..add('areaId', areaId)
          ..add('sourceText', sourceText)
          ..add('lineBreak', lineBreak))
        .toString();
  }
}

class TrialAreaBuilder implements Builder<TrialArea, TrialAreaBuilder> {
  _$TrialArea? _$v;

  String? _areaId;
  String? get areaId => _$this._areaId;
  set areaId(String? areaId) => _$this._areaId = areaId;

  String? _sourceText;
  String? get sourceText => _$this._sourceText;
  set sourceText(String? sourceText) => _$this._sourceText = sourceText;

  TrialBreakBuilder? _lineBreak;
  TrialBreakBuilder get lineBreak => _$this._lineBreak ??= TrialBreakBuilder();
  set lineBreak(TrialBreakBuilder? lineBreak) => _$this._lineBreak = lineBreak;

  TrialAreaBuilder();

  TrialAreaBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _areaId = $v.areaId;
      _sourceText = $v.sourceText;
      _lineBreak = $v.lineBreak.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrialArea other) {
    _$v = other as _$TrialArea;
  }

  @override
  void update(void Function(TrialAreaBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrialArea build() => _build();

  _$TrialArea _build() {
    TrialArea.validate(this);
    _$TrialArea _$result;
    try {
      _$result =
          _$v ??
          _$TrialArea._(
            areaId: BuiltValueNullFieldError.checkNotNull(
              areaId,
              r'TrialArea',
              'areaId',
            ),
            sourceText: BuiltValueNullFieldError.checkNotNull(
              sourceText,
              r'TrialArea',
              'sourceText',
            ),
            lineBreak: lineBreak.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lineBreak';
        lineBreak.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'TrialArea',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$TrialBreak extends TrialBreak {
  @override
  final String mode;
  @override
  final BuiltList<String>? lines;

  factory _$TrialBreak([void Function(TrialBreakBuilder)? updates]) =>
      (TrialBreakBuilder()..update(updates))._build();

  _$TrialBreak._({required this.mode, this.lines}) : super._();
  @override
  TrialBreak rebuild(void Function(TrialBreakBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TrialBreakBuilder toBuilder() => TrialBreakBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TrialBreak && mode == other.mode && lines == other.lines;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, lines.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TrialBreak')
          ..add('mode', mode)
          ..add('lines', lines))
        .toString();
  }
}

class TrialBreakBuilder implements Builder<TrialBreak, TrialBreakBuilder> {
  _$TrialBreak? _$v;

  String? _mode;
  String? get mode => _$this._mode;
  set mode(String? mode) => _$this._mode = mode;

  BuiltList<String>? _lines;
  BuiltList<String>? get lines => _$this._lines;
  set lines(BuiltList<String>? lines) => _$this._lines = lines;

  TrialBreakBuilder();

  TrialBreakBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mode = $v.mode;
      _lines = $v.lines;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TrialBreak other) {
    _$v = other as _$TrialBreak;
  }

  @override
  void update(void Function(TrialBreakBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TrialBreak build() => _build();

  _$TrialBreak _build() {
    TrialBreak.validate(this);
    final _$result =
        _$v ??
        _$TrialBreak._(
          mode: BuiltValueNullFieldError.checkNotNull(
            mode,
            r'TrialBreak',
            'mode',
          ),
          lines: lines,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
