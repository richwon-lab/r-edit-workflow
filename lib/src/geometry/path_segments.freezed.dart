// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'path_segments.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LineTo {


/// Create a copy of LineTo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineToCopyWith<LineTo> get copyWith => _$LineToCopyWithImpl<LineTo>(this as LineTo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LineTo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineTo&&(identical(other.end, _this.end) || other.end == _this.end));
}


@override
int get hashCode {
  final _this = this as LineTo;
  return Object.hash(runtimeType,_this.end);
}

@override
String toString() {
  final _this = this as LineTo;
  return 'LineTo(end: ${_this.end})';
}


}

/// @nodoc
abstract mixin class $LineToCopyWith<$Res>  {
  factory $LineToCopyWith(LineTo value, $Res Function(LineTo) _then) = _$LineToCopyWithImpl;
@useResult
$Res call({
 Point2 end
});


$Point2CopyWith<$Res> get end;

}
/// @nodoc
class _$LineToCopyWithImpl<$Res>
    implements $LineToCopyWith<$Res> {
  _$LineToCopyWithImpl(this._self, this._then);

  final LineTo _self;
  final $Res Function(LineTo) _then;

/// Create a copy of LineTo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? end = null,}) {
  return _then(LineTo(
end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as Point2,
  ));
}
/// Create a copy of LineTo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Point2CopyWith<$Res> get end {
  
  return $Point2CopyWith<$Res>(_self.end, (value) {
    return _then(_self.copyWith(end: value));
  });
}
}



/// @nodoc
mixin _$ArcTo {


/// Create a copy of ArcTo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArcToCopyWith<ArcTo> get copyWith => _$ArcToCopyWithImpl<ArcTo>(this as ArcTo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArcTo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArcTo&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.bulge, _this.bulge) || other.bulge == _this.bulge));
}


@override
int get hashCode {
  final _this = this as ArcTo;
  return Object.hash(runtimeType,_this.end,_this.bulge);
}

@override
String toString() {
  final _this = this as ArcTo;
  return 'ArcTo(end: ${_this.end}, bulge: ${_this.bulge})';
}


}

/// @nodoc
abstract mixin class $ArcToCopyWith<$Res>  {
  factory $ArcToCopyWith(ArcTo value, $Res Function(ArcTo) _then) = _$ArcToCopyWithImpl;
@useResult
$Res call({
 Point2 end, double bulge
});


$Point2CopyWith<$Res> get end;

}
/// @nodoc
class _$ArcToCopyWithImpl<$Res>
    implements $ArcToCopyWith<$Res> {
  _$ArcToCopyWithImpl(this._self, this._then);

  final ArcTo _self;
  final $Res Function(ArcTo) _then;

/// Create a copy of ArcTo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? end = null,Object? bulge = null,}) {
  return _then(ArcTo(
end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as Point2,bulge: null == bulge ? _self.bulge : bulge // ignore: cast_nullable_to_non_nullable
as double,
  ));
}
/// Create a copy of ArcTo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Point2CopyWith<$Res> get end {
  
  return $Point2CopyWith<$Res>(_self.end, (value) {
    return _then(_self.copyWith(end: value));
  });
}
}



// dart format on
