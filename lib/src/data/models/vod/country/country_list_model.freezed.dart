// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'country_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CountryListModel _$CountryListModelFromJson(Map<String, dynamic> json) {
  return _CountryListModel.fromJson(json);
}

/// @nodoc
mixin _$CountryListModel {
  @JsonKey(name: 'data')
  List<CountryModel> get countries => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CountryListModelCopyWith<CountryListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CountryListModelCopyWith<$Res> {
  factory $CountryListModelCopyWith(
          CountryListModel value, $Res Function(CountryListModel) then) =
      _$CountryListModelCopyWithImpl<$Res, CountryListModel>;
  @useResult
  $Res call({@JsonKey(name: 'data') List<CountryModel> countries});
}

/// @nodoc
class _$CountryListModelCopyWithImpl<$Res, $Val extends CountryListModel>
    implements $CountryListModelCopyWith<$Res> {
  _$CountryListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? countries = null,
  }) {
    return _then(_value.copyWith(
      countries: null == countries
          ? _value.countries
          : countries // ignore: cast_nullable_to_non_nullable
              as List<CountryModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CountryListModelImplCopyWith<$Res>
    implements $CountryListModelCopyWith<$Res> {
  factory _$$CountryListModelImplCopyWith(_$CountryListModelImpl value,
          $Res Function(_$CountryListModelImpl) then) =
      __$$CountryListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'data') List<CountryModel> countries});
}

/// @nodoc
class __$$CountryListModelImplCopyWithImpl<$Res>
    extends _$CountryListModelCopyWithImpl<$Res, _$CountryListModelImpl>
    implements _$$CountryListModelImplCopyWith<$Res> {
  __$$CountryListModelImplCopyWithImpl(_$CountryListModelImpl _value,
      $Res Function(_$CountryListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? countries = null,
  }) {
    return _then(_$CountryListModelImpl(
      countries: null == countries
          ? _value._countries
          : countries // ignore: cast_nullable_to_non_nullable
              as List<CountryModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CountryListModelImpl implements _CountryListModel {
  const _$CountryListModelImpl(
      {@JsonKey(name: 'data') required final List<CountryModel> countries})
      : _countries = countries;

  factory _$CountryListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CountryListModelImplFromJson(json);

  final List<CountryModel> _countries;
  @override
  @JsonKey(name: 'data')
  List<CountryModel> get countries {
    if (_countries is EqualUnmodifiableListView) return _countries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_countries);
  }

  @override
  String toString() {
    return 'CountryListModel(countries: $countries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CountryListModelImpl &&
            const DeepCollectionEquality()
                .equals(other._countries, _countries));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_countries));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CountryListModelImplCopyWith<_$CountryListModelImpl> get copyWith =>
      __$$CountryListModelImplCopyWithImpl<_$CountryListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CountryListModelImplToJson(
      this,
    );
  }
}

abstract class _CountryListModel implements CountryListModel {
  const factory _CountryListModel(
      {@JsonKey(name: 'data')
      required final List<CountryModel> countries}) = _$CountryListModelImpl;

  factory _CountryListModel.fromJson(Map<String, dynamic> json) =
      _$CountryListModelImpl.fromJson;

  @override
  @JsonKey(name: 'data')
  List<CountryModel> get countries;
  @override
  @JsonKey(ignore: true)
  _$$CountryListModelImplCopyWith<_$CountryListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
