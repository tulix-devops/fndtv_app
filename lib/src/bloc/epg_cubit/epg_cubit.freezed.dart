// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'epg_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$EpgState {
  Status get status => throw _privateConstructorUsedError;
  TvScheduleModel? get selectedDvr => throw _privateConstructorUsedError;
  List<ChannelModel>? get epgContent => throw _privateConstructorUsedError;
  List<PodcastModel>? get podcasts => throw _privateConstructorUsedError;
  ChannelModel? get selectedChannel => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $EpgStateCopyWith<EpgState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpgStateCopyWith<$Res> {
  factory $EpgStateCopyWith(EpgState value, $Res Function(EpgState) then) =
      _$EpgStateCopyWithImpl<$Res, EpgState>;
  @useResult
  $Res call(
      {Status status,
      TvScheduleModel? selectedDvr,
      List<ChannelModel>? epgContent,
      List<PodcastModel>? podcasts,
      ChannelModel? selectedChannel});
}

/// @nodoc
class _$EpgStateCopyWithImpl<$Res, $Val extends EpgState>
    implements $EpgStateCopyWith<$Res> {
  _$EpgStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? selectedDvr = freezed,
    Object? epgContent = freezed,
    Object? podcasts = freezed,
    Object? selectedChannel = freezed,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      selectedDvr: freezed == selectedDvr
          ? _value.selectedDvr
          : selectedDvr // ignore: cast_nullable_to_non_nullable
              as TvScheduleModel?,
      epgContent: freezed == epgContent
          ? _value.epgContent
          : epgContent // ignore: cast_nullable_to_non_nullable
              as List<ChannelModel>?,
      podcasts: freezed == podcasts
          ? _value.podcasts
          : podcasts // ignore: cast_nullable_to_non_nullable
              as List<PodcastModel>?,
      selectedChannel: freezed == selectedChannel
          ? _value.selectedChannel
          : selectedChannel // ignore: cast_nullable_to_non_nullable
              as ChannelModel?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EpgStateImplCopyWith<$Res>
    implements $EpgStateCopyWith<$Res> {
  factory _$$EpgStateImplCopyWith(
          _$EpgStateImpl value, $Res Function(_$EpgStateImpl) then) =
      __$$EpgStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      TvScheduleModel? selectedDvr,
      List<ChannelModel>? epgContent,
      List<PodcastModel>? podcasts,
      ChannelModel? selectedChannel});
}

/// @nodoc
class __$$EpgStateImplCopyWithImpl<$Res>
    extends _$EpgStateCopyWithImpl<$Res, _$EpgStateImpl>
    implements _$$EpgStateImplCopyWith<$Res> {
  __$$EpgStateImplCopyWithImpl(
      _$EpgStateImpl _value, $Res Function(_$EpgStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? selectedDvr = freezed,
    Object? epgContent = freezed,
    Object? podcasts = freezed,
    Object? selectedChannel = freezed,
  }) {
    return _then(_$EpgStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      selectedDvr: freezed == selectedDvr
          ? _value.selectedDvr
          : selectedDvr // ignore: cast_nullable_to_non_nullable
              as TvScheduleModel?,
      epgContent: freezed == epgContent
          ? _value._epgContent
          : epgContent // ignore: cast_nullable_to_non_nullable
              as List<ChannelModel>?,
      podcasts: freezed == podcasts
          ? _value._podcasts
          : podcasts // ignore: cast_nullable_to_non_nullable
              as List<PodcastModel>?,
      selectedChannel: freezed == selectedChannel
          ? _value.selectedChannel
          : selectedChannel // ignore: cast_nullable_to_non_nullable
              as ChannelModel?,
    ));
  }
}

/// @nodoc

class _$EpgStateImpl extends _EpgState {
  const _$EpgStateImpl(
      {this.status = Status.initial,
      this.selectedDvr = null,
      final List<ChannelModel>? epgContent = null,
      final List<PodcastModel>? podcasts = null,
      this.selectedChannel = null})
      : _epgContent = epgContent,
        _podcasts = podcasts,
        super._();

  @override
  @JsonKey()
  final Status status;
  @override
  @JsonKey()
  final TvScheduleModel? selectedDvr;
  final List<ChannelModel>? _epgContent;
  @override
  @JsonKey()
  List<ChannelModel>? get epgContent {
    final value = _epgContent;
    if (value == null) return null;
    if (_epgContent is EqualUnmodifiableListView) return _epgContent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<PodcastModel>? _podcasts;
  @override
  @JsonKey()
  List<PodcastModel>? get podcasts {
    final value = _podcasts;
    if (value == null) return null;
    if (_podcasts is EqualUnmodifiableListView) return _podcasts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final ChannelModel? selectedChannel;

  @override
  String toString() {
    return 'EpgState(status: $status, selectedDvr: $selectedDvr, epgContent: $epgContent, podcasts: $podcasts, selectedChannel: $selectedChannel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpgStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.selectedDvr, selectedDvr) ||
                other.selectedDvr == selectedDvr) &&
            const DeepCollectionEquality()
                .equals(other._epgContent, _epgContent) &&
            const DeepCollectionEquality().equals(other._podcasts, _podcasts) &&
            (identical(other.selectedChannel, selectedChannel) ||
                other.selectedChannel == selectedChannel));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      selectedDvr,
      const DeepCollectionEquality().hash(_epgContent),
      const DeepCollectionEquality().hash(_podcasts),
      selectedChannel);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EpgStateImplCopyWith<_$EpgStateImpl> get copyWith =>
      __$$EpgStateImplCopyWithImpl<_$EpgStateImpl>(this, _$identity);
}

abstract class _EpgState extends EpgState {
  const factory _EpgState(
      {final Status status,
      final TvScheduleModel? selectedDvr,
      final List<ChannelModel>? epgContent,
      final List<PodcastModel>? podcasts,
      final ChannelModel? selectedChannel}) = _$EpgStateImpl;
  const _EpgState._() : super._();

  @override
  Status get status;
  @override
  TvScheduleModel? get selectedDvr;
  @override
  List<ChannelModel>? get epgContent;
  @override
  List<PodcastModel>? get podcasts;
  @override
  ChannelModel? get selectedChannel;
  @override
  @JsonKey(ignore: true)
  _$$EpgStateImplCopyWith<_$EpgStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
