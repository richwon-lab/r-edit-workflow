// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RectangularPlateGeometry {


/// Create a copy of RectangularPlateGeometry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RectangularPlateGeometryCopyWith<RectangularPlateGeometry> get copyWith => _$RectangularPlateGeometryCopyWithImpl<RectangularPlateGeometry>(this as RectangularPlateGeometry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RectangularPlateGeometry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RectangularPlateGeometry&&(identical(other.widthMm, _this.widthMm) || other.widthMm == _this.widthMm)&&(identical(other.heightMm, _this.heightMm) || other.heightMm == _this.heightMm)&&const DeepCollectionEquality().equals(other.holes, _this.holes));
}


@override
int get hashCode {
  final _this = this as RectangularPlateGeometry;
  return Object.hash(runtimeType,_this.widthMm,_this.heightMm,const DeepCollectionEquality().hash(_this.holes));
}

@override
String toString() {
  final _this = this as RectangularPlateGeometry;
  return 'RectangularPlateGeometry(widthMm: ${_this.widthMm}, heightMm: ${_this.heightMm}, holes: ${_this.holes})';
}


}

/// @nodoc
abstract mixin class $RectangularPlateGeometryCopyWith<$Res>  {
  factory $RectangularPlateGeometryCopyWith(RectangularPlateGeometry value, $Res Function(RectangularPlateGeometry) _then) = _$RectangularPlateGeometryCopyWithImpl;
@useResult
$Res call({
 double widthMm, double heightMm, List<CircularHole> holes
});




}
/// @nodoc
class _$RectangularPlateGeometryCopyWithImpl<$Res>
    implements $RectangularPlateGeometryCopyWith<$Res> {
  _$RectangularPlateGeometryCopyWithImpl(this._self, this._then);

  final RectangularPlateGeometry _self;
  final $Res Function(RectangularPlateGeometry) _then;

/// Create a copy of RectangularPlateGeometry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? widthMm = null,Object? heightMm = null,Object? holes = null,}) {
  return _then(RectangularPlateGeometry(
widthMm: null == widthMm ? _self.widthMm : widthMm // ignore: cast_nullable_to_non_nullable
as double,heightMm: null == heightMm ? _self.heightMm : heightMm // ignore: cast_nullable_to_non_nullable
as double,holes: null == holes ? _self.holes : holes // ignore: cast_nullable_to_non_nullable
as List<CircularHole>,
  ));
}

}



/// @nodoc
mixin _$CircularHole {


/// Create a copy of CircularHole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CircularHoleCopyWith<CircularHole> get copyWith => _$CircularHoleCopyWithImpl<CircularHole>(this as CircularHole, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CircularHole;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CircularHole&&(identical(other.holeId, _this.holeId) || other.holeId == _this.holeId)&&(identical(other.centerXMm, _this.centerXMm) || other.centerXMm == _this.centerXMm)&&(identical(other.centerYMm, _this.centerYMm) || other.centerYMm == _this.centerYMm)&&(identical(other.diameterMm, _this.diameterMm) || other.diameterMm == _this.diameterMm));
}


@override
int get hashCode {
  final _this = this as CircularHole;
  return Object.hash(runtimeType,_this.holeId,_this.centerXMm,_this.centerYMm,_this.diameterMm);
}

@override
String toString() {
  final _this = this as CircularHole;
  return 'CircularHole(holeId: ${_this.holeId}, centerXMm: ${_this.centerXMm}, centerYMm: ${_this.centerYMm}, diameterMm: ${_this.diameterMm})';
}


}

