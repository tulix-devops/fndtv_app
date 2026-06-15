// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OnboardingModel _$OnboardingModelFromJson(Map<String, dynamic> json) {
  return _OnboardingModel.fromJson(json);
}

/// @nodoc
mixin _$OnboardingModel {
  int get id => throw _privateConstructorUsedError;
  int? get orderId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OnboardingModelCopyWith<OnboardingModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingModelCopyWith<$Res> {
  factory $OnboardingModelCopyWith(
          OnboardingModel value, $Res Function(OnboardingModel) then) =
      _$OnboardingModelCopyWithImpl<$Res, OnboardingModel>;
  @useResult
  $Res call({int id, int? orderId, String name, String description});
}

/// @nodoc
class _$OnboardingModelCopyWithImpl<$Res, $Val extends OnboardingModel>
    implements $OnboardingModelCopyWith<$Res> {
  _$OnboardingModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? name = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OnboardingModelImplCopyWith<$Res>
    implements $OnboardingModelCopyWith<$Res> {
  factory _$$OnboardingModelImplCopyWith(_$OnboardingModelImpl value,
          $Res Function(_$OnboardingModelImpl) then) =
      __$$OnboardingModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, int? orderId, String name, String description});
}

/// @nodoc
class __$$OnboardingModelImplCopyWithImpl<$Res>
    extends _$OnboardingModelCopyWithImpl<$Res, _$OnboardingModelImpl>
    implements _$$OnboardingModelImplCopyWith<$Res> {
  __$$OnboardingModelImplCopyWithImpl(
      _$OnboardingModelImpl _value, $Res Function(_$OnboardingModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? orderId = freezed,
    Object? name = null,
    Object? description = null,
  }) {
    return _then(_$OnboardingModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingModelImpl
    with DiagnosticableTreeMixin
    implements _OnboardingModel {
  const _$OnboardingModelImpl(
      {required this.id,
      required this.orderId,
      required this.name,
      required this.description});

  factory _$OnboardingModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingModelImplFromJson(json);

  @override
  final int id;
  @override
  final int? orderId;
  @override
  final String name;
  @override
  final String description;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'OnboardingModel(id: $id, orderId: $orderId, name: $name, description: $description)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'OnboardingModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('orderId', orderId))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('description', description));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, orderId, name, description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingModelImplCopyWith<_$OnboardingModelImpl> get copyWith =>
      __$$OnboardingModelImplCopyWithImpl<_$OnboardingModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingModelImplToJson(
      this,
    );
  }
}

abstract class _OnboardingModel implements OnboardingModel {
  const factory _OnboardingModel(
      {required final int id,
      required final int? orderId,
      required final String name,
      required final String description}) = _$OnboardingModelImpl;

  factory _OnboardingModel.fromJson(Map<String, dynamic> json) =
      _$OnboardingModelImpl.fromJson;

  @override
  int get id;
  @override
  int? get orderId;
  @override
  String get name;
  @override
  String get description;
  @override
  @JsonKey(ignore: true)
  _$$OnboardingModelImplCopyWith<_$OnboardingModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
