// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'closed_boundary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CircleBoundary {


/// Create a copy of CircleBoundary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CircleBoundaryCopyWith<CircleBoundary> get copyWith => _$CircleBoundaryCopyWithImpl<CircleBoundary>(this as CircleBoundary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CircleBoundary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CircleBoundary&&(identical(other.center, _this.center) || other.center == _this.center)&&(identical(other.radius, _this.radius) || other.radius == _this.radius));
}


@override
int get hashCode {
  final _this = this as CircleBoundary;
  return Object.hash(runtimeType,_this.center,_this.radius);
}

@override
String toString() {
  final _this = this as CircleBoundary;
  return 'CircleBoundary(center: ${_this.center}, radius: ${_this.radius})';
}


}

/// @nodoc
abstract mixin class $CircleBoundaryCopyWith<$Res>  {
  factory $CircleBoundaryCopyWith(CircleBoundary value, $Res Function(CircleBoundary) _then) = _$CircleBoundaryCopyWithImpl;
@useResult
$Res call({
 Point2 center, double radius
});


$Point2CopyWith<$Res> get center;

}
/// @nodoc
class _$CircleBoundaryCopyWithImpl<$Res>
    implements $CircleBoundaryCopyWith<$Res> {
  _$CircleBoundaryCopyWithImpl(this._self, this._then);

  final CircleBoundary _self;
  final $Res Function(CircleBoundary) _then;

/// Create a copy of CircleBoundary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? center = null,Object? radius = null,}) {
  return _then(CircleBoundary(
center: null == center ? _self.center : center // ignore: cast_nullable_to_non_nullable
as Point2,radius: null == radius ? _self.radius : radius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of CircleBoundary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Point2CopyWith<$Res> get center {
  
  return $Point2CopyWith<$Res>(_self.center, (value) {
    return _then(_self.copyWith(center: value));
  });
}
}



/// @nodoc
mixin _$PathBoundary {


/// Create a copy of PathBoundary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathBoundaryCopyWith<PathBoundary> get copyWith => _$PathBoundaryCopyWithImpl<PathBoundary>(this as PathBoundary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PathBoundary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathBoundary&&(identical(other.path, _this.path) || other.path == _this.path));
}


@override
int get hashCode {
  final _this = this as PathBoundary;
  return Object.hash(runtimeType,_this.path);
}

@override
String toString() {
  final _this = this as PathBoundary;
  return 'PathBoundary(path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $PathBoundaryCopyWith<$Res>  {
  factory $PathBoundaryCopyWith(PathBoundary value, $Res Function(PathBoundary) _then) = _$PathBoundaryCopyWithImpl;
@useResult
$Res call({
 GeometryPath path
});


$GeometryPathCopyWith<$Res> get path;

}
/// @nodoc
class _$PathBoundaryCopyWithImpl<$Res>
    implements $PathBoundaryCopyWith<$Res> {
  _$PathBoundaryCopyWithImpl(this._self, this._then);

  final PathBoundary _self;
  final $Res Function(PathBoundary) _then;

/// Create a copy of PathBoundary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,}) {
  return _then(PathBoundary(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as GeometryPath,
  ));
}
/// Create a copy of PathBoundary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GeometryPathCopyWith<$Res> get path {
  
  return $GeometryPathCopyWith<$Res>(_self.path, (value) {
    return _then(_self.copyWith(path: value));
  });
}
}



// dart format on
