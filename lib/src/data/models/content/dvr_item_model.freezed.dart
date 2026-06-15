// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dvr_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DvrItemModel _$DvrItemModelFromJson(Map<String, dynamic> json) {
  return _DvrItemModel.fromJson(json);
}

/// @nodoc
mixin _$DvrItemModel {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String get title => throw _privateConstructorUsedError;
  String get descr => throw _privateConstructorUsedError;
  @JsonKey(name: 'length')
  String? get duration => throw _privateConstructorUsedError;
  @JsonKey(name: 'hdposterurl')
  String? get thumb => throw _privateConstructorUsedError;
  @JsonKey(name: 'hls')
  String get stream => throw _privateConstructorUsedError;
  String? get downloadurl => throw _privateConstructorUsedError;
  @JsonKey(name: 'islive')
  int? get isLive => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DvrItemModelCopyWith<DvrItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DvrItemModelCopyWith<$Res> {
  factory $DvrItemModelCopyWith(
          DvrItemModel value, $Res Function(DvrItemModel) then) =
      _$DvrItemModelCopyWithImpl<$Res, DvrItemModel>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'name') String title,
      String descr,
      @JsonKey(name: 'length') String? duration,
      @JsonKey(name: 'hdposterurl') String? thumb,
      @JsonKey(name: 'hls') String stream,
      String? downloadurl,
      @JsonKey(name: 'islive') int? isLive});
}

/// @nodoc
class _$DvrItemModelCopyWithImpl<$Res, $Val extends DvrItemModel>
    implements $DvrItemModelCopyWith<$Res> {
  _$DvrItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? descr = null,
    Object? duration = freezed,
    Object? thumb = freezed,
    Object? stream = null,
    Object? downloadurl = freezed,
    Object? isLive = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      descr: null == descr
          ? _value.descr
          : descr // ignore: cast_nullable_to_non_nullable
              as String,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String?,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: null == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String,
      downloadurl: freezed == downloadurl
          ? _value.downloadurl
          : downloadurl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLive: freezed == isLive
          ? _value.isLive
          : isLive // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DvrItemModelImplCopyWith<$Res>
    implements $DvrItemModelCopyWith<$Res> {
  factory _$$DvrItemModelImplCopyWith(
          _$DvrItemModelImpl value, $Res Function(_$DvrItemModelImpl) then) =
      __$$DvrItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'name') String title,
      String descr,
      @JsonKey(name: 'length') String? duration,
      @JsonKey(name: 'hdposterurl') String? thumb,
      @JsonKey(name: 'hls') String stream,
      String? downloadurl,
      @JsonKey(name: 'islive') int? isLive});
}

/// @nodoc
class __$$DvrItemModelImplCopyWithImpl<$Res>
    extends _$DvrItemModelCopyWithImpl<$Res, _$DvrItemModelImpl>
    implements _$$DvrItemModelImplCopyWith<$Res> {
  __$$DvrItemModelImplCopyWithImpl(
      _$DvrItemModelImpl _value, $Res Function(_$DvrItemModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? descr = null,
    Object? duration = freezed,
    Object? thumb = freezed,
    Object? stream = null,
    Object? downloadurl = freezed,
    Object? isLive = freezed,
  }) {
    return _then(_$DvrItemModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      descr: null == descr
          ? _value.descr
          : descr // ignore: cast_nullable_to_non_nullable
              as String,
      duration: freezed == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String?,
      thumb: freezed == thumb
          ? _value.thumb
          : thumb // ignore: cast_nullable_to_non_nullable
              as String?,
      stream: null == stream
          ? _value.stream
          : stream // ignore: cast_nullable_to_non_nullable
              as String,
      downloadurl: freezed == downloadurl
          ? _value.downloadurl
          : downloadurl // ignore: cast_nullable_to_non_nullable
              as String?,
      isLive: freezed == isLive
          ? _value.isLive
          : isLive // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DvrItemModelImpl extends _DvrItemModel {
  const _$DvrItemModelImpl(
      {required this.id,
      @JsonKey(name: 'name') required this.title,
      required this.descr,
      @JsonKey(name: 'length') this.duration,
      @JsonKey(name: 'hdposterurl') this.thumb,
      @JsonKey(name: 'hls') required this.stream,
      this.downloadurl,
      @JsonKey(name: 'islive') this.isLive})
      : super._();

  factory _$DvrItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DvrItemModelImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'name')
  final String title;
  @override
  final String descr;
  @override
  @JsonKey(name: 'length')
  final String? duration;
  @override
  @JsonKey(name: 'hdposterurl')
  final String? thumb;
  @override
  @JsonKey(name: 'hls')
  final String stream;
  @override
  final String? downloadurl;
  @override
  @JsonKey(name: 'islive')
  final int? isLive;

  @override
  String toString() {
    return 'DvrItemModel(id: $id, title: $title, descr: $descr, duration: $duration, thumb: $thumb, stream: $stream, downloadurl: $downloadurl, isLive: $isLive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DvrItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.descr, descr) || other.descr == descr) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.thumb, thumb) || other.thumb == thumb) &&
            (identical(other.stream, stream) || other.stream == stream) &&
            (identical(other.downloadurl, downloadurl) ||
                other.downloadurl == downloadurl) &&
            (identical(other.isLive, isLive) || other.isLive == isLive));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, descr, duration,
      thumb, stream, downloadurl, isLive);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DvrItemModelImplCopyWith<_$DvrItemModelImpl> get copyWith =>
      __$$DvrItemModelImplCopyWithImpl<_$DvrItemModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DvrItemModelImplToJson(
      this,
    );
  }
}

