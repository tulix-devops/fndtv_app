// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_list_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CategoryListModel _$CategoryListModelFromJson(Map<String, dynamic> json) {
  return _CategoryListModel.fromJson(json);
}

/// @nodoc
mixin _$CategoryListModel {
  @JsonKey(name: 'data')
  List<CategoryModel> get categories => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CategoryListModelCopyWith<CategoryListModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryListModelCopyWith<$Res> {
  factory $CategoryListModelCopyWith(
          CategoryListModel value, $Res Function(CategoryListModel) then) =
      _$CategoryListModelCopyWithImpl<$Res, CategoryListModel>;
  @useResult
  $Res call({@JsonKey(name: 'data') List<CategoryModel> categories});
}

/// @nodoc
class _$CategoryListModelCopyWithImpl<$Res, $Val extends CategoryListModel>
    implements $CategoryListModelCopyWith<$Res> {
  _$CategoryListModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
  }) {
    return _then(_value.copyWith(
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryListModelImplCopyWith<$Res>
    implements $CategoryListModelCopyWith<$Res> {
  factory _$$CategoryListModelImplCopyWith(_$CategoryListModelImpl value,
          $Res Function(_$CategoryListModelImpl) then) =
      __$$CategoryListModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'data') List<CategoryModel> categories});
}

/// @nodoc
class __$$CategoryListModelImplCopyWithImpl<$Res>
    extends _$CategoryListModelCopyWithImpl<$Res, _$CategoryListModelImpl>
    implements _$$CategoryListModelImplCopyWith<$Res> {
  __$$CategoryListModelImplCopyWithImpl(_$CategoryListModelImpl _value,
      $Res Function(_$CategoryListModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
  }) {
    return _then(_$CategoryListModelImpl(
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryListModelImpl implements _CategoryListModel {
  const _$CategoryListModelImpl(
      {@JsonKey(name: 'data') required final List<CategoryModel> categories})
      : _categories = categories;

  factory _$CategoryListModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryListModelImplFromJson(json);

  final List<CategoryModel> _categories;
  @override
  @JsonKey(name: 'data')
  List<CategoryModel> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  String toString() {
    return 'CategoryListModel(categories: $categories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryListModelImpl &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_categories));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryListModelImplCopyWith<_$CategoryListModelImpl> get copyWith =>
      __$$CategoryListModelImplCopyWithImpl<_$CategoryListModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryListModelImplToJson(
      this,
    );
  }
}

abstract class _CategoryListModel implements CategoryListModel {
  const factory _CategoryListModel(
      {@JsonKey(name: 'data')
      required final List<CategoryModel> categories}) = _$CategoryListModelImpl;

  factory _CategoryListModel.fromJson(Map<String, dynamic> json) =
      _$CategoryListModelImpl.fromJson;

  @override
  @JsonKey(name: 'data')
  List<CategoryModel> get categories;
  @override
  @JsonKey(ignore: true)
  _$$CategoryListModelImplCopyWith<_$CategoryListModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
