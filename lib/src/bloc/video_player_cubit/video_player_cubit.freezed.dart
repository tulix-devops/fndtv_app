// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_player_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$VideoPlayerState {
  Status get status => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  bool get isVisible => throw _privateConstructorUsedError;
  bool get isLocked => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  bool get videoIsSeekingForward => throw _privateConstructorUsedError;
  bool get videoIsRewindSeeking => throw _privateConstructorUsedError;
  int get selectedSpeed => throw _privateConstructorUsedError;
  bool get isAdDone => throw _privateConstructorUsedError;
  (bool, String) get liveStatus => throw _privateConstructorUsedError;
  AdModel? get adModel => throw _privateConstructorUsedError;
  TvScheduleModel? get video => throw _privateConstructorUsedError;
  ({double currentVolume, double previousVolume}) get videoVolume =>
      throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $VideoPlayerStateCopyWith<VideoPlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoPlayerStateCopyWith<$Res> {
  factory $VideoPlayerStateCopyWith(
          VideoPlayerState value, $Res Function(VideoPlayerState) then) =
      _$VideoPlayerStateCopyWithImpl<$Res, VideoPlayerState>;
  @useResult
  $Res call(
      {Status status,
      bool isPlaying,
      bool isVisible,
      bool isLocked,
      bool isMuted,
      bool videoIsSeekingForward,
      bool videoIsRewindSeeking,
      int selectedSpeed,
      bool isAdDone,
      (bool, String) liveStatus,
      AdModel? adModel,
      TvScheduleModel? video,
      ({double currentVolume, double previousVolume}) videoVolume});
}

/// @nodoc
class _$VideoPlayerStateCopyWithImpl<$Res, $Val extends VideoPlayerState>
    implements $VideoPlayerStateCopyWith<$Res> {
  _$VideoPlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isPlaying = null,
    Object? isVisible = null,
    Object? isLocked = null,
    Object? isMuted = null,
    Object? videoIsSeekingForward = null,
    Object? videoIsRewindSeeking = null,
    Object? selectedSpeed = null,
    Object? isAdDone = null,
    Object? liveStatus = null,
    Object? adModel = freezed,
    Object? video = freezed,
    Object? videoVolume = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      videoIsSeekingForward: null == videoIsSeekingForward
          ? _value.videoIsSeekingForward
          : videoIsSeekingForward // ignore: cast_nullable_to_non_nullable
              as bool,
      videoIsRewindSeeking: null == videoIsRewindSeeking
          ? _value.videoIsRewindSeeking
          : videoIsRewindSeeking // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedSpeed: null == selectedSpeed
          ? _value.selectedSpeed
          : selectedSpeed // ignore: cast_nullable_to_non_nullable
              as int,
      isAdDone: null == isAdDone
          ? _value.isAdDone
          : isAdDone // ignore: cast_nullable_to_non_nullable
              as bool,
      liveStatus: null == liveStatus
          ? _value.liveStatus
          : liveStatus // ignore: cast_nullable_to_non_nullable
              as (bool, String),
      adModel: freezed == adModel
          ? _value.adModel
          : adModel // ignore: cast_nullable_to_non_nullable
              as AdModel?,
      video: freezed == video
          ? _value.video
          : video // ignore: cast_nullable_to_non_nullable
              as TvScheduleModel?,
      videoVolume: null == videoVolume
          ? _value.videoVolume
          : videoVolume // ignore: cast_nullable_to_non_nullable
              as ({double currentVolume, double previousVolume}),
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VideoPlayerStateImplCopyWith<$Res>
    implements $VideoPlayerStateCopyWith<$Res> {
  factory _$$VideoPlayerStateImplCopyWith(_$VideoPlayerStateImpl value,
          $Res Function(_$VideoPlayerStateImpl) then) =
      __$$VideoPlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Status status,
      bool isPlaying,
      bool isVisible,
      bool isLocked,
      bool isMuted,
      bool videoIsSeekingForward,
      bool videoIsRewindSeeking,
      int selectedSpeed,
      bool isAdDone,
      (bool, String) liveStatus,
      AdModel? adModel,
      TvScheduleModel? video,
      ({double currentVolume, double previousVolume}) videoVolume});
}

/// @nodoc
class __$$VideoPlayerStateImplCopyWithImpl<$Res>
    extends _$VideoPlayerStateCopyWithImpl<$Res, _$VideoPlayerStateImpl>
    implements _$$VideoPlayerStateImplCopyWith<$Res> {
  __$$VideoPlayerStateImplCopyWithImpl(_$VideoPlayerStateImpl _value,
      $Res Function(_$VideoPlayerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? isPlaying = null,
    Object? isVisible = null,
    Object? isLocked = null,
    Object? isMuted = null,
    Object? videoIsSeekingForward = null,
    Object? videoIsRewindSeeking = null,
    Object? selectedSpeed = null,
    Object? isAdDone = null,
    Object? liveStatus = null,
    Object? adModel = freezed,
    Object? video = freezed,
    Object? videoVolume = null,
  }) {
    return _then(_$VideoPlayerStateImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as Status,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      videoIsSeekingForward: null == videoIsSeekingForward
          ? _value.videoIsSeekingForward
          : videoIsSeekingForward // ignore: cast_nullable_to_non_nullable
              as bool,
      videoIsRewindSeeking: null == videoIsRewindSeeking
          ? _value.videoIsRewindSeeking
          : videoIsRewindSeeking // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedSpeed: null == selectedSpeed
          ? _value.selectedSpeed
          : selectedSpeed // ignore: cast_nullable_to_non_nullable
              as int,
      isAdDone: null == isAdDone
          ? _value.isAdDone
          : isAdDone // ignore: cast_nullable_to_non_nullable
              as bool,
      liveStatus: null == liveStatus
          ? _value.liveStatus
          : liveStatus // ignore: cast_nullable_to_non_nullable
              as (bool, String),
      adModel: freezed == adModel
          ? _value.adModel
          : adModel // ignore: cast_nullable_to_non_nullable
              as AdModel?,
      video: freezed == video
          ? _value.video
          : video // ignore: cast_nullable_to_non_nullable
              as TvScheduleModel?,
      videoVolume: null == videoVolume
          ? _value.videoVolume
          : videoVolume // ignore: cast_nullable_to_non_nullable
              as ({double currentVolume, double previousVolume}),
    ));
  }
}

