// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecordModel _$RecordModelFromJson(Map<String, dynamic> json) {
  return _RecordModel.fromJson(json);
}

/// @nodoc
mixin _$RecordModel {
  String? get thumb => throw _privateConstructorUsedError;
  String? get banner => throw _privateConstructorUsedError;
  String? get poster => throw _privateConstructorUsedError;
  String? get trailer => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecordModelCopyWith<RecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecordModelCopyWith<$Res> {
  factory $RecordModelCopyWith(
          RecordModel value, $Res Function(RecordModel) then) =
      _$RecordModelCopyWithImpl<$Res, RecordModel>;
  @useResult
  $Res call(
      {String? thumb,
      String? banner,
      String? poster,
      String? trailer,
      String? source});
}

/// @nodoc
class _$RecordModelCopyWithImpl<$Res, $Val extends RecordModel>
    implements $RecordModelCopyWith<$Res> {
  _$RecordModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumb = freezed,
    Object? banner = freezed,
    Object? poster = freezed,
    Object? trailer = freezed,
    Object? source = freezed,
  }) {
    return _then(_value.copyWith(
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      banner: freezed == banner
          ? _value.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as String?,
      poster: freezed == poster
          ? _value.poster
          : poster // ignore: cast_nullable_to_non_nullable
              as String?,
      trailer: freezed == trailer
          ? _value.trailer
          : trailer // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecordModelImplCopyWith<$Res>
    implements $RecordModelCopyWith<$Res> {
  factory _$$RecordModelImplCopyWith(
          _$RecordModelImpl value, $Res Function(_$RecordModelImpl) then) =
      __$$RecordModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? thumb,
      String? banner,
      String? poster,
      String? trailer,
      String? source});
}

/// @nodoc
class __$$RecordModelImplCopyWithImpl<$Res>
    extends _$RecordModelCopyWithImpl<$Res, _$RecordModelImpl>
    implements _$$RecordModelImplCopyWith<$Res> {
  __$$RecordModelImplCopyWithImpl(
      _$RecordModelImpl _value, $Res Function(_$RecordModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? thumb = freezed,
    Object? banner = freezed,
    Object? poster = freezed,
    Object? trailer = freezed,
    Object? source = freezed,
  }) {
    return _then(_$RecordModelImpl(
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      banner: freezed == banner
          ? _value.banner
          : banner // ignore: cast_nullable_to_non_nullable
              as String?,
      poster: freezed == poster
          ? _value.poster
          : poster // ignore: cast_nullable_to_non_nullable
              as String?,
      trailer: freezed == trailer
          ? _value.trailer
          : trailer // ignore: cast_nullable_to_non_nullable
              as String?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecordModelImpl implements _RecordModel {
  const _$RecordModelImpl(
      {required this.thumb,
      required this.banner,
      required this.poster,
      required this.trailer,
      required this.source});

  factory _$RecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecordModelImplFromJson(json);

  @override
  final String? thumb;
  @override
  final String? banner;
  @override
  final String? poster;
  @override
  final String? trailer;
  @override
  final String? source;

  @override
  String toString() {
    return 'RecordModel(thumb: $thumb, banner: $banner, poster: $poster, trailer: $trailer, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecordModelImpl &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.banner, banner) || other.banner == banner) &&
            (identical(other.poster, poster) || other.poster == poster) &&
            (identical(other.trailer, trailer) || other.trailer == trailer) &&
            (identical(other.source, source) || other.source == source));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, thumb, banner, poster, trailer, source);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecordModelImplCopyWith<_$RecordModelImpl> get copyWith =>
      __$$RecordModelImplCopyWithImpl<_$RecordModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecordModelImplToJson(
      this,
    );
  }
}

abstract class _RecordModel implements RecordModel {
  const factory _RecordModel(
      {required final String? thumb,
      required final String? banner,
      required final String? poster,
      required final String? trailer,
      required final String? source}) = _$RecordModelImpl;

  factory _RecordModel.fromJson(Map<String, dynamic> json) =
      _$RecordModelImpl.fromJson;

  @override
  String? get thumb;
  @override
  String? get banner;
  @override
  String? get poster;
  @override
  String? get trailer;
  @override
  String? get source;
  @override
  @JsonKey(ignore: true)
  _$$RecordModelImplCopyWith<_$RecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
