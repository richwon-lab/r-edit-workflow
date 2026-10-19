// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrialArea {


/// Create a copy of TrialArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrialAreaCopyWith<TrialArea> get copyWith => _$TrialAreaCopyWithImpl<TrialArea>(this as TrialArea, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrialArea;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrialArea&&(identical(other.areaId, _this.areaId) || other.areaId == _this.areaId)&&(identical(other.sourceText, _this.sourceText) || other.sourceText == _this.sourceText)&&(identical(other.lineBreak, _this.lineBreak) || other.lineBreak == _this.lineBreak));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrialArea;
  return Object.hash(runtimeType,_this.areaId,_this.sourceText,_this.lineBreak);
}

@override
String toString() {
  final _this = this as TrialArea;
  return 'TrialArea(areaId: ${_this.areaId}, sourceText: ${_this.sourceText}, lineBreak: ${_this.lineBreak})';
}


}

/// @nodoc
abstract mixin class $TrialAreaCopyWith<$Res>  {
  factory $TrialAreaCopyWith(TrialArea value, $Res Function(TrialArea) _then) = _$TrialAreaCopyWithImpl;
@useResult
$Res call({
 String areaId, String sourceText, TrialBreak lineBreak
});


$TrialBreakCopyWith<$Res> get lineBreak;

}
/// @nodoc
class _$TrialAreaCopyWithImpl<$Res>
    implements $TrialAreaCopyWith<$Res> {
  _$TrialAreaCopyWithImpl(this._self, this._then);

  final TrialArea _self;
  final $Res Function(TrialArea) _then;

/// Create a copy of TrialArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? sourceText = null,Object? lineBreak = null,}) {
  return _then(TrialArea(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,sourceText: null == sourceText ? _self.sourceText : sourceText // ignore: cast_nullable_to_non_nullable
as String,lineBreak: null == lineBreak ? _self.lineBreak : lineBreak // ignore: cast_nullable_to_non_nullable
as TrialBreak,
  ));
}
/// Create a copy of TrialArea
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrialBreakCopyWith<$Res> get lineBreak {
  
  return $TrialBreakCopyWith<$Res>(_self.lineBreak, (value) {
    return _then(_self.copyWith(lineBreak: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrialArea].
extension TrialAreaPatterns on TrialArea {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$TrialBreak {


/// Create a copy of TrialBreak
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrialBreakCopyWith<TrialBreak> get copyWith => _$TrialBreakCopyWithImpl<TrialBreak>(this as TrialBreak, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TrialBreak;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrialBreak&&(identical(other.mode, _this.mode) || other.mode == _this.mode)&&const DeepCollectionEquality().equals(other.lines, _this.lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrialBreak;
  return Object.hash(runtimeType,_this.mode,const DeepCollectionEquality().hash(_this.lines));
}

@override
String toString() {
  final _this = this as TrialBreak;
  return 'TrialBreak(mode: ${_this.mode}, lines: ${_this.lines})';
}


}

/// @nodoc
abstract mixin class $TrialBreakCopyWith<$Res>  {
  factory $TrialBreakCopyWith(TrialBreak value, $Res Function(TrialBreak) _then) = _$TrialBreakCopyWithImpl;
@useResult
$Res call({
 String mode, List<String>? lines
});




}
/// @nodoc
class _$TrialBreakCopyWithImpl<$Res>
    implements $TrialBreakCopyWith<$Res> {
  _$TrialBreakCopyWithImpl(this._self, this._then);

  final TrialBreak _self;
  final $Res Function(TrialBreak) _then;

/// Create a copy of TrialBreak
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? lines = freezed,}) {
  return _then(TrialBreak(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as String,lines: freezed == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrialBreak].
extension TrialBreakPatterns on TrialBreak {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
