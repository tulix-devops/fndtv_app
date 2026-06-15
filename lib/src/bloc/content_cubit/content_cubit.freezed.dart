// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ContentState {
  Status get status => throw _privateConstructorUsedError;
  Map<String, ContentModelList?>? get contentList =>
      throw _privateConstructorUsedError;
  Status get dvrStatus => throw _privateConstructorUsedError;
  DvrDataModel? get dvrData => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ContentStateCopyWith<ContentState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentStateCopyWith<$Res> {
  factory $ContentStateCopyWith(
          ContentState value, $Res Function(ContentState) then) =
      _$ContentStateCopyWithImpl<$Res, ContentState>;
  @useResult
  $Res call(
      {Status status,
      Map<String, ContentModelList?>? contentList,
      Status dvrStatus,
      DvrDataModel? dvrData});

  $DvrDataModelCopyWith<$Res>? get dvrData;
}

/// @nodoc
class _$ContentStateCopyWithImpl<$Res, $Val extends ContentState>
    implements $ContentStateCopyWith<$Res> {
  _$ContentStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? contentList = freezed,
    Object? dvrStatus = null,
    Object? dvrData = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      contentList: freezed == contentList
          ? _value.contentList
          : contentList // ignore: cast_nullable_to_non_nullable
              as Map<String, ContentModelList?>?,
      dvrStatus: null == dvrStatus
          ? _value.dvrStatus
          : dvrStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      dvrData: freezed == dvrData
          ? _value.dvrData
          : dvrData // ignore: cast_nullable_to_non_nullable
              as DvrDataModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DvrDataModelCopyWith<$Res>? get dvrData {
    if (_value.dvrData == null) {
      return null;
    }

    return $DvrDataModelCopyWith<$Res>(_value.dvrData!, (value) {
      return _then(_value.copyWith(dvrData: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ContentStateImplCopyWith<$Res>
    implements $ContentStateCopyWith<$Res> {
  factory _$$ContentStateImplCopyWith(
          _$ContentStateImpl value, $Res Function(_$ContentStateImpl) then) =
      __$$ContentStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      Map<String, ContentModelList?>? contentList,
      Status dvrStatus,
      DvrDataModel? dvrData});

  @override
  $DvrDataModelCopyWith<$Res>? get dvrData;
}

/// @nodoc
class __$$ContentStateImplCopyWithImpl<$Res>
    extends _$ContentStateCopyWithImpl<$Res, _$ContentStateImpl>
    implements _$$ContentStateImplCopyWith<$Res> {
  __$$ContentStateImplCopyWithImpl(
      _$ContentStateImpl _value, $Res Function(_$ContentStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? contentList = freezed,
    Object? dvrStatus = null,
    Object? dvrData = freezed,
  }) {
    return _then(_$ContentStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      contentList: freezed == contentList
          ? _value._contentList
          : contentList // ignore: cast_nullable_to_non_nullable
              as Map<String, ContentModelList?>?,
      dvrStatus: null == dvrStatus
          ? _value.dvrStatus
          : dvrStatus // ignore: cast_nullable_to_non_nullable
              as Status,
      dvrData: freezed == dvrData
          ? _value.dvrData
          : dvrData // ignore: cast_nullable_to_non_nullable
              as DvrDataModel?,
    ));
  }
}

/// @nodoc

class _$ContentStateImpl extends _ContentState {
  const _$ContentStateImpl(
      {this.status = Status.initial,
      final Map<String, ContentModelList?>? contentList,
      this.dvrStatus = Status.initial,
      this.dvrData})
      : _contentList = contentList,
        super._();

  @override
  @JsonKey()
  final Status status;
  final Map<String, ContentModelList?>? _contentList;
  @override
  Map<String, ContentModelList?>? get contentList {
    final value = _contentList;
    if (value == null) return null;
    if (_contentList is EqualUnmodifiableMapView) return _contentList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey()
  final Status dvrStatus;
  @override
  final DvrDataModel? dvrData;

  @override
  String toString() {
    return 'ContentState(status: $status, contentList: $contentList, dvrStatus: $dvrStatus, dvrData: $dvrData)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._contentList, _contentList) &&
            (identical(other.dvrStatus, dvrStatus) ||
                other.dvrStatus == dvrStatus) &&
            (identical(other.dvrData, dvrData) || other.dvrData == dvrData));
  }

  @override
  int get hashCode => Object.hash(runtimeType, status,
      const DeepCollectionEquality().hash(_contentList), dvrStatus, dvrData);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentStateImplCopyWith<_$ContentStateImpl> get copyWith =>
      __$$ContentStateImplCopyWithImpl<_$ContentStateImpl>(this, _$identity);
}

abstract class _ContentState extends ContentState {
  const factory _ContentState(
      {final Status status,
      final Map<String, ContentModelList?>? contentList,
      final Status dvrStatus,
      final DvrDataModel? dvrData}) = _$ContentStateImpl;
  const _ContentState._() : super._();

  @override
  Status get status;
  @override
  Map<String, ContentModelList?>? get contentList;
  @override
  Status get dvrStatus;
  @override
  DvrDataModel? get dvrData;
  @override
  @JsonKey(ignore: true)
  _$$ContentStateImplCopyWith<_$ContentStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
