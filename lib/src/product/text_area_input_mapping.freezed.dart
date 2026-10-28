// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_area_input_mapping.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextAreaInputMapping {


/// Create a copy of TextAreaInputMapping
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAreaInputMappingCopyWith<TextAreaInputMapping> get copyWith => _$TextAreaInputMappingCopyWithImpl<TextAreaInputMapping>(this as TextAreaInputMapping, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextAreaInputMapping;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAreaInputMapping&&(identical(other.fromAreaId, _this.fromAreaId) || other.fromAreaId == _this.fromAreaId)&&(identical(other.toAreaId, _this.toAreaId) || other.toAreaId == _this.toAreaId));
}


@override
int get hashCode {
  final _this = this as TextAreaInputMapping;
  return Object.hash(runtimeType,_this.fromAreaId,_this.toAreaId);
}

@override
String toString() {
  final _this = this as TextAreaInputMapping;
  return 'TextAreaInputMapping(fromAreaId: ${_this.fromAreaId}, toAreaId: ${_this.toAreaId})';
}


}

/// @nodoc
abstract mixin class $TextAreaInputMappingCopyWith<$Res>  {
  factory $TextAreaInputMappingCopyWith(TextAreaInputMapping value, $Res Function(TextAreaInputMapping) _then) = _$TextAreaInputMappingCopyWithImpl;
@useResult
$Res call({
 String fromAreaId, String toAreaId
});




}
/// @nodoc
class _$TextAreaInputMappingCopyWithImpl<$Res>
    implements $TextAreaInputMappingCopyWith<$Res> {
  _$TextAreaInputMappingCopyWithImpl(this._self, this._then);

  final TextAreaInputMapping _self;
  final $Res Function(TextAreaInputMapping) _then;

/// Create a copy of TextAreaInputMapping
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fromAreaId = null,Object? toAreaId = null,}) {
  return _then(TextAreaInputMapping(
fromAreaId: null == fromAreaId ? _self.fromAreaId : fromAreaId // ignore: cast_nullable_to_non_nullable
as String,toAreaId: null == toAreaId ? _self.toAreaId : toAreaId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}



// dart format on
