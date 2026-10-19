// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_area_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AutoLineBreak {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoLineBreak);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AutoLineBreak()';
}


}

/// @nodoc
class $AutoLineBreakCopyWith<$Res>  {
$AutoLineBreakCopyWith(AutoLineBreak _, $Res Function(AutoLineBreak) __);
}



/// @nodoc
mixin _$ManualLineBreak {


/// Create a copy of ManualLineBreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManualLineBreakCopyWith<ManualLineBreak> get copyWith => _$ManualLineBreakCopyWithImpl<ManualLineBreak>(this as ManualLineBreak, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ManualLineBreak;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualLineBreak&&const DeepCollectionEquality().equals(other.lines, _this.lines));
}


@override
int get hashCode {
  final _this = this as ManualLineBreak;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.lines));
}

@override
String toString() {
  final _this = this as ManualLineBreak;
  return 'ManualLineBreak(lines: ${_this.lines})';
}


}

/// @nodoc
abstract mixin class $ManualLineBreakCopyWith<$Res>  {
  factory $ManualLineBreakCopyWith(ManualLineBreak value, $Res Function(ManualLineBreak) _then) = _$ManualLineBreakCopyWithImpl;
@useResult
$Res call({
 List<String> lines
});




}
/// @nodoc
class _$ManualLineBreakCopyWithImpl<$Res>
    implements $ManualLineBreakCopyWith<$Res> {
  _$ManualLineBreakCopyWithImpl(this._self, this._then);

  final ManualLineBreak _self;
  final $Res Function(ManualLineBreak) _then;

/// Create a copy of ManualLineBreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,}) {
  return _then(ManualLineBreak(
null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}



/// @nodoc
mixin _$TextAreaInput {


/// Create a copy of TextAreaInput
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAreaInputCopyWith<TextAreaInput> get copyWith => _$TextAreaInputCopyWithImpl<TextAreaInput>(this as TextAreaInput, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextAreaInput;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAreaInput&&(identical(other.areaId, _this.areaId) || other.areaId == _this.areaId)&&(identical(other.sourceText, _this.sourceText) || other.sourceText == _this.sourceText)&&(identical(other.lineBreak, _this.lineBreak) || other.lineBreak == _this.lineBreak));
}


@override
int get hashCode {
  final _this = this as TextAreaInput;
  return Object.hash(runtimeType,_this.areaId,_this.sourceText,_this.lineBreak);
}

@override
String toString() {
  final _this = this as TextAreaInput;
  return 'TextAreaInput(areaId: ${_this.areaId}, sourceText: ${_this.sourceText}, lineBreak: ${_this.lineBreak})';
}


}

/// @nodoc
abstract mixin class $TextAreaInputCopyWith<$Res>  {
  factory $TextAreaInputCopyWith(TextAreaInput value, $Res Function(TextAreaInput) _then) = _$TextAreaInputCopyWithImpl;
@useResult
$Res call({
 String areaId, String sourceText, LineBreakSpec lineBreak
});




}
/// @nodoc
class _$TextAreaInputCopyWithImpl<$Res>
    implements $TextAreaInputCopyWith<$Res> {
  _$TextAreaInputCopyWithImpl(this._self, this._then);

  final TextAreaInput _self;
  final $Res Function(TextAreaInput) _then;

/// Create a copy of TextAreaInput
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? sourceText = null,Object? lineBreak = null,}) {
  return _then(TextAreaInput(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,lineBreak: null == lineBreak ? _self.lineBreak : lineBreak // ignore: cast_nullable_to_non_nullable
as LineBreakSpec,
  ));
}

}



// dart format on
