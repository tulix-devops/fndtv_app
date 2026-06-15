// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpisodeModelImpl _$$EpisodeModelImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeModelImpl(
      id: (json['id'] as num).toInt(),
      videoId: (json['videoId'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      storageRecord: StorageRecordModel.fromJson(
          json['storageRecord'] as Map<String, dynamic>),
      seasonNumber: (json['seasonNumber'] as num).toInt(),
      episodeNumber: (json['episodeNumber'] as num).toInt(),
      language: json['language'] as String,
      chapters: json['chapters'] as String,
    );

Map<String, dynamic> _$$EpisodeModelImplToJson(_$EpisodeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'videoId': instance.videoId,
      'title': instance.title,
      'description': instance.description,
      'storageRecord': instance.storageRecord,
      'seasonNumber': instance.seasonNumber,
      'episodeNumber': instance.episodeNumber,
      'language': instance.language,
      'chapters': instance.chapters,
    };
