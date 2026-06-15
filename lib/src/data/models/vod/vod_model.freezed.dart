// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vod_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VodModel _$VodModelFromJson(Map<String, dynamic> json) {
  return _VodModel.fromJson(json);
}

/// @nodoc
mixin _$VodModel {
  int get id => throw _privateConstructorUsedError;
  int? get statusId => throw _privateConstructorUsedError;
  int? get typeId => throw _privateConstructorUsedError;
  int? get seasons => throw _privateConstructorUsedError;
  int? get episodesCount => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int? get accessTypeId => throw _privateConstructorUsedError;
  int? get countryId => throw _privateConstructorUsedError;
  int? get storageRecordId => throw _privateConstructorUsedError;
  int? get storageRecordTypeId => throw _privateConstructorUsedError;
  StorageRecordModel? get storageRecord => throw _privateConstructorUsedError;
  StorageModel? get storage => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  int? get productionYear => throw _privateConstructorUsedError;
  List<ActorModel> get actors => throw _privateConstructorUsedError;
  List<EpisodeModel> get episodes => throw _privateConstructorUsedError;
  Map<String, List<EpisodeModel>>? get groupedSeasons =>
      throw _privateConstructorUsedError;
  List<TagModel> get tags => throw _privateConstructorUsedError;
  List<CategoryModel> get categories => throw _privateConstructorUsedError;
  CountryModel? get country => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VodModelCopyWith<VodModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VodModelCopyWith<$Res> {
  factory $VodModelCopyWith(VodModel value, $Res Function(VodModel) then) =
      _$VodModelCopyWithImpl<$Res, VodModel>;
  @useResult
  $Res call(
      {int id,
      int? statusId,
      int? typeId,
      int? seasons,
      int? episodesCount,
      String type,
      int? accessTypeId,
      int? countryId,
      int? storageRecordId,
      int? storageRecordTypeId,
      StorageRecordModel? storageRecord,
      StorageModel? storage,
      String title,
      String description,
      int? productionYear,
      List<ActorModel> actors,
      List<EpisodeModel> episodes,
      Map<String, List<EpisodeModel>>? groupedSeasons,
      List<TagModel> tags,
      List<CategoryModel> categories,
      CountryModel? country});

  $StorageRecordModelCopyWith<$Res>? get storageRecord;
  $StorageModelCopyWith<$Res>? get storage;
  $CountryModelCopyWith<$Res>? get country;
}

/// @nodoc
class _$VodModelCopyWithImpl<$Res, $Val extends VodModel>
    implements $VodModelCopyWith<$Res> {
  _$VodModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? statusId = freezed,
    Object? typeId = freezed,
    Object? seasons = freezed,
    Object? episodesCount = freezed,
    Object? type = null,
    Object? accessTypeId = freezed,
    Object? countryId = freezed,
    Object? storageRecordId = freezed,
    Object? storageRecordTypeId = freezed,
    Object? storageRecord = freezed,
    Object? storage = freezed,
    Object? title = null,
    Object? description = null,
    Object? productionYear = freezed,
    Object? actors = null,
    Object? episodes = null,
    Object? groupedSeasons = freezed,
    Object? tags = null,
    Object? categories = null,
    Object? country = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: freezed == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as int?,
      typeId: freezed == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as int?,
      seasons: freezed == seasons
          ? _value.seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as int?,
      episodesCount: freezed == episodesCount
          ? _value.episodesCount
          : episodesCount // ignore: cast_nullable_to_non_nullable
              as int?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      accessTypeId: freezed == accessTypeId
          ? _value.accessTypeId
          : accessTypeId // ignore: cast_nullable_to_non_nullable
              as int?,
      countryId: freezed == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecordId: freezed == storageRecordId
          ? _value.storageRecordId
          : storageRecordId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecordTypeId: freezed == storageRecordTypeId
          ? _value.storageRecordTypeId
          : storageRecordTypeId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecord: freezed == storageRecord
          ? _value.storageRecord
          : storageRecord // ignore: cast_nullable_to_non_nullable
              as StorageRecordModel?,
      storage: freezed == storage
          ? _value.storage
          : storage // ignore: cast_nullable_to_non_nullable
              as StorageModel?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      actors: null == actors
          ? _value.actors
          : actors // ignore: cast_nullable_to_non_nullable
              as List<ActorModel>,
      episodes: null == episodes
          ? _value.episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<EpisodeModel>,
      groupedSeasons: freezed == groupedSeasons
          ? _value.groupedSeasons
          : groupedSeasons // ignore: cast_nullable_to_non_nullable
              as Map<String, List<EpisodeModel>>?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel>,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as CountryModel?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $StorageRecordModelCopyWith<$Res>? get storageRecord {
    if (_value.storageRecord == null) {
      return null;
    }

    return $StorageRecordModelCopyWith<$Res>(_value.storageRecord!, (value) {
      return _then(_value.copyWith(storageRecord: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $StorageModelCopyWith<$Res>? get storage {
    if (_value.storage == null) {
      return null;
    }

    return $StorageModelCopyWith<$Res>(_value.storage!, (value) {
      return _then(_value.copyWith(storage: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $CountryModelCopyWith<$Res>? get country {
    if (_value.country == null) {
      return null;
    }

    return $CountryModelCopyWith<$Res>(_value.country!, (value) {
      return _then(_value.copyWith(country: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VodModelImplCopyWith<$Res>
    implements $VodModelCopyWith<$Res> {
  factory _$$VodModelImplCopyWith(
          _$VodModelImpl value, $Res Function(_$VodModelImpl) then) =
      __$$VodModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      int? statusId,
      int? typeId,
      int? seasons,
      int? episodesCount,
      String type,
      int? accessTypeId,
      int? countryId,
      int? storageRecordId,
      int? storageRecordTypeId,
      StorageRecordModel? storageRecord,
      StorageModel? storage,
      String title,
      String description,
      int? productionYear,
      List<ActorModel> actors,
      List<EpisodeModel> episodes,
      Map<String, List<EpisodeModel>>? groupedSeasons,
      List<TagModel> tags,
      List<CategoryModel> categories,
      CountryModel? country});

  @override
  $StorageRecordModelCopyWith<$Res>? get storageRecord;
  @override
  $StorageModelCopyWith<$Res>? get storage;
  @override
  $CountryModelCopyWith<$Res>? get country;
}

/// @nodoc
class __$$VodModelImplCopyWithImpl<$Res>
    extends _$VodModelCopyWithImpl<$Res, _$VodModelImpl>
    implements _$$VodModelImplCopyWith<$Res> {
  __$$VodModelImplCopyWithImpl(
      _$VodModelImpl _value, $Res Function(_$VodModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? statusId = freezed,
    Object? typeId = freezed,
    Object? seasons = freezed,
    Object? episodesCount = freezed,
    Object? type = null,
    Object? accessTypeId = freezed,
    Object? countryId = freezed,
    Object? storageRecordId = freezed,
    Object? storageRecordTypeId = freezed,
    Object? storageRecord = freezed,
    Object? storage = freezed,
    Object? title = null,
    Object? description = null,
    Object? productionYear = freezed,
    Object? actors = null,
    Object? episodes = null,
    Object? groupedSeasons = freezed,
    Object? tags = null,
    Object? categories = null,
    Object? country = freezed,
  }) {
    return _then(_$VodModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      statusId: freezed == statusId
          ? _value.statusId
          : statusId // ignore: cast_nullable_to_non_nullable
              as int?,
      typeId: freezed == typeId
          ? _value.typeId
          : typeId // ignore: cast_nullable_to_non_nullable
              as int?,
      seasons: freezed == seasons
          ? _value.seasons
          : seasons // ignore: cast_nullable_to_non_nullable
              as int?,
      episodesCount: freezed == episodesCount
          ? _value.episodesCount
          : episodesCount // ignore: cast_nullable_to_non_nullable
              as int?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      accessTypeId: freezed == accessTypeId
          ? _value.accessTypeId
          : accessTypeId // ignore: cast_nullable_to_non_nullable
              as int?,
      countryId: freezed == countryId
          ? _value.countryId
          : countryId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecordId: freezed == storageRecordId
          ? _value.storageRecordId
          : storageRecordId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecordTypeId: freezed == storageRecordTypeId
          ? _value.storageRecordTypeId
          : storageRecordTypeId // ignore: cast_nullable_to_non_nullable
              as int?,
      storageRecord: freezed == storageRecord
          ? _value.storageRecord
          : storageRecord // ignore: cast_nullable_to_non_nullable
              as StorageRecordModel?,
      storage: freezed == storage
          ? _value.storage
          : storage // ignore: cast_nullable_to_non_nullable
              as StorageModel?,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      productionYear: freezed == productionYear
          ? _value.productionYear
          : productionYear // ignore: cast_nullable_to_non_nullable
              as int?,
      actors: null == actors
          ? _value._actors
          : actors // ignore: cast_nullable_to_non_nullable
              as List<ActorModel>,
      episodes: null == episodes
          ? _value._episodes
          : episodes // ignore: cast_nullable_to_non_nullable
              as List<EpisodeModel>,
      groupedSeasons: freezed == groupedSeasons
          ? _value._groupedSeasons
          : groupedSeasons // ignore: cast_nullable_to_non_nullable
              as Map<String, List<EpisodeModel>>?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<TagModel>,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<CategoryModel>,
      country: freezed == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as CountryModel?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VodModelImpl with DiagnosticableTreeMixin implements _VodModel {
  const _$VodModelImpl(
      {required this.id,
      required this.statusId,
      required this.typeId,
      required this.seasons,
      required this.episodesCount,
      required this.type,
      required this.accessTypeId,
      required this.countryId,
      required this.storageRecordId,
      required this.storageRecordTypeId,
      required this.storageRecord,
      required this.storage,
      required this.title,
      required this.description,
      required this.productionYear,
      required final List<ActorModel> actors,
      required final List<EpisodeModel> episodes,
      required final Map<String, List<EpisodeModel>>? groupedSeasons,
      required final List<TagModel> tags,
      required final List<CategoryModel> categories,
      required this.country})
      : _actors = actors,
        _episodes = episodes,
        _groupedSeasons = groupedSeasons,
        _tags = tags,
        _categories = categories;

  factory _$VodModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$VodModelImplFromJson(json);

  @override
  final int id;
  @override
  final int? statusId;
  @override
  final int? typeId;
  @override
  final int? seasons;
  @override
  final int? episodesCount;
  @override
  final String type;
  @override
  final int? accessTypeId;
  @override
  final int? countryId;
  @override
  final int? storageRecordId;
  @override
  final int? storageRecordTypeId;
  @override
  final StorageRecordModel? storageRecord;
  @override
  final StorageModel? storage;
  @override
  final String title;
  @override
  final String description;
  @override
  final int? productionYear;
  final List<ActorModel> _actors;
  @override
  List<ActorModel> get actors {
    if (_actors is EqualUnmodifiableListView) return _actors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_actors);
  }

  final List<EpisodeModel> _episodes;
  @override
  List<EpisodeModel> get episodes {
    if (_episodes is EqualUnmodifiableListView) return _episodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_episodes);
  }

  final Map<String, List<EpisodeModel>>? _groupedSeasons;
  @override
  Map<String, List<EpisodeModel>>? get groupedSeasons {
    final value = _groupedSeasons;
    if (value == null) return null;
    if (_groupedSeasons is EqualUnmodifiableMapView) return _groupedSeasons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<TagModel> _tags;
  @override
  List<TagModel> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<CategoryModel> _categories;
  @override
  List<CategoryModel> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  final CountryModel? country;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'VodModel(id: $id, statusId: $statusId, typeId: $typeId, seasons: $seasons, episodesCount: $episodesCount, type: $type, accessTypeId: $accessTypeId, countryId: $countryId, storageRecordId: $storageRecordId, storageRecordTypeId: $storageRecordTypeId, storageRecord: $storageRecord, storage: $storage, title: $title, description: $description, productionYear: $productionYear, actors: $actors, episodes: $episodes, groupedSeasons: $groupedSeasons, tags: $tags, categories: $categories, country: $country)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'VodModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('statusId', statusId))
      ..add(DiagnosticsProperty('typeId', typeId))
      ..add(DiagnosticsProperty('seasons', seasons))
      ..add(DiagnosticsProperty('episodesCount', episodesCount))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('accessTypeId', accessTypeId))
      ..add(DiagnosticsProperty('countryId', countryId))
      ..add(DiagnosticsProperty('storageRecordId', storageRecordId))
      ..add(DiagnosticsProperty('storageRecordTypeId', storageRecordTypeId))
      ..add(DiagnosticsProperty('storageRecord', storageRecord))
      ..add(DiagnosticsProperty('storage', storage))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('productionYear', productionYear))
      ..add(DiagnosticsProperty('actors', actors))
      ..add(DiagnosticsProperty('episodes', episodes))
      ..add(DiagnosticsProperty('groupedSeasons', groupedSeasons))
      ..add(DiagnosticsProperty('tags', tags))
      ..add(DiagnosticsProperty('categories', categories))
      ..add(DiagnosticsProperty('country', country));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VodModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.statusId, statusId) ||
                other.statusId == statusId) &&
            (identical(other.typeId, typeId) || other.typeId == typeId) &&
            (identical(other.seasons, seasons) || other.seasons == seasons) &&
            (identical(other.episodesCount, episodesCount) ||
                other.episodesCount == episodesCount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.accessTypeId, accessTypeId) ||
                other.accessTypeId == accessTypeId) &&
            (identical(other.countryId, countryId) ||
                other.countryId == countryId) &&
            (identical(other.storageRecordId, storageRecordId) ||
                other.storageRecordId == storageRecordId) &&
            (identical(other.storageRecordTypeId, storageRecordTypeId) ||
                other.storageRecordTypeId == storageRecordTypeId) &&
            (identical(other.storageRecord, storageRecord) ||
                other.storageRecord == storageRecord) &&
            (identical(other.storage, storage) || other.storage == storage) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.productionYear, productionYear) ||
                other.productionYear == productionYear) &&
            const DeepCollectionEquality().equals(other._actors, _actors) &&
            const DeepCollectionEquality().equals(other._episodes, _episodes) &&
            const DeepCollectionEquality()
                .equals(other._groupedSeasons, _groupedSeasons) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        statusId,
        typeId,
        seasons,
        episodesCount,
        type,
        accessTypeId,
        countryId,
        storageRecordId,
        storageRecordTypeId,
        storageRecord,
        storage,
        title,
        description,
        productionYear,
        const DeepCollectionEquality().hash(_actors),
        const DeepCollectionEquality().hash(_episodes),
        const DeepCollectionEquality().hash(_groupedSeasons),
        const DeepCollectionEquality().hash(_tags),
        const DeepCollectionEquality().hash(_categories),
        country
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VodModelImplCopyWith<_$VodModelImpl> get copyWith =>
      __$$VodModelImplCopyWithImpl<_$VodModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VodModelImplToJson(
      this,
    );
  }
}

abstract class _VodModel implements VodModel {
  const factory _VodModel(
      {required final int id,
      required final int? statusId,
      required final int? typeId,
      required final int? seasons,
      required final int? episodesCount,
      required final String type,
      required final int? accessTypeId,
      required final int? countryId,
      required final int? storageRecordId,
      required final int? storageRecordTypeId,
      required final StorageRecordModel? storageRecord,
      required final StorageModel? storage,
      required final String title,
      required final String description,
      required final int? productionYear,
      required final List<ActorModel> actors,
      required final List<EpisodeModel> episodes,
      required final Map<String, List<EpisodeModel>>? groupedSeasons,
      required final List<TagModel> tags,
      required final List<CategoryModel> categories,
      required final CountryModel? country}) = _$VodModelImpl;

  factory _VodModel.fromJson(Map<String, dynamic> json) =
      _$VodModelImpl.fromJson;

  @override
  int get id;
  @override
  int? get statusId;
  @override
  int? get typeId;
  @override
  int? get seasons;
  @override
  int? get episodesCount;
  @override
  String get type;
  @override
  int? get accessTypeId;
  @override
  int? get countryId;
  @override
  int? get storageRecordId;
  @override
  int? get storageRecordTypeId;
  @override
  StorageRecordModel? get storageRecord;
  @override
  StorageModel? get storage;
  @override
  String get title;
  @override
  String get description;
  @override
  int? get productionYear;
  @override
  List<ActorModel> get actors;
  @override
  List<EpisodeModel> get episodes;
  @override
  Map<String, List<EpisodeModel>>? get groupedSeasons;
  @override
  List<TagModel> get tags;
  @override
  List<CategoryModel> get categories;
  @override
  CountryModel? get country;
  @override
  @JsonKey(ignore: true)
  _$$VodModelImplCopyWith<_$VodModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