abstract class _DvrItemModel extends DvrItemModel {
  const factory _DvrItemModel(
      {required final int id,
      @JsonKey(name: 'name') required final String title,
      required final String descr,
      @JsonKey(name: 'length') final String? duration,
      @JsonKey(name: 'hdposterurl') final String? thumb,
      @JsonKey(name: 'hls') required final String stream,
      final String? downloadurl,
      @JsonKey(name: 'islive') final int? isLive}) = _$DvrItemModelImpl;
  const _DvrItemModel._() : super._();

  factory _DvrItemModel.fromJson(Map<String, dynamic> json) =
      _$DvrItemModelImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'name')
  String get title;
  @override
  String get descr;
  @override
  @JsonKey(name: 'length')
  String? get duration;
  @override
  @JsonKey(name: 'hdposterurl')
  String? get thumb;
  @override
  @JsonKey(name: 'hls')
  String get stream;
  @override
  String? get downloadurl;
  @override
  @JsonKey(name: 'islive')
  int? get isLive;
  @override
  @JsonKey(ignore: true)
  _$$DvrItemModelImplCopyWith<_$DvrItemModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DvrDataModel _$DvrDataModelFromJson(Map<String, dynamic> json) {
  return _DvrDataModel.fromJson(json);
}

/// @nodoc
mixin _$DvrDataModel {
  List<DvrItemModel> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DvrDataModelCopyWith<DvrDataModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DvrDataModelCopyWith<$Res> {
  factory $DvrDataModelCopyWith(
          DvrDataModel value, $Res Function(DvrDataModel) then) =
      _$DvrDataModelCopyWithImpl<$Res, DvrDataModel>;
  @useResult
  $Res call({List<DvrItemModel> items});
}

/// @nodoc
class _$DvrDataModelCopyWithImpl<$Res, $Val extends DvrDataModel>
    implements $DvrDataModelCopyWith<$Res> {
  _$DvrDataModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DvrItemModel>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DvrDataModelImplCopyWith<$Res>
    implements $DvrDataModelCopyWith<$Res> {
  factory _$$DvrDataModelImplCopyWith(
          _$DvrDataModelImpl value, $Res Function(_$DvrDataModelImpl) then) =
      __$$DvrDataModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<DvrItemModel> items});
}

/// @nodoc
class __$$DvrDataModelImplCopyWithImpl<$Res>
    extends _$DvrDataModelCopyWithImpl<$Res, _$DvrDataModelImpl>
    implements _$$DvrDataModelImplCopyWith<$Res> {
  __$$DvrDataModelImplCopyWithImpl(
      _$DvrDataModelImpl _value, $Res Function(_$DvrDataModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
  }) {
    return _then(_$DvrDataModelImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DvrItemModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DvrDataModelImpl extends _DvrDataModel {
  const _$DvrDataModelImpl({required final List<DvrItemModel> items})
      : _items = items,
        super._();

  factory _$DvrDataModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DvrDataModelImplFromJson(json);

  final List<DvrItemModel> _items;
  @override
  List<DvrItemModel> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'DvrDataModel(items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DvrDataModelImpl &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DvrDataModelImplCopyWith<_$DvrDataModelImpl> get copyWith =>
      __$$DvrDataModelImplCopyWithImpl<_$DvrDataModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DvrDataModelImplToJson(
      this,
    );
  }
}

abstract class _DvrDataModel extends DvrDataModel {
  const factory _DvrDataModel({required final List<DvrItemModel> items}) =
      _$DvrDataModelImpl;
  const _DvrDataModel._() : super._();

  factory _DvrDataModel.fromJson(Map<String, dynamic> json) =
      _$DvrDataModelImpl.fromJson;

  @override
  List<DvrItemModel> get items;
  @override
  @JsonKey(ignore: true)
  _$$DvrDataModelImplCopyWith<_$DvrDataModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
