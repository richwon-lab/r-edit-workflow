// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_region.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TextRegion {


/// Create a copy of TextRegion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextRegionCopyWith<TextRegion> get copyWith => _$TextRegionCopyWithImpl<TextRegion>(this as TextRegion, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextRegion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextRegion&&(identical(other.outer, _this.outer) || other.outer == _this.outer)&&const DeepCollectionEquality().equals(other.exclusions, _this.exclusions));
}


@override
int get hashCode {
  final _this = this as TextRegion;
  return Object.hash(runtimeType,_this.outer,const DeepCollectionEquality().hash(_this.exclusions));
}

@override
String toString() {
  final _this = this as TextRegion;
  return 'TextRegion(outer: ${_this.outer}, exclusions: ${_this.exclusions})';
}


}

/// @nodoc
abstract mixin class $TextRegionCopyWith<$Res>  {
  factory $TextRegionCopyWith(TextRegion value, $Res Function(TextRegion) _then) = _$TextRegionCopyWithImpl;
@useResult
$Res call({
 ClosedBoundary outer, List<ClosedBoundary> exclusions
});




}
/// @nodoc
class _$TextRegionCopyWithImpl<$Res>
    implements $TextRegionCopyWith<$Res> {
  _$TextRegionCopyWithImpl(this._self, this._then);

  final TextRegion _self;
  final $Res Function(TextRegion) _then;

/// Create a copy of TextRegion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? outer = null,Object? exclusions = null,}) {
  return _then(TextRegion(
outer: null == outer ? _self.outer : outer // ignore: cast_nullable_to_non_nullable
as ClosedBoundary,exclusions: null == exclusions ? _self.exclusions : exclusions // ignore: cast_nullable_to_non_nullable
as List<ClosedBoundary>,
  ));
}

}



// dart format on
