// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_record_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StorageRecordModel _$StorageRecordModelFromJson(Map<String, dynamic> json) {
  return _StorageRecordModel.fromJson(json);
}

/// @nodoc
mixin _$StorageRecordModel {
  String? get thumb => throw _privateConstructorUsedError;
  String? get banner => throw _privateConstructorUsedError;
  String? get poster => throw _privateConstructorUsedError;
  String? get trailer => throw _privateConstructorUsedError;
  String? get source => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StorageRecordModelCopyWith<StorageRecordModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StorageRecordModelCopyWith<$Res> {
  factory $StorageRecordModelCopyWith(
          StorageRecordModel value, $Res Function(StorageRecordModel) then) =
      _$StorageRecordModelCopyWithImpl<$Res, StorageRecordModel>;
  @useResult
  $Res call(
      {String? thumb,
      String? banner,
      String? poster,
      String? trailer,
      String? source});
}

/// @nodoc
class _$StorageRecordModelCopyWithImpl<$Res, $Val extends StorageRecordModel>
    implements $StorageRecordModelCopyWith<$Res> {
  _$StorageRecordModelCopyWithImpl(this._value, this._then);

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
abstract class _$$StorageRecordModelImplCopyWith<$Res>
    implements $StorageRecordModelCopyWith<$Res> {
  factory _$$StorageRecordModelImplCopyWith(_$StorageRecordModelImpl value,
          $Res Function(_$StorageRecordModelImpl) then) =
      __$$StorageRecordModelImplCopyWithImpl<$Res>;
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
class __$$StorageRecordModelImplCopyWithImpl<$Res>
    extends _$StorageRecordModelCopyWithImpl<$Res, _$StorageRecordModelImpl>
    implements _$$StorageRecordModelImplCopyWith<$Res> {
  __$$StorageRecordModelImplCopyWithImpl(_$StorageRecordModelImpl _value,
      $Res Function(_$StorageRecordModelImpl) _then)
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
    return _then(_$StorageRecordModelImpl(
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
class _$StorageRecordModelImpl implements _StorageRecordModel {
  const _$StorageRecordModelImpl(
      {required this.thumb,
      required this.banner,
      required this.poster,
      required this.trailer,
      required this.source});

  factory _$StorageRecordModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StorageRecordModelImplFromJson(json);

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
    return 'StorageRecordModel(thumb: $thumb, banner: $banner, poster: $poster, trailer: $trailer, source: $source)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageRecordModelImpl &&
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
  _$$StorageRecordModelImplCopyWith<_$StorageRecordModelImpl> get copyWith =>
      __$$StorageRecordModelImplCopyWithImpl<_$StorageRecordModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StorageRecordModelImplToJson(
      this,
    );
  }
}

abstract class _StorageRecordModel implements StorageRecordModel {
  const factory _StorageRecordModel(
      {required final String? thumb,
      required final String? banner,
      required final String? poster,
      required final String? trailer,
      required final String? source}) = _$StorageRecordModelImpl;

  factory _StorageRecordModel.fromJson(Map<String, dynamic> json) =
      _$StorageRecordModelImpl.fromJson;

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
  _$$StorageRecordModelImplCopyWith<_$StorageRecordModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