/// @nodoc

class _$VideoPlayerStateImpl implements _VideoPlayerState {
  const _$VideoPlayerStateImpl(
      {this.status = Status.initial,
      this.isPlaying = true,
      this.isVisible = false,
      this.isLocked = false,
      this.isMuted = false,
      this.videoIsSeekingForward = false,
      this.videoIsRewindSeeking = false,
      this.selectedSpeed = 0,
      this.isAdDone = false,
      this.liveStatus = const (false, "0.00"),
      this.adModel = null,
      this.video = null,
      this.videoVolume = const (currentVolume: 1.0, previousVolume: 1.0)});

  @override
  @JsonKey()
  final Status status;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final bool isVisible;
  @override
  @JsonKey()
  final bool isLocked;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  @JsonKey()
  final bool videoIsSeekingForward;
  @override
  @JsonKey()
  final bool videoIsRewindSeeking;
  @override
  @JsonKey()
  final int selectedSpeed;
  @override
  @JsonKey()
  final bool isAdDone;
  @override
  @JsonKey()
  final (bool, String) liveStatus;
  @override
  @JsonKey()
  final AdModel? adModel;
  @override
  @JsonKey()
  final TvScheduleModel? video;
  @override
  @JsonKey()
  final ({double currentVolume, double previousVolume}) videoVolume;

  @override
  String toString() {
    return 'VideoPlayerState(status: $status, isPlaying: $isPlaying, isVisible: $isVisible, isLocked: $isLocked, isMuted: $isMuted, videoIsSeekingForward: $videoIsSeekingForward, videoIsRewindSeeking: $videoIsRewindSeeking, selectedSpeed: $selectedSpeed, isAdDone: $isAdDone, liveStatus: $liveStatus, adModel: $adModel, video: $video, videoVolume: $videoVolume)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoPlayerStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.videoIsSeekingForward, videoIsSeekingForward) ||
                other.videoIsSeekingForward == videoIsSeekingForward) &&
            (identical(other.videoIsRewindSeeking, videoIsRewindSeeking) ||
                other.videoIsRewindSeeking == videoIsRewindSeeking) &&
            (identical(other.selectedSpeed, selectedSpeed) ||
                other.selectedSpeed == selectedSpeed) &&
            (identical(other.isAdDone, isAdDone) ||
                other.isAdDone == isAdDone) &&
            (identical(other.liveStatus, liveStatus) ||
                other.liveStatus == liveStatus) &&
            (identical(other.adModel, adModel) || other.adModel == adModel) &&
            (identical(other.video, video) || other.video == video) &&
            (identical(other.videoVolume, videoVolume) ||
                other.videoVolume == videoVolume));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      status,
      isPlaying,
      isVisible,
      isLocked,
      isMuted,
      videoIsSeekingForward,
      videoIsRewindSeeking,
      selectedSpeed,
      isAdDone,
      liveStatus,
      adModel,
      video,
      videoVolume);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoPlayerStateImplCopyWith<_$VideoPlayerStateImpl> get copyWith =>
      __$$VideoPlayerStateImplCopyWithImpl<_$VideoPlayerStateImpl>(
          this, _$identity);
}

abstract class _VideoPlayerState implements VideoPlayerState {
  const factory _VideoPlayerState(
          {final Status status,
          final bool isPlaying,
          final bool isVisible,
          final bool isLocked,
          final bool isMuted,
          final bool videoIsSeekingForward,
          final bool videoIsRewindSeeking,
          final int selectedSpeed,
          final bool isAdDone,
          final (bool, String) liveStatus,
          final AdModel? adModel,
          final TvScheduleModel? video,
          final ({double currentVolume, double previousVolume}) videoVolume}) =
      _$VideoPlayerStateImpl;

  @override
  Status get status;
  @override
  bool get isPlaying;
  @override
  bool get isVisible;
  @override
  bool get isLocked;
  @override
  bool get isMuted;
  @override
  bool get videoIsSeekingForward;
  @override
  bool get videoIsRewindSeeking;
  @override
  int get selectedSpeed;
  @override
  bool get isAdDone;
  @override
  (bool, String) get liveStatus;
  @override
  AdModel? get adModel;
  @override
  TvScheduleModel? get video;
  @override
  ({double currentVolume, double previousVolume}) get videoVolume;
  @override
  @JsonKey(ignore: true)
  _$$VideoPlayerStateImplCopyWith<_$VideoPlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
