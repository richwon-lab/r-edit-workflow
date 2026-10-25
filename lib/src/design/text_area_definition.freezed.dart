// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_area_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextAreaDefinition {


/// Create a copy of TextAreaDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAreaDefinitionCopyWith<TextAreaDefinition> get copyWith => _$TextAreaDefinitionCopyWithImpl<TextAreaDefinition>(this as TextAreaDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextAreaDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAreaDefinition&&(identical(other.areaId, _this.areaId) || other.areaId == _this.areaId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.region, _this.region) || other.region == _this.region));
}


@override
int get hashCode {
  final _this = this as TextAreaDefinition;
  return Object.hash(runtimeType,_this.areaId,_this.label,_this.region);
}

@override
String toString() {
  final _this = this as TextAreaDefinition;
  return 'TextAreaDefinition(areaId: ${_this.areaId}, label: ${_this.label}, region: ${_this.region})';
}


}

/// @nodoc
abstract mixin class $TextAreaDefinitionCopyWith<$Res>  {
  factory $TextAreaDefinitionCopyWith(TextAreaDefinition value, $Res Function(TextAreaDefinition) _then) = _$TextAreaDefinitionCopyWithImpl;
@useResult
$Res call({
 String areaId, String label, TextRegion region
});


$TextRegionCopyWith<$Res> get region;

}
/// @nodoc
class _$TextAreaDefinitionCopyWithImpl<$Res>
    implements $TextAreaDefinitionCopyWith<$Res> {
  _$TextAreaDefinitionCopyWithImpl(this._self, this._then);

  final TextAreaDefinition _self;
  final $Res Function(TextAreaDefinition) _then;

/// Create a copy of TextAreaDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? label = null,Object? region = null,}) {
  return _then(TextAreaDefinition(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as TextRegion,
  ));
}
/// Create a copy of TextAreaDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextRegionCopyWith<$Res> get region {
  
  return $TextRegionCopyWith<$Res>(_self.region, (value) {
    return _then(_self.copyWith(region: value));
  });
}
}



// dart format on