/// @nodoc
abstract mixin class $CircularHoleCopyWith<$Res>  {
  factory $CircularHoleCopyWith(CircularHole value, $Res Function(CircularHole) _then) = _$CircularHoleCopyWithImpl;
@useResult
$Res call({
 String holeId, double centerXMm, double centerYMm, double diameterMm
});




}
/// @nodoc
class _$CircularHoleCopyWithImpl<$Res>
    implements $CircularHoleCopyWith<$Res> {
  _$CircularHoleCopyWithImpl(this._self, this._then);

  final CircularHole _self;
  final $Res Function(CircularHole) _then;

/// Create a copy of CircularHole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? holeId = null,Object? centerXMm = null,Object? centerYMm = null,Object? diameterMm = null,}) {
  return _then(CircularHole(
holeId: null == holeId ? _self.holeId : holeId // ignore: cast_nullable_to_non_nullable
as String,centerXMm: null == centerXMm ? _self.centerXMm : centerXMm // ignore: cast_nullable_to_non_nullable
as double,centerYMm: null == centerYMm ? _self.centerYMm : centerYMm // ignore: cast_nullable_to_non_nullable
as double,diameterMm: null == diameterMm ? _self.diameterMm : diameterMm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}



/// @nodoc
mixin _$TextAreaBounds {


/// Create a copy of TextAreaBounds
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextAreaBoundsCopyWith<TextAreaBounds> get copyWith => _$TextAreaBoundsCopyWithImpl<TextAreaBounds>(this as TextAreaBounds, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TextAreaBounds;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAreaBounds&&(identical(other.xMm, _this.xMm) || other.xMm == _this.xMm)&&(identical(other.yMm, _this.yMm) || other.yMm == _this.yMm)&&(identical(other.widthMm, _this.widthMm) || other.widthMm == _this.widthMm)&&(identical(other.heightMm, _this.heightMm) || other.heightMm == _this.heightMm));
}


@override
int get hashCode {
  final _this = this as TextAreaBounds;
  return Object.hash(runtimeType,_this.xMm,_this.yMm,_this.widthMm,_this.heightMm);
}

@override
String toString() {
  final _this = this as TextAreaBounds;
  return 'TextAreaBounds(xMm: ${_this.xMm}, yMm: ${_this.yMm}, widthMm: ${_this.widthMm}, heightMm: ${_this.heightMm})';
}


}

/// @nodoc
abstract mixin class $TextAreaBoundsCopyWith<$Res>  {
  factory $TextAreaBoundsCopyWith(TextAreaBounds value, $Res Function(TextAreaBounds) _then) = _$TextAreaBoundsCopyWithImpl;
@useResult
$Res call({
 double xMm, double yMm, double widthMm, double heightMm
});




}
/// @nodoc
class _$TextAreaBoundsCopyWithImpl<$Res>
    implements $TextAreaBoundsCopyWith<$Res> {
  _$TextAreaBoundsCopyWithImpl(this._self, this._then);

  final TextAreaBounds _self;
  final $Res Function(TextAreaBounds) _then;

/// Create a copy of TextAreaBounds
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xMm = null,Object? yMm = null,Object? widthMm = null,Object? heightMm = null,}) {
  return _then(TextAreaBounds(
xMm: null == xMm ? _self.xMm : xMm // ignore: cast_nullable_to_non_nullable
as double,yMm: null == yMm ? _self.yMm : yMm // ignore: cast_nullable_to_non_nullable
as double,widthMm: null == widthMm ? _self.widthMm : widthMm // ignore: cast_nullable_to_non_nullable
as double,heightMm: null == heightMm ? _self.heightMm : heightMm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}



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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextAreaDefinition&&(identical(other.areaId, _this.areaId) || other.areaId == _this.areaId)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.bounds, _this.bounds) || other.bounds == _this.bounds));
}


@override
int get hashCode {
  final _this = this as TextAreaDefinition;
  return Object.hash(runtimeType,_this.areaId,_this.label,_this.bounds);
}

@override
String toString() {
  final _this = this as TextAreaDefinition;
  return 'TextAreaDefinition(areaId: ${_this.areaId}, label: ${_this.label}, bounds: ${_this.bounds})';
}


}

/// @nodoc
abstract mixin class $TextAreaDefinitionCopyWith<$Res>  {
  factory $TextAreaDefinitionCopyWith(TextAreaDefinition value, $Res Function(TextAreaDefinition) _then) = _$TextAreaDefinitionCopyWithImpl;
@useResult
$Res call({
 String areaId, String label, TextAreaBounds bounds
});


$TextAreaBoundsCopyWith<$Res> get bounds;

}
/// @nodoc
class _$TextAreaDefinitionCopyWithImpl<$Res>
    implements $TextAreaDefinitionCopyWith<$Res> {
  _$TextAreaDefinitionCopyWithImpl(this._self, this._then);

  final TextAreaDefinition _self;
  final $Res Function(TextAreaDefinition) _then;

/// Create a copy of TextAreaDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? label = null,Object? bounds = null,}) {
  return _then(TextAreaDefinition(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,bounds: null == bounds ? _self.bounds : bounds // ignore: cast_nullable_to_non_nullable
as TextAreaBounds,
  ));
}
/// Create a copy of TextAreaDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TextAreaBoundsCopyWith<$Res> get bounds {
  
  return $TextAreaBoundsCopyWith<$Res>(_self.bounds, (value) {
    return _then(_self.copyWith(bounds: value));
  });
}
}



// dart format on
