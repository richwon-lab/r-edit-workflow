// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_geometry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignGeometry {





@override
bool operator ==(Object other) {
  final _this = this as DesignGeometry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignGeometry&&(identical(other.coordinateSpace, _this.coordinateSpace) || other.coordinateSpace == _this.coordinateSpace)&&(identical(other.outline, _this.outline) || other.outline == _this.outline)&&const DeepCollectionEquality().equals(other.cutouts, _this.cutouts)&&const DeepCollectionEquality().equals(other.textAreas, _this.textAreas));
}


@override
int get hashCode {
  final _this = this as DesignGeometry;
  return Object.hash(runtimeType,_this.coordinateSpace,_this.outline,const DeepCollectionEquality().hash(_this.cutouts),const DeepCollectionEquality().hash(_this.textAreas));
}

@override
String toString() {
  final _this = this as DesignGeometry;
  return 'DesignGeometry(coordinateSpace: ${_this.coordinateSpace}, outline: ${_this.outline}, cutouts: ${_this.cutouts}, textAreas: ${_this.textAreas})';
}


}





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
