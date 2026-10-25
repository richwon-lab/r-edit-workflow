// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry_path.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GeometryPath {


/// Create a copy of GeometryPath
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeometryPathCopyWith<GeometryPath> get copyWith => _$GeometryPathCopyWithImpl<GeometryPath>(this as GeometryPath, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GeometryPath;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeometryPath&&(identical(other.start, _this.start) || other.start == _this.start)&&const DeepCollectionEquality().equals(other.segments, _this.segments));
}


@override
int get hashCode {
  final _this = this as GeometryPath;
  return Object.hash(runtimeType,_this.start,const DeepCollectionEquality().hash(_this.segments));
}

@override
String toString() {
  final _this = this as GeometryPath;
  return 'GeometryPath(start: ${_this.start}, segments: ${_this.segments})';
}


}

/// @nodoc
abstract mixin class $GeometryPathCopyWith<$Res>  {
  factory $GeometryPathCopyWith(GeometryPath value, $Res Function(GeometryPath) _then) = _$GeometryPathCopyWithImpl;
@useResult
$Res call({
 Point2 start, List<PathSegment> segments
});


$Point2CopyWith<$Res> get start;

}
/// @nodoc
class _$GeometryPathCopyWithImpl<$Res>
    implements $GeometryPathCopyWith<$Res> {
  _$GeometryPathCopyWithImpl(this._self, this._then);

  final GeometryPath _self;
  final $Res Function(GeometryPath) _then;

/// Create a copy of GeometryPath
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? segments = null,}) {
  return _then(GeometryPath(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as Point2,segments: null == segments ? _self.segments : segments // ignore: cast_nullable_to_non_nullable
as List<PathSegment>,
  ));
}
/// Create a copy of GeometryPath
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Point2CopyWith<$Res> get start {
  
  return $Point2CopyWith<$Res>(_self.start, (value) {
    return _then(_self.copyWith(start: value));
  });
}
}



// dart format on
