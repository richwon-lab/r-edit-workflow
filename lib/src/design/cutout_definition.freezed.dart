// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cutout_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CutoutDefinition {


/// Create a copy of CutoutDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CutoutDefinitionCopyWith<CutoutDefinition> get copyWith => _$CutoutDefinitionCopyWithImpl<CutoutDefinition>(this as CutoutDefinition, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CutoutDefinition;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CutoutDefinition&&(identical(other.cutoutId, _this.cutoutId) || other.cutoutId == _this.cutoutId)&&(identical(other.boundary, _this.boundary) || other.boundary == _this.boundary));
}


@override
int get hashCode {
  final _this = this as CutoutDefinition;
  return Object.hash(runtimeType,_this.cutoutId,_this.boundary);
}

@override
String toString() {
  final _this = this as CutoutDefinition;
  return 'CutoutDefinition(cutoutId: ${_this.cutoutId}, boundary: ${_this.boundary})';
}


}

/// @nodoc
abstract mixin class $CutoutDefinitionCopyWith<$Res>  {
  factory $CutoutDefinitionCopyWith(CutoutDefinition value, $Res Function(CutoutDefinition) _then) = _$CutoutDefinitionCopyWithImpl;
@useResult
$Res call({
 String cutoutId, ClosedBoundary boundary
});




}
/// @nodoc
class _$CutoutDefinitionCopyWithImpl<$Res>
    implements $CutoutDefinitionCopyWith<$Res> {
  _$CutoutDefinitionCopyWithImpl(this._self, this._then);

  final CutoutDefinition _self;
  final $Res Function(CutoutDefinition) _then;

/// Create a copy of CutoutDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cutoutId = null,Object? boundary = null,}) {
  return _then(CutoutDefinition(
cutoutId: null == cutoutId ? _self.cutoutId : cutoutId // ignore: cast_nullable_to_non_nullable
as String,boundary: null == boundary ? _self.boundary : boundary // ignore: cast_nullable_to_non_nullable
as ClosedBoundary,
  ));
}

}



// dart format on
