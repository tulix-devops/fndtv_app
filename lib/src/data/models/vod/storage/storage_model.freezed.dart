// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'storage_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StorageModel _$StorageModelFromJson(Map<String, dynamic> json) {
  return _StorageModel.fromJson(json);
}

/// @nodoc
mixin _$StorageModel {
  int get id => throw _privateConstructorUsedError;
  int get statusId => throw _privateConstructorUsedError;
  int get typeId => throw _privateConstructorUsedError;
  RecordModel get record => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StorageModelCopyWith<StorageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StorageModelCopyWith<$Res> {
  factory $StorageModelCopyWith(
          StorageModel value, $Res Function(StorageModel) then) =
      _$StorageModelCopyWithImpl<$Res, StorageModel>;
  @useResult
  $Res call({int id, int statusId, int typeId, RecordModel record});

  $RecordModelCopyWith<$Res> get record;
}

/// @nodoc
class _$StorageModelCopyWithImpl<$Res, $Val extends StorageModel>
    implements $StorageModelCopyWith<$Res> {
  _$StorageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? statusId = null,
    Object? typeId = null,
    Object? record = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as int,
      typeId: null == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as int,
      record: null == record
          ? _value.record
          : record // ignore: cast_nullable_to_non_nullable
              as RecordModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RecordModelCopyWith<$Res> get record {
    return $RecordModelCopyWith<$Res>(_value.record, (value) {
      return _then(_value.copyWith(record: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StorageModelImplCopyWith<$Res>
    implements $StorageModelCopyWith<$Res> {
  factory _$$StorageModelImplCopyWith(
          _$StorageModelImpl value, $Res Function(_$StorageModelImpl) then) =
      __$$StorageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, int statusId, int typeId, RecordModel record});

  @override
  $RecordModelCopyWith<$Res> get record;
}

/// @nodoc
class __$$StorageModelImplCopyWithImpl<$Res>
    extends _$StorageModelCopyWithImpl<$Res, _$StorageModelImpl>
    implements _$$StorageModelImplCopyWith<$Res> {
  __$$StorageModelImplCopyWithImpl(
      _$StorageModelImpl _value, $Res Function(_$StorageModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? statusId = null,
    Object? typeId = null,
    Object? record = null,
  }) {
    return _then(_$StorageModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: null == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as int,
      typeId: null == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as int,
      record: null == record
          ? _value.record
          : record // ignore: cast_nullable_to_non_nullable
              as RecordModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StorageModelImpl implements _StorageModel {
  const _$StorageModelImpl(
      {required this.id,
      required this.statusId,
      required this.typeId,
      required this.record});

  factory _$StorageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StorageModelImplFromJson(json);

  @override
  final int id;
  @override
  final int statusId;
  @override
  final int typeId;
  @override
  final RecordModel record;

  @override
  String toString() {
    return 'StorageModel(id: $id, statusId: $statusId, typeId: $typeId, record: $record)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StorageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId) &&
            (identical(other.typeId, typeId) || other.typeId == typeId) &&
            (identical(other.record, record) || other.record == record));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, statusId, typeId, record);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StorageModelImplCopyWith<_$StorageModelImpl> get copyWith =>
      __$$StorageModelImplCopyWithImpl<_$StorageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StorageModelImplToJson(
      this,
    );
  }
}

abstract class _StorageModel implements StorageModel {
  const factory _StorageModel(
      {required final int id,
      required final int statusId,
      required final int typeId,
      required final RecordModel record}) = _$StorageModelImpl;

  factory _StorageModel.fromJson(Map<String, dynamic> json) =
      _$StorageModelImpl.fromJson;

  @override
  int get id;
  @override
  int get statusId;
  @override
  int get typeId;
  @override
  RecordModel get record;
  @override
  @JsonKey(ignore: true)
  _$$StorageModelImplCopyWith<_$StorageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
