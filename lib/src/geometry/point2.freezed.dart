// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'point2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Point2 {


/// Create a copy of Point2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Point2CopyWith<Point2> get copyWith => _$Point2CopyWithImpl<Point2>(this as Point2, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Point2;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Point2&&(identical(other.x, _this.x) || other.x == _this.x)&&(identical(other.y, _this.y) || other.y == _this.y));
}


@override
int get hashCode {
  final _this = this as Point2;
  return Object.hash(runtimeType,_this.x,_this.y);
}

@override
String toString() {
  final _this = this as Point2;
  return 'Point2(x: ${_this.x}, y: ${_this.y})';
}


}

/// @nodoc
abstract mixin class $Point2CopyWith<$Res>  {
  factory $Point2CopyWith(Point2 value, $Res Function(Point2) _then) = _$Point2CopyWithImpl;
@useResult
$Res call({
 double x, double y
});




}
/// @nodoc
class _$Point2CopyWithImpl<$Res>
    implements $Point2CopyWith<$Res> {
  _$Point2CopyWithImpl(this._self, this._then);

  final Point2 _self;
  final $Res Function(Point2) _then;

/// Create a copy of Point2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? x = null,Object? y = null,}) {
  return _then(Point2(
x: null == x ? _self.x : x // ignore: cast_nullable_to_non_nullable
as double,y: null == y ? _self.y : y // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}



// dart format on
