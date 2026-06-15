// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VodModelImpl _$$VodModelImplFromJson(Map<String, dynamic> json) =>
    _$VodModelImpl(
      id: (json['id'] as num).toInt(),
      statusId: (json['statusId'] as num?)?.toInt(),
      typeId: (json['typeId'] as num?)?.toInt(),
      seasons: (json['seasons'] as num?)?.toInt(),
      episodesCount: (json['episodesCount'] as num?)?.toInt(),
      type: json['type'] as String,
      accessTypeId: (json['accessTypeId'] as num?)?.toInt(),
      countryId: (json['countryId'] as num?)?.toInt(),
      storageRecordId: (json['storageRecordId'] as num?)?.toInt(),
      storageRecordTypeId: (json['storageRecordTypeId'] as num?)?.toInt(),
      storageRecord: json['storageRecord'] == null
          ? null
          : StorageRecordModel.fromJson(
              json['storageRecord'] as Map<String, dynamic>),
      storage: json['storage'] == null
          ? null
          : StorageModel.fromJson(json['storage'] as Map<String, dynamic>),
      title: json['title'] as String,
      description: json['description'] as String,
      productionYear: (json['productionYear'] as num?)?.toInt(),
      actors: (json['actors'] as List<dynamic>)
          .map((e) => ActorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupedSeasons: (json['groupedSeasons'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      tags: (json['tags'] as List<dynamic>)
          .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      country: json['country'] == null
          ? null
          : CountryModel.fromJson(json['country'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VodModelImplToJson(_$VodModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'statusId': instance.statusId,
      'typeId': instance.typeId,
      'seasons': instance.seasons,
      'episodesCount': instance.episodesCount,
      'type': instance.type,
      'accessTypeId': instance.accessTypeId,
      'countryId': instance.countryId,
      'storageRecordId': instance.storageRecordId,
      'storageRecordTypeId': instance.storageRecordTypeId,
      'storageRecord': instance.storageRecord,
      'storage': instance.storage,
      'title': instance.title,
      'description': instance.description,
      'productionYear': instance.productionYear,
      'actors': instance.actors,
      'episodes': instance.episodes,
      'groupedSeasons': instance.groupedSeasons,
      'tags': instance.tags,
      'categories': instance.categories,
      'country': instance.country,
    };
