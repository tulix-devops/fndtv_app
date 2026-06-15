// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OnboardingListModel _$OnboardingListModelFromJson(Map<String, dynamic> json) {
  return _OnboardingListModel.fromJson(json);
}

/// @nodoc
mixin _$OnboardingListModel {
// ignore: invalid_annotation_target
  @JsonKey(name: 'data')
  List<OnboardingModel> get tabs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OnboardingListModelCopyWith<OnboardingListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OnboardingListModelCopyWith<$Res> {
  factory $OnboardingListModelCopyWith(
          OnboardingListModel value, $Res Function(OnboardingListModel) then) =
      _$OnboardingListModelCopyWithImpl<$Res, OnboardingListModel>;
  @useResult
  $Res call({@JsonKey(name: 'data') List<OnboardingModel> tabs});
}

/// @nodoc
class _$OnboardingListModelCopyWithImpl<$Res, $Val extends OnboardingListModel>
    implements $OnboardingListModelCopyWith<$Res> {
  _$OnboardingListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tabs = null,
  }) {
    return _then(_value.copyWith(
      tabs: null == tabs
          ? _value.tabs
          : tabs // ignore: cast_nullable_to_non_nullable
              as List<OnboardingModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OnboardingListModelImplCopyWith<$Res>
    implements $OnboardingListModelCopyWith<$Res> {
  factory _$$OnboardingListModelImplCopyWith(_$OnboardingListModelImpl value,
          $Res Function(_$OnboardingListModelImpl) then) =
      __$$OnboardingListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'data') List<OnboardingModel> tabs});
}

/// @nodoc
class __$$OnboardingListModelImplCopyWithImpl<$Res>
    extends _$OnboardingListModelCopyWithImpl<$Res, _$OnboardingListModelImpl>
    implements _$$OnboardingListModelImplCopyWith<$Res> {
  __$$OnboardingListModelImplCopyWithImpl(_$OnboardingListModelImpl _value,
      $Res Function(_$OnboardingListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tabs = null,
  }) {
    return _then(_$OnboardingListModelImpl(
      tabs: null == tabs
          ? _value._tabs
          : tabs // ignore: cast_nullable_to_non_nullable
              as List<OnboardingModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OnboardingListModelImpl implements _OnboardingListModel {
  const _$OnboardingListModelImpl(
      {@JsonKey(name: 'data') required final List<OnboardingModel> tabs})
      : _tabs = tabs;

  factory _$OnboardingListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$OnboardingListModelImplFromJson(json);

// ignore: invalid_annotation_target
  final List<OnboardingModel> _tabs;
// ignore: invalid_annotation_target
  @override
  @JsonKey(name: 'data')
  List<OnboardingModel> get tabs {
    if (_tabs is EqualUnmodifiableListView) return _tabs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tabs);
  }

  @override
  String toString() {
    return 'OnboardingListModel(tabs: $tabs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OnboardingListModelImpl &&
            const DeepCollectionEquality().equals(other._tabs, _tabs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_tabs));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OnboardingListModelImplCopyWith<_$OnboardingListModelImpl> get copyWith =>
      __$$OnboardingListModelImplCopyWithImpl<_$OnboardingListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OnboardingListModelImplToJson(
      this,
    );
  }
}

abstract class _OnboardingListModel implements OnboardingListModel {
  const factory _OnboardingListModel(
          {@JsonKey(name: 'data') required final List<OnboardingModel> tabs}) =
      _$OnboardingListModelImpl;

  factory _OnboardingListModel.fromJson(Map<String, dynamic> json) =
      _$OnboardingListModelImpl.fromJson;

  @override // ignore: invalid_annotation_target
  @JsonKey(name: 'data')
  List<OnboardingModel> get tabs;
  @override
  @JsonKey(ignore: true)
  _$$OnboardingListModelImplCopyWith<_$OnboardingListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
