// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'actor_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ActorModel _$ActorModelFromJson(Map<String, dynamic> json) {
  return _ActorModel.fromJson(json);
}

/// @nodoc
mixin _$ActorModel {
  int get id => throw _privateConstructorUsedError;
  int get storageRecordId => throw _privateConstructorUsedError;
  int get storageRecordTypeId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int get birthYear => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ActorModelCopyWith<ActorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActorModelCopyWith<$Res> {
  factory $ActorModelCopyWith(
          ActorModel value, $Res Function(ActorModel) then) =
      _$ActorModelCopyWithImpl<$Res, ActorModel>;
  @useResult
  $Res call(
      {int id,
      int storageRecordId,
      int storageRecordTypeId,
      String title,
      String description,
      int birthYear});
}

/// @nodoc
class _$ActorModelCopyWithImpl<$Res, $Val extends ActorModel>
    implements $ActorModelCopyWith<$Res> {
  _$ActorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storageRecordId = null,
    Object? storageRecordTypeId = null,
    Object? title = null,
    Object? description = null,
    Object? birthYear = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      storageRecordId: null == storageRecordId
          ? _value.storageRecordId
          : storageRecordId // ignore: cast_nullable_to_non_nullable
              as int,
      storageRecordTypeId: null == storageRecordTypeId
          ? _value.storageRecordTypeId
          : storageRecordTypeId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      birthYear: null == birthYear
          ? _value.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActorModelImplCopyWith<$Res>
    implements $ActorModelCopyWith<$Res> {
  factory _$$ActorModelImplCopyWith(
          _$ActorModelImpl value, $Res Function(_$ActorModelImpl) then) =
      __$$ActorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int storageRecordId,
      int storageRecordTypeId,
      String title,
      String description,
      int birthYear});
}

/// @nodoc
class __$$ActorModelImplCopyWithImpl<$Res>
    extends _$ActorModelCopyWithImpl<$Res, _$ActorModelImpl>
    implements _$$ActorModelImplCopyWith<$Res> {
  __$$ActorModelImplCopyWithImpl(
      _$ActorModelImpl _value, $Res Function(_$ActorModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? storageRecordId = null,
    Object? storageRecordTypeId = null,
    Object? title = null,
    Object? description = null,
    Object? birthYear = null,
  }) {
    return _then(_$ActorModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      storageRecordId: null == storageRecordId
          ? _value.storageRecordId
          : storageRecordId // ignore: cast_nullable_to_non_nullable
              as int,
      storageRecordTypeId: null == storageRecordTypeId
          ? _value.storageRecordTypeId
          : storageRecordTypeId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      birthYear: null == birthYear
          ? _value.birthYear
          : birthYear // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ActorModelImpl implements _ActorModel {
  const _$ActorModelImpl(
      {required this.id,
      required this.storageRecordId,
      required this.storageRecordTypeId,
      required this.title,
      required this.description,
      required this.birthYear});

  factory _$ActorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ActorModelImplFromJson(json);

  @override
  final int id;
  @override
  final int storageRecordId;
  @override
  final int storageRecordTypeId;
  @override
  final String title;
  @override
  final String description;
  @override
  final int birthYear;

  @override
  String toString() {
    return 'ActorModel(id: $id, storageRecordId: $storageRecordId, storageRecordTypeId: $storageRecordTypeId, title: $title, description: $description, birthYear: $birthYear)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.storageRecordId, storageRecordId) ||
                other.storageRecordId == storageRecordId) &&
            (identical(other.storageRecordTypeId, storageRecordTypeId) ||
                other.storageRecordTypeId == storageRecordTypeId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.birthYear, birthYear) ||
                other.birthYear == birthYear));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, storageRecordId,
      storageRecordTypeId, title, description, birthYear);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ActorModelImplCopyWith<_$ActorModelImpl> get copyWith =>
      __$$ActorModelImplCopyWithImpl<_$ActorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ActorModelImplToJson(
      this,
    );
  }
}

abstract class _ActorModel implements ActorModel {
  const factory _ActorModel(
      {required final int id,
      required final int storageRecordId,
      required final int storageRecordTypeId,
      required final String title,
      required final String description,
      required final int birthYear}) = _$ActorModelImpl;

  factory _ActorModel.fromJson(Map<String, dynamic> json) =
      _$ActorModelImpl.fromJson;

  @override
  int get id;
  @override
  int get storageRecordId;
  @override
  int get storageRecordTypeId;
  @override
  String get title;
  @override
  String get description;
  @override
  int get birthYear;
  @override
  @JsonKey(ignore: true)
  _$$ActorModelImplCopyWith<_$ActorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
